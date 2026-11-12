# frozen_string_literal: true

require "digest"

module OpenHAB
  module DSL
    module Items
      module Builder
        # @!visibility private
        module Persistence
          STRATEGIES = {
            on_change: "everyChange",
            on_update: "everyUpdate",
            restore_on_startup: "restoreOnStartup",
            forecast: "forecast"
          }.freeze
          private_constant :STRATEGIES

          class << self
            def declaration(strategies, service:, every:, cron:, filter:)
              strategies = Array(strategies).map do |strategy|
                STRATEGIES.fetch(strategy) { raise ArgumentError, "Unknown persistence strategy: #{strategy.inspect}" }
              end
              filters = Array(filter).map do |name|
                unless name.is_a?(String) || name.is_a?(Symbol)
                  raise ArgumentError, "Persistence filters must name filters configured in the UI."
                end

                name.to_s
              end
              expressions = []
              if every
                cron_builder = Rules::Triggers::Cron
                expressions << if every.is_a?(Duration)
                                 cron_builder.from_duration(every, nil)
                               else
                                 cron_builder.from_symbol(every, nil)
                               end
              end
              expressions << cron if cron
              expressions.each do |expression|
                raise ArgumentError, "cron must be a String" unless expression.is_a?(String)

                begin
                  org.openhab.core.scheduler.CronAdjuster.new(expression)
                rescue java.lang.IllegalArgumentException => e
                  raise ArgumentError, e.message
                end
              end
              if strategies.empty? && expressions.empty?
                raise ArgumentError, "Persistence requires a strategy, every, or cron"
              end

              { service:, strategies: strategies.uniq, expressions: expressions.uniq, filters: filters.uniq }
            end

            def apply(name, declarations)
              return if declarations.empty?

              registry = configuration_registry
              services = service_registry
              grouped = declarations.group_by do |declaration|
                service = declaration[:service] || Thread.current[:openhab_persistence_service] || services.default_id
                raise ArgumentError, "No default persistence service is configured" unless service

                service.to_s
              end
              # Resolve and validate every selected service before writing any configuration.
              updates = grouped.map do |service, configs|
                configuration = registry.get(service)
                unless configuration
                  raise ArgumentError, "Configure persistence for #{service} through the UI before using persist"
                end

                provider = registry.provider_for(configuration)
                unless provider.is_a?(org.openhab.core.common.registry.ManagedProvider)
                  raise FrozenError, "Persistence configuration for #{service} is not editable through " \
                                     "the framework; configure persistence through the UI instead of a .persist file"
                end

                dto = mapper.map(configuration)
                replace_item(dto, name, configs)
                [provider, mapper.map(dto)]
              end
              updates.each { |provider, configuration| provider.update(configuration) }
            end

            def remove(*names)
              return if names.empty?

              registry = configuration_registry
              registry.all.each do |configuration|
                provider = registry.provider_for(configuration)
                next unless provider.is_a?(org.openhab.core.common.registry.ManagedProvider)

                dto = mapper.map(configuration)
                next unless dto.configs.any? { |config| config.items.to_a.intersect?(names) } ||
                            dto.aliases.keys.to_a.intersect?(names)

                remove_items(dto, names)
                dto.aliases = dto.aliases.to_h.except(*names)
                remove_unused_schedules(dto)
                provider.update(mapper.map(dto))
              end
            end

            private

            def configuration_registry
              @configuration_registry ||=
                OSGi.service("org.openhab.core.persistence.registry.PersistenceServiceConfigurationRegistry")
            end

            def service_registry
              @service_registry ||= OSGi.service("org.openhab.core.persistence.PersistenceServiceRegistry")
            end

            def remove_items(dto, names)
              dto.configs = dto.configs.to_a.filter_map do |config|
                config.items = config.items.to_a - names
                config unless config.items.empty?
              end
            end

            def remove_unused_schedules(dto)
              used = dto.configs.flat_map { |config| config.strategies.to_a }
              used.concat(dto.defaults.to_a) if dto.defaults
              dto.cronStrategies = dto.cronStrategies.reject do |strategy|
                strategy.name == "jruby_#{Digest::SHA256.hexdigest(strategy.cronExpression)}" &&
                  !used.include?(strategy.name)
              end
            end

            def mapper
              org.openhab.core.persistence.registry.PersistenceServiceConfigurationDTOMapper
            end

            def replace_item(dto, name, declarations)
              remove_items(dto, [name])
              configs = dto.configs.to_a
              cron_strategies = dto.cronStrategies.to_a
              filters = mapper.map(dto).filters.map(&:name)
              declarations.each do |declaration|
                unknown_filters = declaration[:filters] - filters
                unless unknown_filters.empty?
                  raise ArgumentError, "Unknown persistence filters for #{dto.serviceId}: #{unknown_filters.join(", ")}"
                end

                strategies = declaration[:strategies] + declaration[:expressions].map do |expression|
                  strategy = cron_strategies.find { |existing| existing.cronExpression == expression }
                  unless strategy
                    strategy = org.openhab.core.persistence.dto.PersistenceCronStrategyDTO.new
                    strategy.name = "jruby_#{Digest::SHA256.hexdigest(expression)}"
                    strategy.cronExpression = expression
                    cron_strategies << strategy
                  end
                  strategy.name
                end
                config = org.openhab.core.persistence.dto.PersistenceItemConfigurationDTO.new
                config.items = [name]
                config.strategies = strategies.uniq
                config.filters = declaration[:filters]
                configs << config
              end
              dto.configs = configs
              dto.cronStrategies = cron_strategies
            end
          end
        end
      end
    end
  end
end
