# frozen_string_literal: true

RSpec.describe OpenHAB::DSL::Items::Builder do
  %i[call color contact date_time dimmer group image location number player rollershutter string switch].each do |type|
    it "can create a #{type} item" do
      items.build { send(:"#{type}_item", "MyItem", "My Label") }
      expect(MyItem.label).to eql "My Label"
      expect(MyItem).to be_a(Object.const_get(:"#{type.to_s.gsub(/(^[a-z]|_[a-z])/) do |x|
                                                    x.delete("_").capitalize
                                                  end }Item"))
    end
  end

  describe "persistence configuration" do
    let(:configuration_registry) do
      OpenHAB::DSL::Items::Builder::Persistence.send(:configuration_registry)
    end
    let(:configuration_mapper) do
      org.openhab.core.persistence.registry.PersistenceServiceConfigurationDTOMapper
    end
    let(:configuration_provider) do
      provider = configuration_registry.managed_provider
      provider.is_a?(java.util.Optional) ? provider.get : provider
    end
    let(:service_id) { "jruby_builder_spec" }
    let(:other_service_id) { "jruby_builder_spec_other" }

    def expect_blocked_worker(worker, java_thread)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
      until java_thread.get.state.to_s == "BLOCKED" || worker.join(0) ||
            Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        Thread.pass
      end
      expect(java_thread.get.state.to_s).to eq "BLOCKED"
    end

    def check_removal_and_rebuild(operation)
      persistence = OpenHAB::DSL::Items::Builder::Persistence
      selected_service = service_id
      item_provider = (operation == :managed) ? :persistent : nil
      items.build(item_provider) { number_item "Reading", persist: :on_change }
      provider = Reading.provider
      workers = []
      entered = java.util.concurrent.CountDownLatch.new(1)
      release = java.util.concurrent.CountDownLatch.new(1)
      started = java.util.concurrent.CountDownLatch.new(1)
      rebuilding_thread = java.util.concurrent.atomic.AtomicReference.new
      allow(persistence).to receive(:remove).and_wrap_original do |original, *names|
        entered.count_down
        raise "Timed out waiting to remove" unless release.await(10, java.util.concurrent.TimeUnit::SECONDS)

        original.call(*names)
      end
      workers << Thread.new do
        case operation
        when :managed then items.remove("Reading")
        when :clear then provider.clear
        else provider.remove("Reading")
        end
      end
      expect(entered.await(5, java.util.concurrent.TimeUnit::SECONDS)).to be true
      workers << Thread.new do
        rebuilding_thread.set(java.lang.Thread.current_thread)
        started.count_down
        items.build(provider) do
          number_item "Reading" do
            persist :on_update, service: selected_service
          end
        end
      end
      expect(started.await(5, java.util.concurrent.TimeUnit::SECONDS)).to be true
      expect_blocked_worker(workers.last, rebuilding_thread)
      release.count_down
      workers.each do |worker|
        expect(worker.join(10)).not_to be_nil
        worker.value
      end
      expect(items["Reading"]).not_to be_nil
      entry = configuration.configs.find { |config| config.items.first.item == "Reading" }
      expect(entry.strategies.map(&:name)).to eq ["everyUpdate"]
    ensure
      release&.count_down
      workers&.each { |worker| worker.kill unless worker.join(10) }
      items.remove("Reading") if operation == :managed && items["Reading"]
    end

    def check_concurrent_persistence(operation)
      persistence = OpenHAB::DSL::Items::Builder::Persistence
      declarations = [persistence.declaration(:on_change, service: service_id, every: nil, cron: nil, filter: nil)]
      workers = []
      release = java.util.concurrent.CountDownLatch.new(1)
      entered = java.util.concurrent.CountDownLatch.new(1)
      started = java.util.concurrent.CountDownLatch.new(1)
      second_thread = java.util.concurrent.atomic.AtomicReference.new
      workers << Thread.new do
        persistence.apply("ConcurrentFirst", declarations) do
          entered.count_down
          raise "Timed out waiting to commit" unless release.await(10, java.util.concurrent.TimeUnit::SECONDS)
        end
      end
      expect(entered.await(5, java.util.concurrent.TimeUnit::SECONDS)).to be true
      workers << Thread.new do
        second_thread.set(java.lang.Thread.current_thread)
        started.count_down
        if operation == :apply
          persistence.apply("ConcurrentSecond", declarations)
        else
          persistence.remove("Reading")
        end
      end
      expect(started.await(5, java.util.concurrent.TimeUnit::SECONDS)).to be true
      expect_blocked_worker(workers.last, second_thread)
      release.count_down
      workers.each do |worker|
        expect(worker.join(10)).not_to be_nil
        worker.value
      end
      names = configuration_mapper.map(configuration).configs.flat_map { |config| config.items.to_a }
      expect(names).to include("Other", "ConcurrentFirst")
      if operation == :apply
        expect(names).to include("Reading", "ConcurrentSecond")
      else
        expect(names).not_to include("Reading")
      end
    ensure
      release&.count_down
      workers&.each { |worker| worker.kill unless worker.join(10) }
    end

    def configuration(service = service_id)
      configuration_registry.get(service)
    end

    def configure_service(service = service_id)
      dto = org.openhab.core.persistence.dto.PersistenceServiceConfigurationDTO.new
      dto.serviceId = service
      dto.aliases = { "Reading" => "StoredReading" }
      entry = org.openhab.core.persistence.dto.PersistenceItemConfigurationDTO.new
      entry.items = %w[Reading Other]
      entry.strategies = ["everyUpdate"]
      dto.configs = [entry]
      configuration_provider.add(configuration_mapper.map(dto))
    end

    before do
      configure_service
      services = OpenHAB::DSL::Items::Builder::Persistence.send(:service_registry)
      allow(services).to receive(:default_id).and_return(service_id)
    end

    after do
      configuration_provider.remove(service_id)
      configuration_provider.remove(other_service_id)
    end

    it "serializes concurrent additions" do
      check_concurrent_persistence(:apply)
    end

    it "serializes concurrent additions and removals" do
      check_concurrent_persistence(:remove)
    end

    it "serializes Ruby item removal and a concurrent rebuild" do
      check_removal_and_rebuild(:remove)
    end

    it "serializes Ruby provider clearing and a concurrent rebuild" do
      check_removal_and_rebuild(:clear)
    end

    it "serializes managed item removal and a concurrent rebuild" do
      check_removal_and_rebuild(:managed)
    end

    it "updates the existing provider for the default service without creating rules" do
      previous_rules = rules.to_a
      items.build { number_item "Reading", persist: :on_change }
      entries = configuration.configs
      expect(entries.find { |entry| entry.items.first.item == "Reading" }.strategies.map(&:name))
        .to eq ["everyChange"]
      expect(entries.find { |entry| entry.items.first.item == "Other" }.strategies.map(&:name))
        .to eq ["everyUpdate"]
      expect(configuration.aliases.to_h).to eq("Reading" => "StoredReading")
      expect(rules.to_a).to eq previous_rules
    end

    it "supports multiple services, native schedules, and restore strategies" do
      configure_service(other_service_id)
      selected_service = other_service_id
      items.build do
        number_item "Reading" do
          persist %i[on_change restore_on_startup], service: selected_service
          persist every: 5.minutes
          persist cron: "0 * * * * ?"
        end
      end
      entries = configuration(other_service_id).configs
      expect(entries.last.strategies.map(&:name)).to eq %w[everyChange restoreOnStartup]
      expect(configuration.strategies.map(&:cron_expression)).to contain_exactly("0 */5 * ? * ? *", "0 * * * * ?")
      expect(configuration.configs.to_a.last(2).flat_map { |entry| entry.strategies.map(&:name) }.uniq.size).to eq 2
    end

    it "accepts schedule options as a keyword and does not duplicate them on rebuild" do
      2.times { items.build { number_item "Reading", persist: { cron: "0 * * * * ?" } } }
      expect(configuration.strategies.size).to eq 1
      expect(configuration.configs.size).to eq 2
      expect(configuration.strategies.first.cron_expression).to eq "0 * * * * ?"
    end

    it "removes an item's persistence entries from every editable service" do
      configure_service(other_service_id)
      selected_service = other_service_id
      items.build do
        number_item "Reading" do
          persist :on_change
          persist :on_update, service: selected_service
        end
      end
      items.remove("Reading")
      [configuration, configuration(other_service_id)].each do |config|
        dto = configuration_mapper.map(config)
        expect(dto.configs.map { |entry| entry.items.to_a }).to eq [["Other"]]
        expect(dto.aliases).to be_empty
      end
    end

    it "cleans up when the Ruby provider removes an item directly" do
      items.build { number_item "Reading", persist: :on_change }
      Reading.provider.remove("Reading")
      expect(configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }).to eq [["Other"]]
    end

    it "cleans up when a transient item provider unloads" do
      OpenHAB::Core::Items::Provider.new do
        items.build { number_item "Reading", persist: :on_change }
      end
      expect(items["Reading"]).to be_nil
      expect(configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }).to eq [["Other"]]
    end

    it "updates each affected service once when clearing a Ruby item provider" do
      configure_service(other_service_id)
      selected_service = other_service_id
      items.build do
        number_item "Reading" do
          persist every: 5.minutes
          persist :on_update, service: selected_service
        end
        number_item "Other" do
          persist every: 5.minutes
          persist :on_change, service: selected_service
        end
      end
      provider = Reading.provider
      allow(configuration_registry).to receive(:provider_for).and_call_original
      allow(configuration_registry).to receive(:provider_for).with(configuration).and_return(configuration_provider)
      allow(configuration_registry).to receive(:provider_for).with(configuration(other_service_id))
                                                             .and_return(configuration_provider)
      allow(configuration_provider).to receive(:update).and_call_original
      provider.clear
      expect(configuration_provider).to have_received(:update).with(
        have_attributes(uid: service_id)
      ).once
      expect(configuration_provider).to have_received(:update).with(
        have_attributes(uid: other_service_id)
      ).once
      [configuration, configuration(other_service_id)].each do |config|
        expect(config.configs).to be_empty
        expect(config.aliases).to be_empty
        expect(config.strategies).to be_empty
      end
      expect(items["Reading"]).to be_nil
      expect(items["Other"]).to be_nil
    end

    it "retains persistence for persistent items until they are removed" do
      OpenHAB::Core::Items::Provider.new do
        items.build(:persistent) { number_item "Reading", persist: :on_change }
      end
      expect(items["Reading"]).not_to be_nil
      expect(configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a })
        .to include(["Reading"])
      items.remove("Reading")
      expect(configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }).to eq [["Other"]]
    ensure
      items.remove("Reading") if items["Reading"]
    end

    [nil, :persistent].each do |item_provider|
      it "cleans up recursively removed groups and members with provider #{item_provider.inspect}" do
        items.build(item_provider) do
          group_item "Readings", persist: :on_update do
            group_item "NestedReadings", persist: :on_change do
              number_item "Reading", persist: :on_change
            end
          end
        end
        items.remove("Readings", recursive: true)
        expect(items.to_a.map(&:name)).not_to include("Readings", "NestedReadings", "Reading")
        expect(configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }).to eq [["Other"]]
      ensure
        items.remove("Reading") if items["Reading"]
        items.remove("NestedReadings") if items["NestedReadings"]
        items.remove("Readings") if items["Readings"]
      end
    end

    it "preserves shared schedules until their last item is removed" do
      items.build do
        number_item "Reading", persist: { every: 5.minutes }
        number_item "Other", persist: { every: 5.minutes }
      end
      expect(configuration.strategies.size).to eq 1
      items.remove("Reading")
      expect(configuration.strategies.size).to eq 1
      expect(configuration.configs.last.items.first.item).to eq "Other"
      items.remove("Other")
      expect(configuration.configs).to be_empty
      expect(configuration.strategies).to be_empty
    end

    it "updates persistence once when recursively removing Ruby items" do
      items.build do
        group_item "Readings", persist: :on_update do
          group_item "NestedReadings", persist: :on_change do
            number_item "Reading", persist: :on_change
          end
        end
      end
      allow(configuration_registry).to receive(:provider_for).and_call_original
      allow(configuration_registry).to receive(:provider_for).with(configuration).and_return(configuration_provider)
      allow(configuration_provider).to receive(:update).and_call_original
      removed = Readings.provider.remove("Readings", true)
      expect(removed.name).to eq "Readings"
      expect(configuration_provider).to have_received(:update).once
      expect(configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }).to eq [["Other"]]
      expect(items.to_a.map(&:name)).not_to include("Readings", "NestedReadings", "Reading")
    end

    it "preserves items and persistence owned by another Ruby provider during recursive removal" do
      items.build { group_item "Readings", persist: :on_update }
      provider = Readings.provider
      OpenHAB::Core::Items::Provider.new do
        items.build { number_item "Reading", group: "Readings", persist: :on_change }
        provider.remove("Readings", true)
        expect(items["Readings"]).to be_nil
        expect(items["Reading"]).not_to be_nil
        entries = configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }
        expect(entries).to contain_exactly(["Reading"], ["Other"])
      end
    end

    it "cleans up only deleted items when recursive removal fails" do
      items.build do
        group_item "Readings", persist: :on_update do
          number_item "Reading", persist: :on_change
        end
      end
      provider = Readings.provider
      allow(provider).to receive(:notify_listeners_about_removed_element).and_wrap_original do |original, item|
        original.call(item)
        raise "Removal failed" if item.name == "Readings"
      end
      expect { provider.remove("Readings", true) }.to raise_error("Removal failed")
      expect(items["Readings"]).to be_nil
      expect(items["Reading"]).not_to be_nil
      entries = configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }
      expect(entries).to contain_exactly(["Reading"], ["Other"])
    end

    it "discards obsolete generated schedules when rebuilding an item" do
      items.build { number_item "Reading", persist: { every: 5.minutes } }
      items.build { number_item "Reading", persist: { every: 10.minutes } }
      expect(configuration.strategies.map(&:cron_expression)).to eq ["0 */10 * ? * ? *"]
      items.build { number_item "Reading", persist: :on_change }
      expect(configuration.strategies).to be_empty
    end

    it "preserves schedules used by other items when replacing an item's schedule" do
      items.build do
        number_item "Reading", persist: { every: 5.minutes }
        number_item "Other", persist: { every: 5.minutes }
      end
      items.build { number_item "Reading", persist: :on_change }
      expect(configuration.strategies.map(&:cron_expression)).to eq ["0 */5 * ? * ? *"]
    end

    it "updates persistence once when recursively removing persistent items" do
      items.build(:persistent) do
        group_item "Readings", persist: :on_update do
          number_item "Reading", persist: :on_change
        end
        number_item "Other", persist: :on_update
      end
      allow(configuration_registry).to receive(:provider_for).and_call_original
      allow(configuration_registry).to receive(:provider_for).with(configuration).and_return(configuration_provider)
      allow(configuration_provider).to receive(:update).and_call_original
      items.remove("Readings", recursive: true)
      expect(configuration_provider).to have_received(:update).once
      expect(configuration_mapper.map(configuration).configs.map { |entry| entry.items.to_a }).to eq [["Other"]]
      expect(items["Other"]).not_to be_nil
    ensure
      items.remove("Readings", recursive: true) if items["Readings"]
      items.remove("Other") if items["Other"]
    end

    it "does not commit persistence if item registration fails" do
      items.build { number_item "Reading" }
      original = configuration
      expect do
        items.build(update: false) { number_item "Reading", persist: :on_change }
      end.to raise_error(ArgumentError, /already exists/)
      expect(configuration).to eq original
    end

    it "preserves existing configuration when persist is omitted" do
      original = configuration
      items.build { number_item "Reading" }
      expect(configuration).to eq original
    end

    it "supports group and member declarations" do
      items.build do
        group_item "Readings", persist: :on_update do
          number_item "Reading", persist: :on_change
        end
      end
      names = configuration.configs.flat_map { |entry| entry.items.map(&:item) }
      expect(names).to contain_exactly("Reading", "Readings", "Other")
    end

    it "uses named filters configured in the UI and preserves them through serialization" do
      dto = configuration_mapper.map(configuration)
      filter = org.openhab.core.persistence.dto.PersistenceFilterDTO.new
      filter.name = "within_range"
      filter.lower = java.math.BigDecimal.new("5")
      filter.upper = java.math.BigDecimal.new("10")
      filter.inverted = false
      dto.includeFilters = [filter]
      configuration_provider.update(configuration_mapper.map(dto))
      items.build do
        number_item "Reading" do
          persist :on_update, filter: :within_range
        end
      end
      restored = configuration_mapper.map(configuration_mapper.map(configuration))
      entry = restored.configs.last
      expect(entry.filters.map(&:name)).to eq ["within_range"]
      Reading.update(3)
      expect(entry.filters.first.apply(Reading.__getobj__)).to be false
      Reading.update(7)
      expect(entry.filters.first.apply(Reading.__getobj__)).to be true
    end

    it "rejects file-owned configurations without modifying them" do
      original = configuration
      provider = instance_double(org.openhab.core.persistence.registry.PersistenceServiceConfigurationProvider)
      allow(configuration_registry).to receive(:provider_for).with(original).and_return(provider)
      expect do
        items.build { number_item "Reading", persist: :on_change }
      end.to raise_error(FrozenError, /configure persistence through the UI/)
      expect(configuration).to eq original
    end

    it "requires a service configuration created in the UI" do
      missing_service = other_service_id
      expect do
        items.build { number_item "Reading", persist: { service: missing_service, cron: "0 * * * * ?" } }
      end.to raise_error(ArgumentError, /through the UI/)
      expect(configuration(other_service_id)).to be_nil
    end

    it "preserves wildcard and group configurations" do
      dto = configuration_mapper.map(configuration)
      entry = org.openhab.core.persistence.dto.PersistenceItemConfigurationDTO.new
      entry.items = ["*", "Readings*"]
      entry.strategies = ["everyChange"]
      dto.configs = dto.configs.to_a + [entry]
      configuration_provider.update(configuration_mapper.map(dto))
      items.build { number_item "Reading", persist: :on_update }
      saved = configuration_mapper.map(configuration)
      expect(saved.configs.map { |config| config.items.to_a }).to include(["*", "Readings*"])
    end

    it "validates all selected services before changing any configuration" do
      original = configuration
      missing_service = other_service_id
      expect do
        items.build do
          number_item "Reading" do
            persist :on_change
            persist :on_update, service: missing_service
          end
        end
      end.to raise_error(ArgumentError, /through the UI/)
      expect(configuration).to eq original
    end

    it "requires a default service when no service is specified" do
      services = OpenHAB::DSL::Items::Builder::Persistence.send(:service_registry)
      allow(services).to receive(:default_id).and_return(nil)
      expect do
        items.build { number_item "Reading", persist: :on_change }
      end.to raise_error(ArgumentError, /No default persistence service/)
    end

    it "rejects invalid schedules before adding an item" do
      expect do
        items.build { number_item "Reading", persist: { cron: "not a cron expression" } }
      end.to raise_error(ArgumentError, /cron expression/)
      expect(items["Reading"]).to be_nil
    end

    it "rejects unknown strategies before adding the item" do
      expect do
        items.build { number_item "Reading", persist: :unknown }
      end.to raise_error(ArgumentError, /strategy/)
      expect(items["Reading"]).to be_nil
    end

    it "rejects callable filters instead of UI-configured filter names" do
      expect do
        items.build do
          number_item "Reading" do
            persist :on_update, filter: ->(value) { value.between?(5, 10) }
          end
        end
      end.to raise_error(ArgumentError, /filters configured in the UI/)
    end

    it "rejects unknown filters without changing the configuration" do
      original = configuration
      expect do
        items.build { number_item "Reading", persist: { cron: "0 * * * * ?", filter: :unknown } }
      end.to raise_error(ArgumentError, /Unknown persistence filters/)
      expect(configuration).to eq original
      expect(items["Reading"]).to be_nil
    end

    it "leaves existing item properties, metadata, state, and links unchanged on persistence errors" do
      things.build do
        thing "a:b:c" do
          channel "old", "number"
          channel "new", "number"
        end
      end
      items.build do
        number_item "Reading", "Original", state: 7, channel: "a:b:c:old", autoupdate: false
      end
      original = Reading.__getobj__
      expect do
        items.build do
          number_item "Reading", "Changed", state: 9, channel: "a:b:c:new", autoupdate: true do
            persist :on_change, filter: :unknown
          end
        end
      end.to raise_error(ArgumentError, /Unknown persistence filters/)
      expect(Reading.__getobj__).to equal original
      expect(Reading.label).to eq "Original"
      expect(Reading.state).to eq 7
      expect(Reading.metadata[:autoupdate].value).to eq "false"
      expect(Reading.links.map { |link| link.linked_uid.to_s }).to eq ["a:b:c:old"]
    end
  end

  context "when items already exist and build is called" do
    context "with update: false" do
      it "raises an error" do
        items.build { switch_item "Switch1" }
        expect { items.build(update: false) { switch_item "Switch1" } }.to raise_error(ArgumentError)
      end

      it "the failure in creating the new item doesn't cause any changes to the original item" do
        things.build do
          thing "a:b:c" do
            channel "old", "switch"
            channel "new", "switch"
          end
        end

        properties = {
          tags: ["Light"],
          unit: "W",
          format: "%f",
          ga: ["Light", {}],
          groups: ["Group1"],
          icon: "light",
          autoupdate: "true",
          expire: "1h",
          channel: "a:b:c:old",
          state: 1
        }.freeze

        items.build { number_item "Number1", "Old Label", **properties }

        expect do
          items.build(update: false) do
            number_item "Number1",
                        "New Label",
                        tags: "Measurement",
                        unit: "°C",
                        format: "%s",
                        ga: "Fan",
                        groups: "Group2",
                        icon: "window",
                        autoupdate: "false",
                        expire: ["2h", { ignore_state_updates: true }],
                        channel: "a:b:c:new",
                        state: 2
          end
        end.to raise_error(ArgumentError)
        expect(Number1.label).to eql "Old Label"
        expect(Number1.tags.to_a).to eql properties[:tags]
        expect(Number1.unit.to_s).to eql properties[:unit]
        expect(Number1.state_description.pattern).to eql properties[:format]
        expect(Number1.metadata[:ga]).to eq properties[:ga]
        expect(Number1.group_names.to_a).to eql properties[:groups]
        expect(Number1.category).to eql properties[:icon]
        expect(Number1.metadata[:autoupdate].value).to eql properties[:autoupdate]
        expect(Number1.metadata[:expire].value).to eq properties[:expire]
        expect(Number1.metadata[:expire]).to be_empty
        expect(Number1.links.first.linked_uid.to_s).to eql properties[:channel]
        expect(Number1.links.size).to be 1
        expect(Number1.state.to_i).to eql properties[:state]
      end
    end

    context "with the default argument (update: true)" do
      subject(:item) { Built }

      it "raises an error if the existing item is from a different provider" do
        item_name = "ItemFromAnotherProvider"
        existing_item = OpenHAB::Core::Items::StringItem.new(item_name)
        generic_item_provider = OpenHAB::OSGi.service("org.openhab.core.items.ItemProvider")
        allow(OpenHAB::DSL.items).to receive(:key?).with(item_name).and_return(true)
        allow(OpenHAB::DSL.items).to receive(:[]).with(item_name).and_return(existing_item)
        allow(existing_item).to receive(:provider).and_return(generic_item_provider)
        expect { items.build { number_item item_name } }.to raise_error(FrozenError)
      end

      #
      # Create an item, then create it again with build(update: true)
      #
      # @param [Hash] org_config Config to create the original item
      # @param [Hash] new_config Config to create the new item
      # @param [true,false] update_expected Whether the provider should update the item with the new config
      # @return [Array<OpenHAB::Core::Items::Item, OpenHAB::Core::Items::Item>]
      #   An array of [original item, updated item]. These are unproxied raw items
      #
      def build_and_update(org_config, new_config, update_expected: true, &block)
        org_config = org_config.dup
        new_config = new_config.dup
        org_item = items.build do
          send("#{org_config.delete(:type) || "number"}_item", "Built", org_config.delete(:label), **org_config)
        end
        yield :original, org_item if block

        if update_expected
          expect(org_item.provider).to receive(:update).and_call_original
        else
          expect(org_item.provider).not_to receive(:update)
        end

        new_item = items.build do
          send("#{new_config.delete(:type) || "number"}_item", "Built", new_config.delete(:label), **new_config)
        end
        yield :updated, new_item if block

        [org_item, new_item]
      end

      context "with changes" do
        it "replaces the old item when the item type is different" do
          build_and_update({ type: "switch" }, { type: "string" })
          expect(item).to be_a_string_item
        end

        it "replaces the old item when the label is different" do
          build_and_update({ label: "Old Label" }, { label: "New Label" })
          expect(item.label).to eql "New Label"
        end

        it "replaces the old item when the dimension is different" do
          build_and_update({ dimension: "Power" }, { dimension: "Length" })
          expect(item.dimension.ruby_class).to be javax.measure.quantity.Length
        end

        it "replaces the old item when a unit is added" do
          build_and_update({}, { unit: "W" })
          expect(item.unit.to_s).to eql "W"
        end

        it "replaces the old item when a unit is removed" do
          build_and_update({ unit: "W" }, {})
          expect(item.unit).to be_nil
        end

        it "replaces the old item when the groups changed" do
          build_and_update({ group: "Group1" }, { groups: %w[Group1 Group2] })
          expect(item.group_names).to match_array %w[Group1 Group2]
        end

        it "replaces the old item when the tags changed" do
          build_and_update({ tags: %w[Tag1 Tag2 Light] }, { tags: %w[Tag1 Tag2] }) do |built, item|
            expect(item.metadata[:semantics]).not_to be_nil if built == :original
          end
          expect(item.tags).to match_array %w[Tag1 Tag2]
          expect(item.metadata[:semantics]).to be_nil
        end

        it "replaces the old item when icon is different" do
          build_and_update({ icon: :light }, {}) do |built, item|
            case built
            when :original then expect(item.category).to eql "light"
            when :updated then expect(item.category).to be_nil
            end
          end
        end

        it "keeps the old item but updates its links when the channels are different" do
          things.build do
            thing "a:b:c" do
              channel "old", "number"
              channel "new", "number"
            end
          end
          build_and_update({ channel: "a:b:c:old" }, { channel: "a:b:c:new" }, update_expected: false)
          expect(item.links.map(&:linked_uid)).to match_array(things["a:b:c"].channels["new"].uid)
        end

        it "keeps the old item but updates its links when the channel configs are different" do
          things.build do
            thing "a:b:c" do
              channel "d", "number"
            end
          end
          build_and_update({ channel: ["a:b:c:d", { foo: "bar" }] },
                           { channel: ["a:b:c:d", { foo: "qux" }] },
                           update_expected: false)
          link = item.links.first
          expect(link.linked_uid).to eql things["a:b:c"].channels["d"].uid
          expect(link.configuration).to eq({ "foo" => "qux" })
        end

        it "replaces the old item when necessary but verifies that channels remain the same" do
          things.build do
            thing "a:b:c" do
              channel "d", "number"
            end
          end
          channel_config = { "foo" => "bar" }.freeze
          build_and_update({ channel: ["a:b:c:d", channel_config] },
                           { channel: ["a:b:c:d", channel_config], label: "x" })
          link = item.links.first
          expect(link.linked_uid).to eql things["a:b:c"].channels["d"].uid
          expect(link.configuration).to eq channel_config
        end

        it "keeps the old item but delete its metadata when the new item has no metadata" do
          build_and_update({ metadata: { foo: "baz" } }, {}, update_expected: false)
          expect(item.metadata.key?(:foo)).to be false
        end

        it "keeps the old item but reset to the new metadata" do
          build_and_update({ metadata: { foo: "bar", moo: "cow" } },
                           { metadata: { foo: "baz", qux: "quux" } },
                           update_expected: false)
          expect(item.metadata[:foo].value).to eq "baz"
          expect(item.metadata[:qux].value).to eq "quux"
          expect(item.metadata.key?(:moo)).to be false
        end

        it "works when there's a special semantics (unmanaged) metadata" do
          build_and_update({ tags: "Lightbulb", metadata: { qux: "quux" } },
                           { tags: "Lightbulb", metadata: { foo: "bar" } },
                           update_expected: false) do |type, item|
            expect(item.metadata[:semantics]).not_to be_nil if type == :original
          end
          expect(item.metadata.key?(:qux)).to be false
          expect(item.metadata[:foo].value).to eql "bar"
        end

        it "keeps the old item when only the format (state description metadata) is different" do
          build_and_update({ format: "OLD %s" }, { format: "NEW %s" }, update_expected: false)
          expect(item.state_description.pattern).to eql "NEW %s"
        end

        it "keeps the old item when autoupdate (metadata) is different" do
          build_and_update({ autoupdate: true }, { autoupdate: false }, update_expected: false)
          expect(item.metadata[:autoupdate].value).to eql "false"
        end

        it "keeps the old item but remove autoupdate (metadata)" do
          build_and_update({ autoupdate: true }, {}, update_expected: false)
          expect(item.metadata.key?(:autoupdate)).to be false
        end

        it "keeps the old item but add expire (metadata)" do
          build_and_update({}, { expire: "5s" }, update_expected: false)
          expect(item.metadata[:expire].value).to eql "5s"
        end
      end

      context "with no changes" do
        it "keeps the old item" do
          properties = {
            label: "Just a label",
            tags: "Light",
            unit: "W",
            format: "%f",
            ga: "Light",
            groups: "Group1",
            icon: :light,
            autoupdate: true,
            expire: "1h",
            channel: "a:b:c:old"
          }.freeze

          build_and_update(properties, properties, update_expected: false)
        end

        it "keeps the old item but updates to the new state" do
          build_and_update({ state: 1 }, { state: 2 }, update_expected: false)
          expect(item.state).to eq 2
        end
      end
    end
  end

  it "can remove an item" do
    items.build { switch_item "MySwitchItem", autoupdate: false, channel: "binding:type:thing:channel" }
    items.remove(MySwitchItem)
    expect(items["MySwitchItem"]).to be_nil
    # make sure metadata and channel links also got cleaned up
    expect(OpenHAB::Core::Items::Metadata::Provider.instance.all).to be_empty
    expect(OpenHAB::Core::Things::Links::Provider.instance.all).to be_empty
  end

  it "can create items in a group" do
    items.build do
      group_item "Group1"
      group_item "MyGroupItem" do
        switch_item "MySwitchItem"
        switch_item "MySwitch2", groups: [Group1]
        switch_item "MySwitch3", groups: Group1
      end
    end

    expect(MyGroupItem.members.to_a).to match_array [MySwitchItem, MySwitch2, MySwitch3]
    expect(MySwitchItem.groups).to eq [MyGroupItem]
    expect(MySwitch2.groups).to match_array [Group1, MyGroupItem]
    expect(MySwitch3.groups).to match_array [Group1, MyGroupItem]
  end

  it "can add items to groups" do
    items.build do
      group_item "MyGroupItem"
      group_item "Group2"
      switch_item "MySwitchItem", group: MyGroupItem
      switch_item "MySwitchItem2", groups: [Group2]
      switch_item "MySwitchItem3", group: "MyGroupItem", groups: [Group2]
    end

    expect(MyGroupItem.members.to_a).to match_array [MySwitchItem, MySwitchItem3]
    expect(MySwitchItem.groups).to eql [MyGroupItem]
    expect(MySwitchItem2.groups).to eql [Group2]
    expect(MySwitchItem3.groups).to match_array [MyGroupItem, Group2]
  end

  it "can set a dimension on a number item" do
    items.build do
      number_item "MyNumberItem", dimension: "Power"
      number_item "MyNumberItem2", dimension: :ElectricPotential
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
    expect(MyNumberItem2.dimension.ruby_class).to be javax.measure.quantity.ElectricPotential
  end

  it "complains about invalid dimension" do
    expect { items.build { number_item "MyNumberItem", dimension: "Foo" } }.to raise_error(ArgumentError)
  end

  it "can set a unit on a number item" do
    items.build do
      number_item "MyNumberItem", dimension: "Power", unit: "kW"
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
    expect(MyNumberItem.metadata["unit"].value).to eql "kW"
    expect(MyNumberItem.unit.to_s).to eql "kW"
  end

  it "can infer the dimension from the explicit unit for a number item" do
    items.build do
      number_item "MyNumberItem", unit: "kW"
      number_item "ColorTempItem", unit: "mired"
    end
    expect(MyNumberItem.dimension.ruby_class).to be javax.measure.quantity.Power
    expect(MyNumberItem.metadata["unit"].value).to eql "kW"
    expect(ColorTempItem.dimension.ruby_class).to be javax.measure.quantity.Temperature
    expect(ColorTempItem.metadata["unit"].value).to eql "mired"
    expect(MyNumberItem.unit.to_s).to eql "kW"
    expect(MyNumberItem.state_description.pattern).to eql "%s %unit%"
  end

  it "can format a number item" do
    items.build do
      number_item "MyNumberItem", format: "something %d else"
    end

    MyNumberItem.update(1)
    expect(MyNumberItem.state_description.pattern).to eql "something %d else"
  end

  it "can set a range on a number item" do
    items.build do
      number_item "Number1", range: 5..10
      number_item "Number2", range: 2..10, step: 2
      number_item "Number3", range: Range.new(nil, 50)
      number_item "Number4", range: 50..
    end

    expect(Number1.state_description.minimum.to_i).to be 5
    expect(Number1.state_description.maximum.to_i).to be 10
    expect(Number1.state_description.step).to be_nil
    expect(Number2.state_description.minimum.to_i).to be 2
    expect(Number2.state_description.maximum.to_i).to be 10
    expect(Number2.state_description.step.to_i).to be 2
    expect(Number3.state_description.minimum).to be_nil
    expect(Number3.state_description.maximum.to_i).to be 50
    expect(Number4.state_description.minimum.to_i).to be 50
    expect(Number4.state_description.maximum).to be_nil
  end

  it "can set read only" do
    items.build do
      switch_item "Switch1", read_only: true
      switch_item "Switch2", read_only: false
      switch_item "Switch3"
    end

    expect(Switch1.state_description).to be_read_only
    expect(Switch2.state_description).not_to be_read_only
    expect(Switch3.state_description).to be_nil
  end

  it "can set state options" do
    items.build do
      string_item "Text1", state_options: %w[LOCKED UNLOCKED]
      switch_item "Lock1", state_options: { ON => "LOCKED", OFF => "UNLOCKED" }
    end

    expect(Text1.state_description.options.to_h { |o| [o.value, o.label] }).to eql({
                                                                                     "LOCKED" => nil,
                                                                                     "UNLOCKED" => nil
                                                                                   })
    expect(Lock1.state_description.options.to_h { |o| [o.value, o.label] }).to eql({
                                                                                     "ON" => "LOCKED",
                                                                                     "OFF" => "UNLOCKED"
                                                                                   })
  end

  it "can set command options" do
    items.build do
      string_item "Text1", command_options: %w[LOCKED UNLOCKED]
      switch_item "Lock1", command_options: { ON => "LOCKED", OFF => "UNLOCKED" }
    end

    expect(Text1.command_description.command_options.to_h { |o| [o.command, o.label] }).to eql({
                                                                                                 "LOCKED" => nil,
                                                                                                 "UNLOCKED" => nil
                                                                                               })
    expect(Lock1.command_description.command_options.to_h { |o| [o.command, o.label] }).to eql({
                                                                                                 "ON" => "LOCKED",
                                                                                                 "OFF" => "UNLOCKED"
                                                                                               })
  end

  it "does not overwrite an explicit format with the unit" do
    items.build do
      number_item "MyNumberItem", format: "something %d else", unit: "W"
    end

    MyNumberItem.update(1)
    expect(MyNumberItem.unit.to_s).to eql "W"
    expect(MyNumberItem.state_description.pattern).to eql "something %d else"
  end

  it "can set an icon" do
    items.build do
      switch_item "MySwitch", icon: :light
    end

    expect(MySwitch.category).to eql "light"
  end

  it "can add tags" do
    items.build do
      switch_item "MySwitch", tags: ["MyTag", Semantics::Switch]
      switch_item "MySwitch2", tag: "MyTag"
      switch_item "MySwitch3", tag: "MyTag", tags: ["MyTag2"]
      switch_item "MySwitch4", tags: "MyTag"
    end

    expect(MySwitch.tags).to match_array %w[MyTag Switch]
    expect(MySwitch2.tags).to match_array ["MyTag"]
    expect(MySwitch3.tags).to match_array %w[MyTag MyTag2]
    expect(MySwitch4.tags).to match_array ["MyTag"]
  end

  it "raises errors on invalid argument types" do
    rspec = self
    items.build do
      rspec.expect { switch_item "Switch1", tags: [1] }.to rspec.raise_error(ArgumentError)
      rspec.expect { switch_item "Switch1", tag: 2 }.to rspec.raise_error(ArgumentError)
      switch_item "SwitchNone"
      rspec.expect { switch_item "Switch1", group: SwitchNone }.to rspec.raise_error(ArgumentError)
      rspec.expect { switch_item "Switch1", groups: SwitchNone }.to rspec.raise_error(ArgumentError)
      rspec.expect { switch_item "Switch1", group: [SwitchNone] }.to rspec.raise_error(ArgumentError)
    end
  end

  it "can configure autoupdate" do
    items.build do
      switch_item "MySwitch1", autoupdate: true
      switch_item "MySwitch2", autoupdate: false
      switch_item "MySwitch3"
    end

    expect(MySwitch1.metadata["autoupdate"]&.value).to eq "true"
    expect(MySwitch2.metadata["autoupdate"]&.value).to eq "false"
    expect(MySwitch3.metadata["autoupdate"]).to be_nil
  end

  it "can configure expires" do
    items.build do
      switch_item "MySwitch1", expire: 1.hour
      switch_item "MySwitch2", expire: "2h"
      switch_item "MySwitch3", expire: [3.hours, OFF]
      switch_item "MySwitch4", expire: ["4h", { command: OFF }]
      switch_item "MySwitch5", expire: ["4h", { ignore_state_updates: true }]
      string_item "MyString", expire: [5.hours, "EXPIRED"]
    end

    expect(MySwitch1.metadata["expire"]&.value).to eq "1h"
    expect(MySwitch2.metadata["expire"]&.value).to eq "2h"
    expect(MySwitch3.metadata["expire"]&.value).to eq "3h,state=OFF"
    expect(MySwitch4.metadata["expire"]&.value).to eq "4h,command=OFF"
    expect(MySwitch5.metadata["expire"]).to eq ["4h", { "ignoreStateUpdates" => true }]
    expect(MyString.metadata["expire"]&.value).to eq "5h,state='EXPIRED'"
  end

  it "passes homekit helper on to metadata" do
    items.build do
      switch_item "MySwitch1", homekit: ["Switchable", { somethingElse: "more" }]
    end

    expect(MySwitch1.metadata["homekit"]&.value).to eql "Switchable"
    expect(MySwitch1.metadata["homekit"].to_h).to eql({ "somethingElse" => "more" })
  end

  it "prefixes group members" do
    items.build do
      group_item "MyGroup" do
        self.name_base = "Family"
        self.label_base = "Family Room "

        switch_item "Lights_Switch", "Lights"
        switch_item "Lamps_Switch", "Lamps"
      end
    end

    expect(FamilyLights_Switch.label).to eql "Family Room Lights"
    expect(FamilyLamps_Switch.label).to eql "Family Room Lamps"
  end

  context "with group items" do
    it "can create a group with a base type" do
      items.build do
        group_item "MyGroup", type: :switch
      end

      expect(MyGroup.base_item).to be_a(SwitchItem)
    end

    context "with a function" do
      it "can create a group with a function and base type and arguments" do
        items.build do
          group_item "MyGroup", type: :switch, function: "OR(ON,OFF)"
        end

        expect(MyGroup.base_item).to be_a(SwitchItem)
        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Or)
        expect(MyGroup.function.parameters.to_a).to eql [ON, OFF]
      end

      it "can create a group with a function and base type without an argument" do
        items.build do
          group_item "MyGroup", type: :number, function: "SUM"
        end

        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Sum)
        expect(MyGroup.function.parameters.to_a).to be_empty
      end

      it "can create a group with a simple COUNT function without quotes" do
        items.build do
          group_item "MyGroup", type: :number, function: "COUNT(ON)"
        end

        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Count)
        expect(MyGroup.function.parameters.to_a).to eq ["ON"]
      end

      it "can create a group with a complex COUNT function enclosed in double quotes" do
        items.build do
          group_item "MyGroup", type: :number, function: 'COUNT("(\w+\,\s\w+|[\d\/]*\,\d+\:\d*|[\w\d\:\s\-]+)")'
        end

        expect(MyGroup.function).to be_a(org.openhab.core.library.types.ArithmeticGroupFunction::Count)
        expect(MyGroup.function.parameters.to_a).to eq ['(\w+\,\s\w+|[\d\/]*\,\d+\:\d*|[\w\d\:\s\-]+)']
      end
    end
  end

  it "sets initial state" do
    items.build { number_item "Number1", state: 1 }

    expect(Number1.state).to eq 1
  end

  it "sets initial state on a switch with false" do
    items.build { switch_item "Switch1", state: false }
    expect(Switch1.state).to be OFF
  end

  it "sets initial state on a dimmer with an integer" do
    items.build { dimmer_item "Dimmer1", state: 50 }
    expect(Dimmer1.state).to eq 50
  end

  it "sets initial state on a date time item with a string" do
    items.build { date_time_item "DateTimeItem1", state: "1970-01-01T00:00:00+00:00" }
    expect(DateTimeItem1.state).to eq Time.parse("1970-01-01T00:00:00+00:00")
  end

  it "sets initial state on a group item" do
    items.build { group_item "GroupItem1", type: :switch, state: ON }
    expect(GroupItem1.state).to be ON
  end

  describe "entity lookup" do
    it "can reference a group item directly" do
      items.build do
        group_item "group1"
        group_item "group2", group: group1
      end
      expect(group2.groups).to eql [group1]
    end

    it "can reference a group item within another group_item" do
      items.build do
        group_item "group1"
        group_item "group2" do
          switch_item "switch1", group: group1
        end
      end
      expect(switch1.groups).to match_array([group1, group2])
    end

    it "can reference an item (constant) that doesn't exist yet" do
      items.build do
        switch_item Switch1
      end
      expect(Switch1).to be_a(SwitchItem)
    end

    it "can reference an item (method) that doesn't exist yet" do
      items.build do
        group_item gMyGroup
      end
      expect(gMyGroup).to be_a(GroupItem)
    end

    it "can reference an item (constant) that doesn't exist yet inside a group" do
      items.build do
        group_item "gMyGroup" do
          switch_item Switch1
        end
      end
      expect(Switch1).to be_a(SwitchItem)
    end

    it "can reference an item (method) that doesn't exist yet inside a group" do
      items.build do
        group_item "gMyGroup" do
          group_item gGroup2
        end
      end
      expect(gGroup2).to be_a(GroupItem)
    end

    it "can reference a group item within the item's block" do
      items.build do
        group_item "gTestGroup"
        number_item "TestItem" do
          group gTestGroup
        end
      end
      expect(TestItem.groups).to eql [gTestGroup]
    end
  end

  context "with a thing" do
    before do
      install_addon "binding-astro", ready_markers: "openhab.xmlThingTypes"
      things.build do
        thing "astro:sun:home", "Astro Sun Data", config: { "geolocation" => "0,0" }
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
    end

    it "can link an item to a channel" do
      items.build { string_item "StringItem1", channel: "astro:sun:home:season#name" }
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "can link an item to multiple channels" do
      things.build do
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
      items.build do
        date_time_item "DateTime1" do
          channel "astro:sun:home:rise#start"
          channel "astro:moon:home:rise#start"
        end
      end
      expect(DateTime1.things).to match_array([things["astro:sun:home"], things["astro:moon:home"]])
    end

    it "accepts multiple channels in an immediate argument" do
      items.build { string_item "StringItem1", channels: ["astro:sun:home:season#name", "astro:moon:home:season#name"] }
      expect(StringItem1.things).to match [things["astro:sun:home"], things["astro:moon:home"]]
    end

    it "accepts multiple channels with config in an immediate argument" do
      items.build do
        string_item "StringItem1",
                    channels: [["astro:sun:home:season#name", { config: 1 }], "astro:moon:home:season#name"]
      end
      expect(StringItem1.things).to match [things["astro:sun:home"], things["astro:moon:home"]]
    end

    it "rejects invalid channel data" do
      expect do
        items.build { string_item "StringItem1", channels: 1 }
      end.to raise_error(ArgumentError)
    end

    it "can link to an item channel with a profile" do
      items.build do
        date_time_item "LastUpdated", channel: ["astro:sun:home:season#name", { profile: "system:timestamp-update" }]
      end
      expect(LastUpdated.thing).to be things["astro:sun:home"]
    end

    it "combines thing (string) and channel" do
      items.build do
        string_item "StringItem1", thing: "astro:sun:home", channel: "season#name"
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "combines thing and channel" do
      items.build do
        string_item "StringItem1", thing: things["astro:sun:home"], channel: "season#name"
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "can use symbolic channel" do
      items.build do
        string_item "StringItem1", thing: "astro:sun:home" do
          channel :"season#name"
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "ignores thing when channel contains multiple segments" do
      items.build do
        string_item "StringItem1", thing: "foo:baz:bar", channel: "astro:sun:home:season#name"
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "allows mixing short and fully qualified channels" do
      things.build do
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
      items.build do
        string_item "StringItem1", thing: "astro:moon:home", channel: "astro:sun:home:rise#start" do
          channel "rise#start"
        end
      end
      expect(StringItem1.things).to match_array [things["astro:sun:home"], things["astro:moon:home"]]
    end

    it "implicitly assumes a group's thing (string) for channels" do
      items.build do
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", channel: "season#name"
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "implicitly assumes a group's thing for channels" do
      items.build do
        group_item "MyGroup", thing: things["astro:sun:home"] do
          string_item "StringItem1", channel: "season#name"
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "implicitly assumes a group's thing (string) for channels with multiple groups" do
      items.build do
        group_item "OtherGroup"
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", channel: "season#name", group: OtherGroup
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "implicitly assumes a group's thing (string) for channels with a latent added group" do
      items.build do
        group_item "OtherGroup"
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", channel: "season#name" do
            group "OtherGroup"
          end
        end
      end
      expect(StringItem1.thing).to be things["astro:sun:home"]
    end

    it "item's thing overrides group's thing" do
      things.build do
        thing "astro:moon:home", "Astro Moon Data", config: { "geolocation" => "0,0" }
      end
      items.build do
        group_item "MyGroup", thing: "astro:sun:home" do
          string_item "StringItem1", thing: "astro:moon:home", channel: "set#start"
        end
      end
      expect(StringItem1.thing).to be things["astro:moon:home"]
    end
  end
end
