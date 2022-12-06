# @title Usage

# Usage


## UI Rules vs File-based Rules

The following features of this library are only usable within file-based rules:

* `Triggers`: UI-based rules provide equivalent triggers through the UI.
* `Guards`: UI-based rules use `Conditions` in the UI instead. Alternatively it can be implemented inside the rule code.
* `Execution Blocks`: The UI-based rules will execute your JRuby script as if it's inside a {OpenHAB::DSL::Rules::BuilderDSL#run run execution blocks}. 
A special {OpenHAB::Core::Events::AbstractEvent event} variable is available within your code to provide it with additional information regarding the event. 
For more details see the {OpenHAB::DSL::Rules::BuilderDSL#run run execution blocks}.
* `delay`: There is no direct equivalent in the UI. It can be achieved using {OpenHAB::DSL.after timers}.
* `otherwise`: There is no direct equivalent in the UI. However, it can be implemented within the rule using an `if-else` block.
