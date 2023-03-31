Feature:  semantics
  Custom semantic tag creation

  Background:
    Given Clean OpenHAB with latest Ruby Libraries

  Scenario: Semantic tag added
    Given a rule
      """
      locale = java.util.Locale.default

      Semantics.add(<tag>: Semantics::<parent>)
      member_of_tag = Semantics::<tag>.java_class < org.openhab.core.semantics.Tag.java_class
      found_in_aggregator = org.openhab.core.semantics.model.<type>.<aggregator>.stream.any_match { |l| l == Semantics::<tag>.java_class }
      found_by_id = org.openhab.core.semantics.SemanticTags.get_by_id("<tag>") == Semantics::<tag>.java_class
      found_by_label = org.openhab.core.semantics.SemanticTags.get_by_label("<default_label>", locale) == Semantics::<tag>.java_class
      logger.info "#{Semantics::<tag>.java_class}: #{member_of_tag} #{found_in_aggregator} #{found_by_id} #{found_by_label}"
      """
    When I deploy the rule
    Then It should log 'org.openhab.core.semantics.model.<type>.<tag>: true true true true' within 5 seconds
    Examples:
      | tag         | parent    | type      | aggregator | default_label |
      | SecretRoom2 | Room      | location  | Locations  | Secret Room 2 |
      | Equipment9  | Lightbulb | equipment | Equipments | Equipment 9   |
      | Pointier    | Control   | point     | Points     | Pointier      |
      | Property8   | Property  | property  | Properties | Property 8    |

  Scenario: Supports custom label
    Given a rule
      """
      Semantics.add(Room1: Semantics::Room, label: "My Custom Label")
      logger.info org.openhab.core.semantics.SemanticTags.get_label(Semantics::Room1, java.util.Locale.default)
      """
    When I deploy the rule
    Then It should log 'My Custom Label' within 5 seconds

  # There's a bug in openhab, it doesn't load the synonyms other than from the resource bundle
  # @wip
  # Scenario: Support synonyms
  #   Given a rule
  #     """
  #     Semantics.add(Room2: Semantics::Room, synonyms: "Alias1")
  #     logger.info org.openhab.core.semantics.SemanticTags.get_by_label_or_synonym("Alias1", java.util.Locale.default)
  #     """
  #   When I deploy the rule
  #   Then It should log 'org.openhab.core.semantics.model.location.Room2' within 5 seconds

  Scenario: Semantic tag usable by items
    Given a rule
      """
      Semantics.add(<tag>: Semantics::<parent>)
      items.build { <item_type>_item "<item_name>", tags: Semantics::<tag> }
      logger.info "<item_name> is a <semantic_type>? #{<item_name>.<semantic_type>?}"
      """
    When I deploy the rule
    Then It should log '<item_name> is a <semantic_type>? <result>' within 5 seconds
    Examples:
      | tag             | parent    | semantic_type | item_type | item_name  | result |
      | Color           | Light     | point         | color     | LightColor | true   |
      | TorpedoLauncher | Equipment | equipment     | contact   | Launcher1  | true   |
