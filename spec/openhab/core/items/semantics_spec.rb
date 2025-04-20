# frozen_string_literal: true

RSpec.describe OpenHAB::Core::Items::Semantics do
  before do
    items.build do
      group_item "gMyGroup"
      group_item "gOutdoor", tag: Semantics::Outdoor do
        group_item "gPatio", tag: Semantics::Patio do
          group_item "Patio_Light_Bulb", tag: Semantics::Lightbulb do
            dimmer_item "Patio_Light_Brightness", tags: [Semantics::Control, Semantics::Level]
            color_item "Patio_Light_Color", tags: [Semantics::Control, Semantics::Light]
            number_item "Patio_Light_Power", tags: [Semantics::Measurement, Semantics::Power]
            switch_item "Patio_Light_ControlPower", tags: [Semantics::Control, Semantics::Power]
          end

          switch_item "Patio_Motion", tags: [Semantics::MotionDetector, "CustomTag"]
          switch_item "Patio_Point", tag: Semantics::Control
        end
      end
      group_item "gIndoor", tag: Semantics::Indoor do
        group_item "gLivingRoom", tag: Semantics::LivingRoom do
          group_item "LivingRoom_Light1_Bulb", group: gMyGroup, tag: Semantics::Lightbulb do
            dimmer_item "LivingRoom_Light1_Brightness", tags: [Semantics::Control, Semantics::Level]
            color_item "LivingRoom_Light1_Color", tags: [Semantics::Control, Semantics::Light]
            switch_item "LivingRoom_Light1_Custom", group: gMyGroup
          end
          group_item "LivingRoom_Light2_Bulb", tags: [Semantics::Lightbulb, "CustomTag"] do
            dimmer_item "LivingRoom_Light2_Brightness", tags: [Semantics::Control, Semantics::Level]
            color_item "LivingRoom_Light2_Color", tags: [Semantics::Control, Semantics::Light]
          end
          switch_item "LivingRoom_Motion", tag: Semantics::MotionDetector
        end
      end
      switch_item "NoSemantic"
    end
  end

  describe "provides semantic predicates" do
    specify { expect(gIndoor).to be_location }
    specify { expect(gIndoor).not_to be_equipment }
    specify { expect(gIndoor).not_to be_point }
    specify { expect(NoSemantic).not_to be_semantic }
    specify { expect(Patio_Light_Bulb).to be_semantic }
    specify { expect(Patio_Light_Bulb).to be_equipment }
    specify { expect(Patio_Motion).to be_equipment }
  end

  describe "semantic types methods" do
    specify { expect(Patio_Light_Bulb.location_type).to be Semantics::Patio }
    specify { expect(Patio_Light_Bulb.equipment_type).to be Semantics::Lightbulb }
    specify { expect(Patio_Light_Brightness.point_type).to be Semantics::Control }
    specify { expect(Patio_Light_Brightness.property_type).to be Semantics::Level }
    specify { expect(Patio_Light_Brightness.equipment_type).to be Semantics::Lightbulb }
    specify { expect(Patio_Light_Brightness.semantic_type).to be Semantics::Control }
  end

  describe "related semantic item methods" do
    specify { expect(Patio_Light_Bulb.location).to be gPatio }
    specify { expect(Patio_Light_Brightness.location).to be gPatio }
    specify { expect(Patio_Light_Brightness.equipment).to be Patio_Light_Bulb }
  end

  describe "#points" do
    it "returns siblings of a point" do
      expect(Patio_Light_Brightness.points).to eql [Patio_Light_Color, Patio_Light_Power, Patio_Light_ControlPower]
    end

    describe "returns points of an equipment" do
      specify do
        expect(Patio_Light_Bulb.points).to match_array([Patio_Light_Brightness,
                                                        Patio_Light_Color,
                                                        Patio_Light_Power,
                                                        Patio_Light_ControlPower])
      end

      specify { expect(Patio_Light_Bulb.points(Semantics::Light)).to eql [Patio_Light_Color] }
      specify { expect(Patio_Light_Bulb.points(Semantics::Level)).to eql [Patio_Light_Brightness] }
      specify { expect(Patio_Light_Bulb.points(Semantics::Level, Semantics::Control)).to eql [Patio_Light_Brightness] }
      specify { expect(Patio_Light_Bulb.points([Semantics::Measurement, Semantics::Power])).to eql [Patio_Light_Power] }

      specify do
        expect(Patio_Light_Bulb.points(Semantics::Control, Semantics::Measurement))
          .to match_array([Patio_Light_Brightness,
                           Patio_Light_Color,
                           Patio_Light_Power,
                           Patio_Light_ControlPower])
      end

      specify do
        expect(Patio_Light_Bulb.points(Semantics::Control, Semantics::Light, Semantics::Power))
          .to match_array([Patio_Light_Color,
                           Patio_Light_ControlPower])
      end

      specify do
        expect(Patio_Light_Bulb.points(Semantics::Control, Semantics::Measurement, Semantics::Power))
          .to match_array([Patio_Light_Power,
                           Patio_Light_ControlPower])
      end

      specify do
        # A bit odd, but valid. It's anything that's (control or measurement) and (light or power)
        expect(Patio_Light_Bulb.points(Semantics::Control,
                                       Semantics::Measurement,
                                       Semantics::Power,
                                       Semantics::Light))
          .to match_array([
                            Patio_Light_Color,
                            Patio_Light_Power,
                            Patio_Light_ControlPower
                          ])
      end

      specify do
        expect(Patio_Light_Bulb.points([Semantics::Measurement, Semantics::Power],
                                       [Semantics::Control, Semantics::Light]))
          .to match_array([Patio_Light_Power, Patio_Light_Color])
      end
    end

    it "includes the subclasses of the given point" do
      items.build do
        switch_item "Patio_Switch", group: gPatio, tag: Semantics::Switch # This is a subclass of Control
      end
      expect(gPatio.points(Semantics::Control)).to match_array [Patio_Point, Patio_Switch]
    end

    context "with subclasses: false" do
      it "excludes subclasses" do
        items.build do
          switch_item "Patio_Switch", group: gPatio, tag: Semantics::Switch # This is a subclass of Control
        end
        expect(Patio_Switch.semantic_type < Patio_Point.semantic_type).to be true
        expect(gPatio.points(Semantics::Control, subclasses: false)).to match_array [Patio_Point]
      end
    end

    it "does not return points in sublocations and equipments" do
      items.build do
        group_item "Outdoor_Light_Bulb", group: gOutdoor, tag: Semantics::Lightbulb do
          switch_item "Outdoor_Light_Switch", tags: [Semantics::Control, Semantics::Power]
        end
        switch_item "Outdoor_Point", tag: Semantics::Control, group: gOutdoor
      end

      expect(gOutdoor.points).to eql [Outdoor_Point]
    end

    context "with invalid arguments" do
      specify { expect { Patio_Light_Bulb.points(:not_a_class) }.to raise_error(ArgumentError) }
      specify { expect { Patio_Light_Bulb.points(Semantics::Level, Semantics::Indoor) }.to raise_error(ArgumentError) }
      specify { expect { Patio_Light_Bulb.points(Semantics::Lightbulb) }.to raise_error(ArgumentError) }
      specify { expect { Patio_Light_Bulb.points(Semantics::Indoor) }.to raise_error(ArgumentError) }
    end
  end

  describe Enumerable do
    describe "provides semantic methods" do
      specify { expect(gPatio.equipments).to match_array([Patio_Light_Bulb, Patio_Motion]) }
      specify { expect(gIndoor.locations).to eql [gLivingRoom] }
      specify { expect(gIndoor.locations(Semantics::Room)).to eql [gLivingRoom] }
      specify { expect(gIndoor.locations(Semantics::LivingRoom)).to eql [gLivingRoom] }
      specify { expect(gIndoor.locations(Semantics::FamilyRoom)).to eql [] }
      specify { expect { gIndoor.locations(Semantics::Light) }.to raise_error(ArgumentError) }
      specify { expect(items.tagged("CustomTag")).to match_array([LivingRoom_Light2_Bulb, Patio_Motion]) }

      specify do
        expect(gLivingRoom.members.tagged("Lightbulb")).to match_array([LivingRoom_Light1_Bulb, LivingRoom_Light2_Bulb])
      end

      specify { expect(gLivingRoom.members.not_tagged("Lightbulb")).to eql [LivingRoom_Motion] }
      specify { expect(gLivingRoom.members.member_of(gMyGroup)).to eql [LivingRoom_Light1_Bulb] }

      specify do
        expect(gLivingRoom.members.not_member_of(gMyGroup)).to match_array([LivingRoom_Light2_Bulb, LivingRoom_Motion])
      end

      specify do
        expect(LivingRoom_Motion.location.members.not_member_of(gMyGroup).tagged("CustomTag"))
          .to eql [LivingRoom_Light2_Bulb]
      end

      specify { expect(LivingRoom_Motion.location.equipments.tagged("CustomTag")).to eql [LivingRoom_Light2_Bulb] }
      specify { expect(gLivingRoom.equipments.members.member_of(gMyGroup)).to eql [LivingRoom_Light1_Custom] }
    end

    describe "#command" do
      it "works" do
        triggered = false
        received_command(LivingRoom_Light1_Brightness) { triggered = true }
        [LivingRoom_Light1_Brightness].on
        expect(triggered).to be true
        expect(LivingRoom_Light1_Brightness).to be_on
      end
    end

    describe "#update" do
      it "works" do
        triggered = false
        changed(LivingRoom_Light1_Brightness) { triggered = true }
        [LivingRoom_Light1_Brightness].update(ON)
        expect(triggered).to be true
        expect(LivingRoom_Light1_Brightness).to be_on
      end
    end

    describe "#toggle" do
      it "works for switches" do
        triggered = false
        received_command(LivingRoom_Light1_Custom) { triggered = true }
        [LivingRoom_Light1_Custom].toggle
        expect(triggered).to be true
        expect(LivingRoom_Light1_Custom).to be_on
      end

      it "accepts a source" do
        source = nil
        received_command(LivingRoom_Light1_Custom) { |event| source = event.source }
        [LivingRoom_Light1_Custom].toggle(source: "source")
        expect(source).to eq "source"
      end
    end

    describe "#points" do
      def points(*args)
        gPatio.members.equipments.members.points(*args)
      end

      specify do
        expect(points).to match_array([Patio_Light_Brightness,
                                       Patio_Light_Color,
                                       Patio_Light_Power,
                                       Patio_Light_ControlPower])
      end

      specify do
        expect(points(Semantics::Control)).to match_array([Patio_Light_Brightness,
                                                           Patio_Light_Color,
                                                           Patio_Light_ControlPower])
      end

      specify { expect(points(Semantics::Light)).to eql([Patio_Light_Color]) }
      specify { expect(points(Semantics::Light, Semantics::Control)).to eql([Patio_Light_Color]) }

      specify { expect { points(Semantics::Room) }.to raise_error(ArgumentError) }

      context "with GroupItem as a point" do
        before do
          items.build do
            group_item "My_Equipment", group: gIndoor, tag: Semantics::Lightbulb do
              group_item "GroupPoint", tag: Semantics::Switch
              dimmer_item "Brightness", tags: [Semantics::Control, Semantics::Level]
            end
          end
        end

        it "works" do
          expect(gIndoor.equipments.members.points).to match_array([Brightness, GroupPoint])
        end

        it "can find its siblings" do
          items.build do
            switch_item "MySwitch", group: My_Equipment, tags: [Semantics::Control, Semantics::Switch]
          end

          expect(GroupPoint.points).to match_array([Brightness, MySwitch])
          expect(Brightness.points).to match_array([GroupPoint, MySwitch])
        end
      end
    end

    describe "#locations" do
      it "supports multiple arguments" do
        items.build do
          group_item "gIndoor", tag: Semantics::Indoor do
            group_item "gLivingRoom", tag: Semantics::LivingRoom
            group_item "gKitchen", tag: Semantics::Kitchen
            group_item "gBedroom", tag: Semantics::Bedroom
          end
        end

        expect(gIndoor.locations(Semantics::LivingRoom, Semantics::Kitchen)).to match_array([gLivingRoom, gKitchen])
      end

      it "includes the subclasses of the given locations" do
        items.build do
          group_item "gRoom", group: gIndoor, tag: Semantics::Room
        end
        expect(gIndoor.locations(Semantics::Room)).to match_array [gRoom, gLivingRoom]
      end

      context "with subclasses: false" do
        it "excludes subclasses" do
          items.build do
            group_item "gRoom", group: gIndoor, tag: Semantics::Room
          end
          expect(Semantics::LivingRoom < Semantics::Room).to be true # Perform check in case the hierarchy changes
          expect(gIndoor.locations(Semantics::Room, subclasses: false)).to match_array [gRoom]
        end
      end
    end

    describe "#equipments" do
      it "gets sub-equipment" do
        items.build do
          group_item "SubEquipment", group: Patio_Light_Bulb, tag: Semantics::Lightbulb
        end
        expect(gPatio.equipments(Semantics::Lightbulb).members.equipments).to eql [SubEquipment]
      end

      it "supports multiple arguments" do
        items.build do
          group_item "gIndoor", tag: Semantics::Indoor do
            group_item "gTV", tag: Semantics::Television
            group_item "gSpeaker", tag: Semantics::Speaker
            group_item "gLightbulb", tag: Semantics::Lightbulb
          end
        end

        expect(gIndoor.equipments(Semantics::Television, Semantics::Speaker)).to match_array([gTV, gSpeaker])
      end

      it "includes the subclasses of the given equipments" do
        items.build do
          switch_item "Patio_Fan", group: gPatio, tag: Semantics::Fan
          switch_item "Patio_CeilingFan", group: gPatio, tag: Semantics::CeilingFan # This is a subclass of Fan
        end
        expect(gPatio.equipments(Semantics::Fan)).to match_array [Patio_Fan, Patio_CeilingFan]
      end

      context "with subclasses: false" do
        it "excludes subclasses" do
          items.build do
            switch_item "Patio_Fan", group: gPatio, tag: Semantics::Fan
            switch_item "Patio_CeilingFan", group: gPatio, tag: Semantics::CeilingFan # This is a subclass of Fan
          end
          expect(Semantics::CeilingFan < Semantics::Fan).to be true # Perform check in case the hierarchy changes
          expect(gPatio.equipments(Semantics::Fan, subclasses: false)).to match_array [Patio_Fan]
        end
      end
    end

    describe "#members" do
      it "doesn't include duplicate members from multiple groups" do
        expect([gMyGroup, gLivingRoom, NoSemantic].members).to match_array(
          [
            LivingRoom_Light1_Bulb,
            LivingRoom_Light2_Bulb,
            LivingRoom_Motion,
            LivingRoom_Light1_Custom
          ]
        )
      end
    end

    describe "#all_members" do
      it "includes all recursive members, uniquely" do
        expect([gMyGroup, gLivingRoom, NoSemantic].all_members).to match_array(
          [
            LivingRoom_Light1_Brightness,
            LivingRoom_Light1_Color,
            LivingRoom_Light1_Custom,
            LivingRoom_Light2_Brightness,
            LivingRoom_Light2_Color,
            LivingRoom_Motion
          ]
        )
      end
    end

    describe "#groups" do
      it "gets all groups" do
        expect([LivingRoom_Light1_Custom,
                LivingRoom_Light2_Color,
                LivingRoom_Light1_Bulb].groups).to match_array([
                                                                 gMyGroup,
                                                                 gLivingRoom,
                                                                 LivingRoom_Light1_Bulb,
                                                                 LivingRoom_Light2_Bulb
                                                               ])
      end
    end

    describe "#all_groups" do
      it "gets all groups recursively" do
        expect([LivingRoom_Light1_Custom,
                LivingRoom_Light2_Color,
                LivingRoom_Light1_Bulb].all_groups).to match_array([
                                                                     gMyGroup,
                                                                     LivingRoom_Light1_Bulb,
                                                                     gLivingRoom,
                                                                     gIndoor,
                                                                     LivingRoom_Light2_Bulb
                                                                   ])
      end
    end
  end

  describe "#equipments" do
    it "supports non-group equipments" do
      items.build do
        group_item "Group_Equipment", group: gIndoor, tag: Semantics::Lightbulb do
          dimmer_item "Brightness", tags: [Semantics::Control, Semantics::Level]
        end
        switch_item "NonGroup_Equipment", group: gIndoor, tag: Semantics::Lightbulb
      end
      expect(gIndoor.equipments).to match_array([Group_Equipment, NonGroup_Equipment])
    end
  end

  context "with custom semantics" do
    describe "#add" do
      it "works" do
        Semantics.add(SecretRoom: Semantics::Room)
        expect(Semantics::SecretRoom < Semantics::Room).to be true

        Semantics.add(SecretEquipment: Semantics::Equipment)
        expect(Semantics::SecretEquipment < Semantics::Equipment).to be true

        Semantics.add(SecretPoint: Semantics::Point)
        expect(Semantics::SecretPoint < Semantics::Point).to be true

        items.build do
          group_item TestLoc, tag: Semantics::SecretRoom do
            group_item TestEquip, tag: Semantics::SecretEquipment do
              number_item TestItem, tag: Semantics::SecretPoint
            end
          end
        end

        expect(TestItem.point?).to be true
        expect(TestEquip.equipment?).to be true
        expect(TestLoc.location?).to be true
        expect(TestItem.location).to be TestLoc
        expect(TestItem.equipment).to be TestEquip
        expect(TestEquip.location).to be TestLoc
      end

      it "supports tag name as string" do
        Semantics.add("StringTag" => Semantics::Equipment)
        expect(Semantics::StringTag < Semantics::Equipment).to be true
      end

      it "supports parent name as string" do
        Semantics.add(StringParent: "Equipment")
        expect(Semantics::StringParent < Semantics::Equipment).to be true
      end

      it "supports parent name as symbol" do
        Semantics.add(SymParent: :Equipment)
        expect(Semantics::SymParent < Semantics::Equipment).to be true
      end

      it "supports creating multiple tags" do
        to_create = %i[Room1 Room2 Room3]
        expect(Semantics.add(**to_create.to_h { |tag| [tag, Semantics::Room] }))
          .to match_array([Semantics::Room1, Semantics::Room2, Semantics::Room3])
        expect(Semantics.constants).to include(*to_create)
      end

      it "raises an error when trying to create a tag with an invalid parent" do
        expect { Semantics.add(InvalidParentTag: :Blah) }.to raise_error(ArgumentError)
        expect(Semantics.constants).not_to include(:InvalidParentTag)
      end

      it "returns the created tags as an array" do
        created = Semantics.add(ArrayTag1: :Equipment,
                                ArrayTag2: :Location,
                                ArrayTag3: :Point,
                                LivingRoom: Semantics::Room)
        expect(created).to match_array([Semantics::ArrayTag1, Semantics::ArrayTag2, Semantics::ArrayTag3])

        created = Semantics.add(ArrayTag1: :Equipment, ArrayTag2: :Location, ArrayTag3: :Point)
        expect(created).to be_empty
      end

      it "supports specifying label, synonyms, and description for the tag" do
        Semantics.add(Detailed: Semantics::Equipment,
                      label: "Label 1",
                      synonyms: "Synonym 2",
                      description: "Description 3")
        expect(Semantics::Detailed.label).to eq "Label 1"
        expect(Semantics.lookup("Synonym 2")).to eql Semantics::Detailed
        expect(Semantics::Detailed.description).to eq "Description 3"
      end

      it "supports synonyms in an array" do
        Semantics.add(ArraySynonyms: Semantics::Property, synonyms: ["Syn1", :Syn2])

        expect(Semantics.lookup("Syn1")).to be Semantics::ArraySynonyms
        expect(Semantics.lookup("Syn2")).to be Semantics::ArraySynonyms
      end

      it "warns when trying to create a tag that already exists" do
        Semantics.add(ExistingTag: Semantics::Equipment)
        expect(Semantics.logger).to receive(:warn).with(/already exists/)
        Semantics.add(ExistingTag: Semantics::Point)
      end
    end

    describe "#remove" do
      it "works" do
        to_be_removed = Semantics.add(RemoveTest: Semantics::Equipment)
        expect(Semantics::RemoveTest < Semantics::Equipment).to be true
        expect(Semantics.remove(Semantics::RemoveTest)).to eql to_be_removed
        expect { Semantics::RemoveTest }.to raise_error(NameError)
      end

      it "supports tag name as string" do
        Semantics.add(RemoveTest: Semantics::Equipment)
        Semantics.remove("RemoveTest")
        expect { Semantics::RemoveTest }.to raise_error(NameError)
      end

      it "supports tag name as symbol" do
        Semantics.add(RemoveTest: Semantics::Equipment)
        Semantics.remove(:RemoveTest)
        expect { Semantics::RemoveTest }.to raise_error(NameError)
      end

      it "supports removing multiple tags" do
        Semantics.add(RemoveTest1: Semantics::Equipment, RemoveTest2: Semantics::Equipment)
        Semantics.remove(Semantics::RemoveTest1, Semantics::RemoveTest2)
        expect { Semantics::RemoveTest1 }.to raise_error(NameError)
        expect { Semantics::RemoveTest2 }.to raise_error(NameError)
      end

      it "returns an empty array if the tag doesn't exist" do
        expect(Semantics.remove(:NotATag)).to be_empty
      end

      it "complains when trying to remove a tag that has children" do
        # Note we want to use a unique name here so it won't affect other tests
        Semantics.add(FailedTest: Semantics::Equipment)
        Semantics.add(FailedTestChild: Semantics::FailedTest)
        expect { Semantics.remove(:FailedTest) }.to raise_error(ArgumentError)
      end

      it "can remove the tag and its children recursively with recursive: true" do
        added = Semantics.add(RemoveTest: Semantics::Equipment)
        added += Semantics.add(RemoveTestChild1: Semantics::RemoveTest)
        added += Semantics.add(RemoveTestChild2: Semantics::RemoveTest)
        added += Semantics.add(RemoveTestGrandChild11: Semantics::RemoveTestChild1)
        added += Semantics.add(RemoveTestGrandChild21: Semantics::RemoveTestChild2)

        expect(Semantics.remove(Semantics::RemoveTestChild2,
                                Semantics::RemoveTest,
                                recursive: true)).to match_array(added)

        expect { Semantics::RemoveTest }.to raise_error(NameError)
        expect { Semantics::RemoveTestChild1 }.to raise_error(NameError)
        expect { Semantics::RemoveTestChild2 }.to raise_error(NameError)
        expect { Semantics::RemoveTestGrandChild11 }.to raise_error(NameError)
        expect { Semantics::RemoveTestGrandChild21 }.to raise_error(NameError)
      end

      it "complains when trying to remove a default tag" do
        expect { Semantics.remove(Semantics::Lightbulb) }.to raise_error(FrozenError)
      end
    end
  end

  describe "#lookup" do
    it "can lookup by name" do
      expect(Semantics.lookup("Kitchen")).to be Semantics::Kitchen
      expect(Semantics.lookup(:Kitchen)).to be Semantics::Kitchen
    end

    it "can lookup by label" do
      expect(Semantics.lookup("Living Room")).to be Semantics::LivingRoom
    end

    it "can lookup by synonym" do
      expect(Semantics.lookup("Living Rooms")).to be Semantics::LivingRoom
    end
  end

  describe "#tags" do
    it "works" do
      expect(Semantics.tags).to include(Semantics::LivingRoom)
      expect(Semantics.tags).to include(Semantics::Lightbulb)
      expect(Semantics.tags).to include(Semantics::Control)
      expect(Semantics.tags).to include(Semantics::Light)
    end

    it "includes newly added tags" do
      Semantics.add(TagsTest1: Semantics::Outdoor, TagsTest2: Semantics::Property)
      expect(Semantics.tags).to include(Semantics::TagsTest2, Semantics::TagsTest2)
    end
  end

  describe "Tag Info" do
    it "has a label attribute" do
      expect(Semantics::LivingRoom.label).to eq "Living Room"
    end

    describe "#to_s" do
      it "returns its tag name" do
        expect(Semantics::Equipment.to_s).to eql "Equipment"
        expect(Semantics::LivingRoom.to_s).to eql "LivingRoom"
      end
    end

    it "has a synonyms attribute" do
      expect(Semantics::LivingRoom.synonyms).to include("Living Rooms")
    end

    it "has a description attribute" do
      Semantics.add(TestDescAttr: Semantics::Room, description: "Test Description Attribute")
      expect(Semantics::TestDescAttr.description).to eq "Test Description Attribute"
    end
  end
end
