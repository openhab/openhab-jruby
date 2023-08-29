# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::GroupItem do
  before do
    items.build do
      group_item "Sensors" do
        group_item "Temperatures", type: :number, function: "AVG"
      end

      group_item "House" do
        group_item "GroundFloor" do
          group_item "LivingRoom" do
            number_item "LivingRoom_Temp", "Living Room Temperature", state: 70, group: Temperatures
          end
          number_item "Bedroom_Temp", "Bedroom Temperature", state: 50, group: Temperatures
          number_item "Den_Temp", "Den Temperature", state: 30, group: Temperatures
        end
      end
    end
  end

  it "does not respond to #to_a" do
    expect(Temperatures.respond_to?(:to_a)).to be false
  end

  describe "#members" do
    it "is enumerable" do
      expect(Temperatures.members.count).to be 3
      expect(Temperatures.members.map(&:label)).to match_array ["Bedroom Temperature", "Den Temperature",
                                                                "Living Room Temperature"]
    end

    it "does math" do
      expect(Temperatures.members.map(&:state).max).to eq 70
      expect(Temperatures.members.map(&:state).min).to eq 30
    end

    it "is a live view" do
      expect(Temperatures.members.map(&:name)).to match_array %w[Bedroom_Temp Den_Temp LivingRoom_Temp]
      items.build do
        number_item "Kitchen_Temp", group: Temperatures
        number_item "Basement_Temp"
      end
      expect(Temperatures.members.map(&:name)).to match_array %w[Bedroom_Temp Den_Temp Kitchen_Temp
                                                                 LivingRoom_Temp]
    end

    it "can be added to an array" do
      expect([Temperatures] + LivingRoom.members).to match_array [Temperatures, LivingRoom_Temp]
      expect(LivingRoom.members + [Temperatures]).to match_array [Temperatures, LivingRoom_Temp]
      expect(LivingRoom.members + GroundFloor.members).to match_array [LivingRoom_Temp, Bedroom_Temp, Den_Temp,
                                                                       LivingRoom]
    end
  end

  describe "#all_members" do
    it "is enumerable" do
      expect(House.all_members.count).to be 3
      expect(House.all_members.map(&:label)).to match_array [
        "Bedroom Temperature",
        "Den Temperature",
        "Living Room Temperature"
      ]
    end
  end

  describe "#function" do
    describe "#to_s" do
      it "returns the function name in uppercase" do
        expect(Temperatures.function.to_s).to eql "AVG"
      end
    end

    describe "#inspect" do
      it "includes the function" do
        items.build do
          group_item "Switches", type: :switch, function: "OR(ON,OFF)"
        end
        expect(Switches.function.inspect).to eql "OR(ON,OFF)"
      end
    end

    context "with predicates" do
      it "works" do
        items.build do
          group_item Equality, type: :switch
          group_item Count, type: :number, function: "COUNT(ON)"
          group_item Min, type: :number, function: "MIN"
          group_item Max, type: :number, function: "MAX"
          group_item Sum, type: :number, function: "SUM"
          group_item Avg, type: :number, function: "AVG"
          group_item And, type: :switch, function: "AND(ON,OFF)"
          group_item Or, type: :switch, function: "OR(ON,OFF)"
          group_item Nor, type: :switch, function: "NOR(ON,OFF)"
          group_item Nand, type: :switch, function: "NAND(ON,OFF)"
          group_item Earliest, type: :date_time, function: "EARLIEST"
          group_item Latest, type: :date_time, function: "LATEST"
        end

        functions = %i[equality? count? min? max? sum? avg? and? or? nor? nand? earliest? latest?]

        functions.each do |current|
          item = items[current.to_s.delete_suffix("?").capitalize]
          logger.info "#{item} #{item.function} -> #{current}: #{item.function.send(current)}"
          expect(item.function.send(current)).to be true

          (functions - [current]).each do |other_function|
            logger.info "#{item} #{item.function} -> #{other_function}: #{item.function.send(other_function)}"
            expect(item.function.send(other_function)).to be false
          end
        end
      end
    end
  end

  describe "#command" do
    it "propagates to all items" do
      GroundFloor.command(60)
      expect(Bedroom_Temp.state).to eq 60
      expect(Den_Temp.state).to eq 60
    end
  end

  describe "#method_missing" do
    it "has command methods for the group type" do
      items.build do
        group_item "Switches", type: :switch
      end
      Switches.on
    end
  end

  describe "#inspect" do
    it "includes the base type" do
      items.build do
        group_item "Switches", type: :switch
      end
      expect(Switches.inspect).to eql "#<OpenHAB::Core::Items::GroupItem:Switch Switches nil state=NULL>"
    end

    it "includes the function" do
      items.build do
        group_item "Switches", type: :switch, function: "OR(ON,OFF)"
      end
      expect(Switches.inspect).to eql "#<OpenHAB::Core::Items::GroupItem:Switch:OR(ON,OFF) Switches nil state=NULL>"
    end
  end
end
