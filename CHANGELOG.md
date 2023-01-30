# JRuby openHAB Scripting Change Log

## [5.0.0](https://github.com/ccutrer/openhab-jrubyscripting/compare/4.45.2...main)

5.0 is the first release of `openhab-jrubyscripting` as a fork of
`openhab-scripting`. Many thanks to
[@boc-tothefuture](https://github.com/boc-tothefuture),
[@jimtng](https://github.com/jimtng), and [@pacive](https://github.com/pacive)
for their work on the latter. The purpose of this fork is because I
([@ccutrer](https://github.com/ccutrer)) felt that I wanted to significantly
re-work some of the core structure of the gem to shed some of the technical
debt that had accumulated from organic growth, and to do so speedily without
waiting for full review from other contributors with limited time. That said,
here is a non-exhaustive list of significant departures from the original gem:

* Logging has been reworked. There's generally no need to
  `include OpenHAB::Log` in your classes. {OpenHAB::Log.logger} method now
  accepts a String to explicitly find whichever logger you would like, and
  {OpenHAB::Logger#level=} can be used to dynamically change the log level.
  Issues around the logger name while a rule is executing have also been
  resolved: the top-level `logger` will be named after the file, and the
  `logger` within a `rule` or execution block will be named after the rule.
  Loggers within class or instance-of-a-class context will be named after
  the class. These loggers will _not_ have their name changed simply because
  their methods happened to be called while a rule is executing. Logging
  also defaults to `#to_s` now, instead of `#inspect`.
* The documentation philosophy has changed. Instead of relying on a large
  set of markdown files to give both commentary and to document the details
  of objects, [YARD](https://yardoc.org/) is now the primary generator
  of the documentation site. Details of individual objects and methods are
  now documented inline with the code, reducing duplication, aiding in
  keeping them up-to-date and accurate, and being more rigorous in ensuring
  the documentation has every available method listed, and in a consistent
  manner. Some commentary and high level examples (such as this file) are
  still maintained as dedicated markdown files, but included in the YARD
  docs, instead of being a separate site that then links to the YARD docs.
* The testing philosophy has also changed. The
  [rspec-openhab-scripting gem](https://rubygems.org/gems/rspec-openhab-scripting),
  previously written as an independent project by me
  ([@ccutrer](https://github.com/ccutrer)), has now been merged into this gem.
  There is a tight interdependence between the two, and especially during the
  large refactoring it's much easier to have them in the same repository. This
  means that that gem is now the endorsed method to write tests for end-user
  rules, as well as the preferred way to write tests for this gem itself, when
  possible.
* Major re-organization of class structures. {OpenHAB::Core} now contains any
  classes that are mostly wrappers or extensions of org.openhab.core Java
  classes, while {OpenHAB::DSL} contains novel Ruby-only classes that implement
  a Ruby-first manner of creating rules, items, and things.
* As part of the re-organization from above, the definition of a "DSL method"
  that is publicly exposed and available for use has been greatly refined.
  Top-level DSL methods are only available on `main` (the top-level {Object}
  instance when you're writing code in a rules file and not in any other
  classes), and inside of other select additional DSL constructs. If you've
  written your own classes that need access to DSL methods, you either need
  to explicitly call them on {OpenHAB::DSL}, or mix that module into your
  class yourself. Additional internal and Java constants and methods should
  no longer be leaking out of the gem's public API.

### Breaking Changes

* Dropping support for openHAB < 3.4.
* The main require is now `require "openhab/dsl"` instead of just
  `require "openhab"`. The reason being to avoid conflicts if a gem gets
  written to access openHAB via REST API. It's probably preferred that you
  [configure automatic requires](USAGE.md#configuration) for this file anyway.
* {GenericItem} and descendants can no longer be treated as the item's state.
  While convenient at times, it introduces many ambiguities on if the intention
  is to interact with the item or its state, and contortionist code attempting
  to support both use cases.
* {OpenHAB::Core::Types::Type Enum types} no longer have implicit conversions for comparisons.
  This means you can no longer do `DimmerItem.state == ON`.
  Predicate methods retain the implicit conversion semantics, so you _can_ do `DimmerItem.on?`.
  `ensure.on`, etc. also still retain their internal implicit comparisons, so you can also still do `DimmerItem.ensure.on` and it will _not_ send {ON} if the item is anything but `0`.
  {OpenHAB::Core::Events::ItemStateEvent} and {OpenHAB::Core::Events::ItemStateChangedEvent} both now have a full set of predicate methods to ease use from within rule execution blocks.
* Semi-related to the above two points, the `#truthy?` method has been removed from any items the previously implemented it.
  Instead, be more explicit on what you mean - for example `Item.on?`.
  If you would like to use a similar structure with {StringItem StringItems}, just [include the ActiveSupport gem](USAGE.md#gems) in your rules to get `#blank?` and `#present?` methods, and then you can use `Item.state.present?`.
* Semi-related to the above, the
  {OpenHAB::DSL::Rules::BuilderDSL#only_if only_if} and
  {OpenHAB::DSL::Rules::BuilderDSL#not_if not_if} guards now _only_ take blocks.
  This just means where you previously had `only_if Item` you now write
  `only_if { Item.on? }`.
* Related to the above, {OpenHAB::DSL::Rules::BuilderDSL#changed changed for:}
  guards no longer take items. This just means if you previously had
  `changed Item, for: OtherItem` you now write
  `changed Item, for: -> { OtherItem.state }`.
* {QuantityType} is no longer implicitly
  convertible and comparable against Strings. Use the `|` operator for easy
  construction of {QuantityType}s: `10 | "°F"`.
* {HSBType} is no longer convertible and comparable against Strings, Hashes,
  and Arrays. Just construct an HSBType. Sending a HTML hex color as a string
  as a command is still supported.
* {PointType} is no longer convertible and comparable against Strings and
  Hashes. Just construct a PointType. Send strings as a command is still supported.
* {QuantityType} can no longer be compared against `Numeric` or {DecimalType} outside
  a {OpenHAB::DSL.unit unit} block. Either compare it against another QuantityType, or
  convert it with to_f first, perform the comparison inside a
  {OpenHAB::DSL.unit unit} block, or {OpenHAB::DSL.unit! permanently set} your
  preferred units.
* The top-level `groups` method providing access to only {GroupItem}s has been
  removed. Use `items.grep(GroupItem)` if you would like to filter to only
  groups.
* `GenericItem#id` no longer exists; just use
  {Item#to_s Item#to_s} which does what `#id` used to do.
* `states?(*items)` helper is gone. Just use `items.all?(:state?)`, or in
  the rare cased you used `states?(*items, things: true)`, use
  `items.all? { |i| i.state? && i.things.all?(&:online?) }`.
* {GroupItem} is no longer {Enumerable}, and you must use
  {GroupItem#members GroupItem#members}.
* {GroupItem#all_members GroupItem#all_members} no
  longer has a `filter` parameter; use `grep` if you want just {GroupItem}s.
* `create_timer` no longer exists as an alias for {after}.
* `Item#meta` is no longer a supported alias for
  {Item#metadata Item#metadata}.
* Triggers (such as {OpenHAB::DSL::Rules::BuilderDSL#changed changed},
  {OpenHAB::DSL::Rules::BuilderDSL#updated updated}, and
  {OpenHAB::DSL::Rules::BuilderDSL#received_command received_command} that
  previously took a splat _or_ an Array of Items now _only_ take a splat.
  This just means instead of `changed [Item1, Item2]` you write
  `changed Item1, Item2`, or if you have an actual array you write
  `changed(*item_array)`. This greatly simplifies the internal code that has to
  distinguish between {GroupItem::Members GroupItem::Members} and other
  types of collections of items.
* Date and time objects have been reworked:
  * `TimeOfDay` has been replaced with {LocalTime}
  * Date/time objects are no longer comparable to strings.
    Please use the correct type.
  * Comparisons among the varying date/time classes all work.
  * See also [Working With Time](USAGE.md#time)
  * Persistence methods no longer accept a {Duration}. Please use `Duration#ago`
    instead.
* Thing actions are no longer available as a top level method. You must use the
  {OpenHAB::Core::Things::Thing#actions Thing} object.
* Thing actions whose scope does _not_ match the thing's binding are no longer
  directly available on {OpenHAB::Core::Things::Thing Thing}; you must
  explicitly access them via
  {OpenHAB::Core::Things::Thing#actions Thing#actions}.
* {OpenHAB::Core::Items::Persistence Persistence} predicates are no longer
  aliased without the `?` (i.e. you must call `#changed_since?`, not
  `#changed_since`).
* Timers with IDs are no longer uniqueified by where they were created. Make
  sure you're using a completely unique timer ID if you're using them in
  multiple locations. For example,
  `after(1.minute, id: [:this_logical_usage, event.item])`. This makes it
  possible to schedule the same logically re-entrant timer from multiple rules.
* `OpenHAB.conf_root` was renamed to {OpenHAB::Core.config_folder}.
* {OpenHAB::Core::Items::GenericItem#metadata Metadata} now defaults to using transient backing provider.
  This means that if you add metadata to an item from Ruby, it will disappear when the script is unloaded.
  See {OpenHAB::DSL.provider} for how to revert to the old behavior within a single block, or for your entire script.
* {OpenHAB::Core::Items::GenericItem#metadata Metadata} will now be serialized before being set.
  This fixes a complicated issue where types would changed unexpectedly, or even worse, reference Ruby classes that are not even available in the current JRuby instance.
  See https://github.com/openhab/openhab-core/issues/3169 for more details.
* `#on_start` trigger was renamed to {OpenHAB::DSL::Rules::BuilderDSL#on_load #on_load} and its 'run_on_start' parameter removed. 
  {OpenHAB::DSL::Rules::BuilderDSL#on_start #on_start} is now a trigger for `core.SystemStartlevelTrigger`.
* `say`, `play_sound`, and `play_stream` are no longer available at the top level.
  You must access them from their Action class: {OpenHAB::Core::Actions::Voice.say Voice.say}, 
  {OpenHAB::Core::Actions::Audio.play_sound Audio.play_sound}, and {OpenHAB::Core::Actions::Audio.play_stream Audio.play_stream}

### Features

* {OpenHAB::DSL::Items::Builder}
* {OpenHAB::DSL::Things::Builder}
* {group::OpenHAB::DSL::Rules::BuilderDSL::Triggers Several new triggers}
* {OpenHAB::DSL.profile}
* {OpenHAB::DSL.script}
* {OpenHAB::DSL.shared_cache}
* {OpenHAB::Core::Rules::Registry}, specifically {OpenHAB::Core::Rules::Registry#remove #remove} and {OpenHAB::Core::Rules::Rule#trigger #trigger} are new functionality.
* {OpenHAB::DSL.unit} can now handle units for multiple dimensions.
* Support Ruby's method name convention for thing actions, e.g. `things["mqtt:broker:mosquitto"].publish_mqtt`
* {OpenHAB::DSL.timers timers} now returns {OpenHAB::DSL::TimerManager an object}
  that can be used to thread-safely schedule/reschedule/cancel timers by ID.
* `#inspect` on several classes has been improved to be useful, instead of just returning the class name.
* {OpenHAB::DSL.after after} (and anything else that ultimately relies on timers) support `Proc` for durations.
* Add `#ago` and `#from_now` methods to {Duration}.
* The ability to designate how metadata should be persisted or not, via {OpenHAB::DSL.provider}.
* {java.util.Map} and {java.util.List} now more fully implement the expected interfaces of `Hash` and `Array`, so you don't need to explicitly convert (as much) anymore.
* If you reference an item that does not currently exist in a rule trigger, instead of raising `MethodMissing` or `NameError`, the trigger will be created anyway.
  openHAB will log a warning that the item is missing, and the trigger will not work. When the item is eventually created, the trigger will begin to work.
  This matches the behavior of DSL rules.
  Note that this only works for {OpenHAB::DSL::Rules::Terse terse rules} if they're created within a {OpenHAB::DSL::Rules::Builder rules.build} block.
* {OpenHAB::DSL::Rules::BuilderDSL#on_start #on_start} supports creating a `core.SystemStartlevelTrigger`.
  Also see {OpenHAB::DSL::Rules::BuilderDSL#on_load #on_load}.
* {OpenHAB::DSL::Rules::BuilderDSL#on_load #on_load} supports delay
* Various Ephemeris methods on {ZonedDateTime}.
* {OpenHAB::DSL::Rules::BuilderDSL#dependencies} Rule dependencies
* A set of debounce/throttle guards for file-based rules: {OpenHAB::DSL::Rules::BuilderDSL#debounce_for debounce_for}, {OpenHAB::DSL::Rules::BuilderDSL#throttle_for throttle_for}, and {OpenHAB::DSL::Rules::BuilderDSL#only_every only_every} 
* And for UI rules: {OpenHAB::DSL.debounce_for debounce_for}, {OpenHAB::DSL.throttle_for throttle_for}, {OpenHAB::DSL.only_every only_every}
* Explicitly document modifying item tags, labels and categories (where possible), and notify openHAB of the change
* {OpenHAB::Core::Events::ItemStateEvent} and {OpenHAB::Core::Events::ItemStateChangedEvent} now have full sets of predicate methods.

### Bug Fixes

* Fix thing {OpenHAB::Core::EntityLookup#method_missing entity lookup}
* Fix {OpenHAB::DSL::Items::Ensure ensure} to work with {QuantityType}
* Fix scoping of {OpenHAB::DSL::Rules::Terse terse rule} blocks
* {OpenHAB::DSL.persistence persistence block} now restores the previous setting
* {OpenHAB::DSL.unit unit} block applies to sending commands to {NumberItem NumberItems}.
* *All* thread locals are carried over to rule executions and timers. This includes {OpenHAB::DSL.unit unit}, {OpenHAB::DSL.persistence persistence}, and {OpenHAB::DSL.ensure_states ensure_states}.
* Fix thread safety issue that could cause timers to not be canceled when the script unloads.
* {OpenHAB::DSL::Items::TimedCommand#command Timed command} thread safety issues resolved
* {OpenHAB::DSL::Items::TimedCommand#command Timed command} now resets the on_expire setting when called again
* {OpenHAB::DSL::Items::TimedCommand#command Timed command} still sends the command even the previous timed command is still pending
* {OpenHAB::DSL::Items::TimedCommand#command Timed command} works with resetting to {NULL}/{UNDEF}
* {OpenHAB::DSL::Items::TimedCommand#command Timed command} works on items with autoupdate=false
* {OpenHAB::Core::Items::Metadata} hashes are indifferent (converts symbol keys to string keys).
* Fix {OpenHAB::DSL::Items::Ensure ensure} to work with conversions-from-string that are handled by openhab-core.
* Avoid stack overflow issues when all of ActiveSupport is required.
* Don't swallow exceptions inside of `rule` blocks - just let them propagate up.
* Fix changed duration when only the `from` state is given
* Updating an item with `nil` sets it to `NULL`, not an empty string (which will be ignored by other item types).

## [4.45.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.45.1...4.45.2) (2022-10-02)


### Bug Fixes

* **items:** ensure enumerable methods from `items` use ItemProxy ([a149f96](https://github.com/boc-tothefuture/openhab-jruby/commit/a149f96abd1e1d43c165c1a85591b5e39b4d43b0))
* **logging:** use the class name for class loggers ([e87e03b](https://github.com/boc-tothefuture/openhab-jruby/commit/e87e03b715836f7d89fef1cdc37c339b4139d593))

## [4.45.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.45.0...4.45.1) (2022-09-21)


### Bug Fixes

* **math:** configure rounding params when doing BigDecimal division ([e1cee18](https://github.com/boc-tothefuture/openhab-jruby/commit/e1cee18ea264901f07024ff0b26c8cb2b88ba85f)), closes [#640](https://github.com/boc-tothefuture/openhab-jruby/issues/640)


### Continuous Integration

* update openhab source url to github ([792015e](https://github.com/boc-tothefuture/openhab-jruby/commit/792015e88e3715d0608c43c44a8995edfb7d8192))

## [4.45.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.44.2...4.45.0) (2022-09-18)


### Features

* **time:** support arithmetic and comparison operators ([e3466db](https://github.com/boc-tothefuture/openhab-jruby/commit/e3466dbf67f49ce4cecae127968848f8c7708879))
* **time_of_day:** support a range of LocalTime for TimeOfDay#between? ([fd12e3d](https://github.com/boc-tothefuture/openhab-jruby/commit/fd12e3db18b0cb75a7a8824baa45909284896499))


### Documentation

* clean up ordering in Misc section ([a6a0beb](https://github.com/boc-tothefuture/openhab-jruby/commit/a6a0bebd1708cee94908e4cbfb804ff5f235bd3d))

## [4.44.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.44.1...4.44.2) (2022-09-06)


### Bug Fixes

* **cron:** fix clean up of cron handler ([4190255](https://github.com/boc-tothefuture/openhab-jruby/commit/41902553270a7cc9871b132586936d2d66f4bdc7))
* **items:** ensure items coming from group members are wrapped in ItemProxy ([19bd416](https://github.com/boc-tothefuture/openhab-jruby/commit/19bd4165342152f58380cbaa4dd794f9fcd5a627))

## [4.44.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.44.0...4.44.1) (2022-08-20)


### Bug Fixes

* **ruby:** fix error with jruby 9.3.7 ([82dced4](https://github.com/boc-tothefuture/openhab-jruby/commit/82dced4e2bfea835bb655094e7cd9f42a967a143))

## [4.44.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.43.3...4.44.0) (2022-07-31)


### Features

* **rule:** add tags to rules ([d5c29de](https://github.com/boc-tothefuture/openhab-jruby/commit/d5c29deabb793d23880463f86285bf6764dfb5c7))
* **rules:** improve rule name inference ([a0b30ec](https://github.com/boc-tothefuture/openhab-jruby/commit/a0b30ec3c3c254cb0e94aec33a048b8723021e60))


### Code Refactoring

* standardize on java format for java class references ([ae519bf](https://github.com/boc-tothefuture/openhab-jruby/commit/ae519bf1b5033a2d7588dd5e338e2e7eabbcb039))


### Build System

* change the default openhab version to 3.3.0 ([1fb42d0](https://github.com/boc-tothefuture/openhab-jruby/commit/1fb42d08566d75725654c864ac21bf597b9c8003))

## [4.43.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.43.2...4.43.3) (2022-07-25)


### Bug Fixes

* **actions:** don't use a singleton method for monkeypatching ScriptThingActions ([e330a0f](https://github.com/boc-tothefuture/openhab-jruby/commit/e330a0fe0ebee31d7790b6941afabde0dcf891b1)), closes [#596](https://github.com/boc-tothefuture/openhab-jruby/issues/596)

## [4.43.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.43.1...4.43.2) (2022-07-25)


### Bug Fixes

* **rules:** fix reloading of rules ([06cb928](https://github.com/boc-tothefuture/openhab-jruby/commit/06cb9288b9a2f618bfc37b76dc5e60ba39de3e15)), closes [#620](https://github.com/boc-tothefuture/openhab-jruby/issues/620)


### Build System

* **rubocop:** explicitly allow openhab globals ([2baf772](https://github.com/boc-tothefuture/openhab-jruby/commit/2baf77268656d5c0e3ed22001da5e9374ec49790))

## [4.43.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.43.0...4.43.1) (2022-07-18)


### Bug Fixes

* **ensure:** with QuantityType and plain number ([83036b8](https://github.com/boc-tothefuture/openhab-jruby/commit/83036b84aee376b8e6565d11a9e563d7024ad924))
* **terse:** improve automatic naming of terse rules ([9683845](https://github.com/boc-tothefuture/openhab-jruby/commit/9683845aea9bec223bcf8c592e16d2344ac1b7c2))
* **ui:** attach rule source to rule ([940780f](https://github.com/boc-tothefuture/openhab-jruby/commit/940780fd903891fe3c0e6e28be310c2345cf031b))
* **ui:** improve rule UIDs ([f41f5c5](https://github.com/boc-tothefuture/openhab-jruby/commit/f41f5c5159567b6deedd271325439c8767e66917))

## [4.43.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.42.2...4.43.0) (2022-07-11)


### Features

* add play_stream action method ([f3ab3ae](https://github.com/boc-tothefuture/openhab-jruby/commit/f3ab3ae4dca88db880e6b488ad765267253bc4d5))
* make the code base compatible with JRuby 9.4 (Ruby 3.x) ([77cae44](https://github.com/boc-tothefuture/openhab-jruby/commit/77cae44a4f115b5c9ca7c3f44099109ebd587c4e))


### Bug Fixes

* **ruby:** fix another minor ruby warnings ([77899c9](https://github.com/boc-tothefuture/openhab-jruby/commit/77899c9267cf6db299b04d9d60b6322bbd6f1a86))


### Documentation

* **generic_trigger:** config kwargs is not a hash in Ruby 3.x ([528994a](https://github.com/boc-tothefuture/openhab-jruby/commit/528994a3dfdb2a98399f88023e658451b3d3fafe))


### Tests

* **persistence:** change top-level class variable to instance var ([95babba](https://github.com/boc-tothefuture/openhab-jruby/commit/95babba1a9d8f534fe2a345a0a4a3bf6e837f047))


### Continuous Integration

* update test matrix to openhab 3.3 ([c9e8f1c](https://github.com/boc-tothefuture/openhab-jruby/commit/c9e8f1c84c1cb865bc097526cd1ff9d5cbb010f7))
* **atomic_rule_write:** create temp file in userdata/tmp ([1cfec6b](https://github.com/boc-tothefuture/openhab-jruby/commit/1cfec6bc93df1fb0214715f9f23132330c9a3e4d))

## [4.42.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.42.1...4.42.2) (2022-06-29)


### Bug Fixes

* **items:** fix ComparableItem#nil_comparison ([0908ef6](https://github.com/boc-tothefuture/openhab-jruby/commit/0908ef636c2424e8957603515c99d1235bc6428e))
* **ruby:** fix some minor ruby warnings ([040e836](https://github.com/boc-tothefuture/openhab-jruby/commit/040e8367c7ff031b0492b7d8956aa65bd8a93020))

## [4.42.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.42.0...4.42.1) (2022-06-20)


### Bug Fixes

* **persistence:** between called the wrong method ([f6b4b7a](https://github.com/boc-tothefuture/openhab-jruby/commit/f6b4b7a725d62e3ae382de3e86f279fcaff6917e))


### Build System

* upgrade test to 3.3.0.M7 ([128e132](https://github.com/boc-tothefuture/openhab-jruby/commit/128e13215e71e0dee2b80eb6b44a3f68e16c06f6))

## [4.42.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.41.0...4.42.0) (2022-06-18)


### Features

* add support for persistence 'between' methods ([fc46fc4](https://github.com/boc-tothefuture/openhab-jruby/commit/fc46fc41e58788ff26f4c4d8b7ee62e45a6ab2f9))


### Documentation

* add an example for DateTimeTrigger ([279b81a](https://github.com/boc-tothefuture/openhab-jruby/commit/279b81aab1ac16b1f64d37eb3947e7c909292677))


### Build System

* add --no-heap-dump to dev:dump-create ([228710c](https://github.com/boc-tothefuture/openhab-jruby/commit/228710cf20ea00c3ab03c5cbe07247f3d72128b3))
* close file handle in truncate_log ([359ae07](https://github.com/boc-tothefuture/openhab-jruby/commit/359ae0768773b1733227f39eee098c4bdc29ca91))
* include more commit types in the changelog ([2002afb](https://github.com/boc-tothefuture/openhab-jruby/commit/2002afb0012b0f178d121d3f92768029842f94ce))
* update build to use openhab 3.3.0M5 ([46b9f32](https://github.com/boc-tothefuture/openhab-jruby/commit/46b9f329dbd6b58bcad17cd703a6dd927498ace0))
* use a simpler setup-ruby action ([8187e77](https://github.com/boc-tothefuture/openhab-jruby/commit/8187e77ead0e476876cb52e9e018cd22dd44d5df))
* use index in log dump file in github action ([01e683a](https://github.com/boc-tothefuture/openhab-jruby/commit/01e683a548679cd4d1e7bbb1ee8e2361bde83f58))
* **ci:** optimize CI builds by splitting features across number of runners ([ed85b4d](https://github.com/boc-tothefuture/openhab-jruby/commit/ed85b4db59a543e3abee2dc6883f1932790e4deb))


### Tests

* **ensure_states:** change logging from trace to info ([7686d32](https://github.com/boc-tothefuture/openhab-jruby/commit/7686d32ef13f14eb5528cea9b9e7b349d3779c9b))
* **rule_language:** [@log_level_changed was missing ([fe61b04](https://github.com/boc-tothefuture/openhab-jruby/commit/fe61b040019142ba9525685f742b13d0eb54e233))

# [4.41.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.40.0...4.41.0) (2022-04-28)


### Bug Fixes

* comparing non null vs null comparable-item objects raised an exception ([2844d7a](https://github.com/boc-tothefuture/openhab-jruby/commit/2844d7abbea381309205152c3826ea258dcc937f))


### Features

* **logging:** change logger level predicate method names ([a7305d3](https://github.com/boc-tothefuture/openhab-jruby/commit/a7305d3543fb4aabe19fe963d960b1db71a28ab6))
* **semantics:** rename sublocations to locations ([f2dfd29](https://github.com/boc-tothefuture/openhab-jruby/commit/f2dfd2922e246c820635fb02bbe15bcf5fa3bf64))

# [4.40.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.39.1...4.40.0) (2022-04-24)


### Features

* **grep:** support grepping items from enumerable ([ef29edd](https://github.com/boc-tothefuture/openhab-jruby/commit/ef29edd2c4c1122045ad14c644dd7a0c341c6c70))
* **item_equality:** add the ability to compare item objects ([0f4608b](https://github.com/boc-tothefuture/openhab-jruby/commit/0f4608b80c3b7307cdcde6f04841e43a27373b40))

## [4.39.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.39.0...4.39.1) (2022-04-24)


### Bug Fixes

* **semantics:** groupitem.points failed to return its siblings ([afbec5e](https://github.com/boc-tothefuture/openhab-jruby/commit/afbec5e7a15008d90a31aa491858213f2b82466c))
* **semantics:** revert the members search for enumerable#points ([4e62458](https://github.com/boc-tothefuture/openhab-jruby/commit/4e62458a983071a62380fe7b22e9d464d45a5b9b))

# [4.39.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.38.0...4.39.0) (2022-04-20)


### Bug Fixes

* **ensure:** ensure didn't work on Enumerable ([5cfe07b](https://github.com/boc-tothefuture/openhab-jruby/commit/5cfe07bae4ad71c6e1699e03d2d091ad05a0a6cc))


### Features

* **enumerable:** add Enumerable#members ([e093bed](https://github.com/boc-tothefuture/openhab-jruby/commit/e093bed1c6641090d7f4304ae4138da50e915c2a))
* **semantics:** incorporate flat_map into Enumerable#points ([a74194b](https://github.com/boc-tothefuture/openhab-jruby/commit/a74194bb301b83898b0fea2fd0e4cdec651512ca))

# [4.38.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.37.1...4.38.0) (2022-04-15)


### Features

* **semantics:** add semantic helper methods to items ([a16f976](https://github.com/boc-tothefuture/openhab-jruby/commit/a16f9768b57763145e8b90a0877108d09c57dfe8)), closes [#370](https://github.com/boc-tothefuture/openhab-jruby/issues/370)

## [4.37.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.37.0...4.37.1) (2022-04-09)


### Bug Fixes

* **numeric_item:** make NumericItem#| raise NoMethodError when state is nil ([ac289fc](https://github.com/boc-tothefuture/openhab-jruby/commit/ac289fc2c7a9d1dba7f4c5b908d1f0fd2eb49875))

# [4.37.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.36.0...4.37.0) (2022-04-08)


### Bug Fixes

* **zoneddatetime:** make ZonedDateTime available on OpenHAB 3.2 ([c22be74](https://github.com/boc-tothefuture/openhab-jruby/commit/c22be74104ef5254223838adcc3adaa70e2edefa))


### Features

* **conf:** rename __conf__ to OpenHAB.conf_root ([ea0a657](https://github.com/boc-tothefuture/openhab-jruby/commit/ea0a65736821bbd64fe3ed199229953b55f6a1ab))
* **timers[]:** add #reschedule, rename #cancel_all to #cancel ([38da4a0](https://github.com/boc-tothefuture/openhab-jruby/commit/38da4a01607830fb44cb17c6b52f46000de2ddc0))

# [4.36.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.35.0...4.36.0) (2022-04-03)


### Features

* add support for timer and persistence to accept zoneddatetime and rubytime ([640cf0e](https://github.com/boc-tothefuture/openhab-jruby/commit/640cf0ec24ee7b34faec819ae194c9a2ffd4c344))

# [4.35.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.34.1...4.35.0) (2022-03-29)


### Features

* **state:** add state? helper method ([e8bb65e](https://github.com/boc-tothefuture/openhab-jruby/commit/e8bb65e17f654cc5ad9d58deb11eda7a304f9859))

## [4.34.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.34.0...4.34.1) (2022-03-16)

# [4.34.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.33.1...4.34.0) (2022-03-15)


### Features

* **cron:** support fields for cron and monthday object for every ([0e53986](https://github.com/boc-tothefuture/openhab-jruby/commit/0e53986e76353d910d5c73a54393d500c87e7ffa))

## [4.33.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.33.0...4.33.1) (2022-03-10)

# [4.33.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.7...4.33.0) (2022-03-09)


### Bug Fixes

* **build:** specify the local theme for jekyll ([d9a3be3](https://github.com/boc-tothefuture/openhab-jruby/commit/d9a3be3326b7c84123420a7761295a1c97f32bbc))
* **ensure:** implement ensure.update ([c519b8b](https://github.com/boc-tothefuture/openhab-jruby/commit/c519b8b654d87cd93cf5b02cb16feee055b2ddb8))
* **timer:** remove timer class from top-level ([4c22e5a](https://github.com/boc-tothefuture/openhab-jruby/commit/4c22e5a00a08e1f5bff55d05f6d7297e11448eac))


### Features

* **timer:** add create_timer as an alias for after ([3753304](https://github.com/boc-tothefuture/openhab-jruby/commit/3753304f1a4c720670dc9c495503b422b9142ad0))

## [4.32.7](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.6...4.32.7) (2022-03-07)


### Bug Fixes

* **dsl:** dsl methods leaked into other objects ([3d17030](https://github.com/boc-tothefuture/openhab-jruby/commit/3d17030848d0b2d18d945dd08b03a672f1e74513))

## [4.32.6](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.5...4.32.6) (2022-03-04)


### Bug Fixes

* **timed_command:** timed command cancelled by its own command ([075e627](https://github.com/boc-tothefuture/openhab-jruby/commit/075e6276f761616601b893539819b68e8aa403a0))

## [4.32.5](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.4...4.32.5) (2022-02-28)


### Bug Fixes

* **logger:** exclude <script> in log prefix ([ddb7104](https://github.com/boc-tothefuture/openhab-jruby/commit/ddb71040cab0c6a25b28881d103c91bae7812bae))
* **rule:** rule method returns the created rule ([afe7f69](https://github.com/boc-tothefuture/openhab-jruby/commit/afe7f69f5f36e1a82a62add82181009370508643))

## [4.32.4](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.3...4.32.4) (2022-02-27)

## [4.32.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.2...4.32.3) (2022-02-24)


### Bug Fixes

* **script_thing_actions:** adapt to changes in openhab 3.3 ([41cbb55](https://github.com/boc-tothefuture/openhab-jruby/commit/41cbb5533a8e9a15f134ceab91ae527ba767e02d))

## [4.32.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.1...4.32.2) (2022-02-22)


### Bug Fixes

* **logger:** move logger class into core module to prevent unintentional modification ([1ab681f](https://github.com/boc-tothefuture/openhab-jruby/commit/1ab681f9947dfe290a14ed4721ac30b1cfc16ac3))

## [4.32.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.32.0...4.32.1) (2022-02-21)


### Bug Fixes

* **color_item:** move to_h and to_a from color_item into hsb_type ([b00bbe7](https://github.com/boc-tothefuture/openhab-jruby/commit/b00bbe7bbe4a4d847177d538f018cf71c98120b6))
* **hsbtype:** comparison against another hsbtype only checks for brightness ([2cebe9e](https://github.com/boc-tothefuture/openhab-jruby/commit/2cebe9e2f2bd498ab33714210aeb6a70caff8787))

# [4.32.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.31.0...4.32.0) (2022-01-23)


### Features

* **command:** received_command supports ranges and procs ([ab3d974](https://github.com/boc-tothefuture/openhab-jruby/commit/ab3d974c4ebbdcb7ffd73190f5d865c38a5ab2f8))

# [4.31.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.30.5...4.31.0) (2022-01-22)


### Features

* **triggers:** support quantity string range in trigger conditions ([531ed23](https://github.com/boc-tothefuture/openhab-jruby/commit/531ed232f16eb13bc1ff80fefefa55ed15b5483e))

## [4.30.5](https://github.com/boc-tothefuture/openhab-jruby/compare/4.30.4...4.30.5) (2022-01-21)


### Bug Fixes

* **string_type:** direct regex comparison and inspect ([1703aa2](https://github.com/boc-tothefuture/openhab-jruby/commit/1703aa2600fb1fec846b8b408df23b349073146d))

## [4.30.4](https://github.com/boc-tothefuture/openhab-jruby/compare/4.30.3...4.30.4) (2022-01-21)

## [4.30.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.30.2...4.30.3) (2022-01-20)


### Bug Fixes

* **persistence:** npe on dimensioned item without an explicit unit ([251f625](https://github.com/boc-tothefuture/openhab-jruby/commit/251f62541eff71aa5238ff66bde9160b80f69a17))

## [4.30.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.30.1...4.30.2) (2022-01-20)


### Bug Fixes

* **logger:** incorrect logger prefix on non standard gem_home path ([a3d9677](https://github.com/boc-tothefuture/openhab-jruby/commit/a3d96779b32d5dd2f46912f1f64321851030296b))

## [4.30.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.30.0...4.30.1) (2022-01-19)


### Bug Fixes

* **types:** fix already initialized warning on openhab 3.2.0 ([188f2b0](https://github.com/boc-tothefuture/openhab-jruby/commit/188f2b0c48fdb04bc8a90fd0602ee20a66856ed8))

# [4.30.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.29.0...4.30.0) (2022-01-18)


### Features

* **conditions:** support procs/lambdas for trigger conditions ([0f0bd16](https://github.com/boc-tothefuture/openhab-jruby/commit/0f0bd160e2d70e6f3ec38f910a4ecbab38af2af7))

# [4.29.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.28.2...4.29.0) (2022-01-17)


### Features

* **rules:** support ranges as rule conditions ([8cd6901](https://github.com/boc-tothefuture/openhab-jruby/commit/8cd6901c762d6a903ccc42e7c05e056b6abdd25d))

## [4.28.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.28.1...4.28.2) (2022-01-17)

## [4.28.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.28.0...4.28.1) (2022-01-15)


### Bug Fixes

* **exception_handling:** fix java exception handling ([3539136](https://github.com/boc-tothefuture/openhab-jruby/commit/35391361c2713705535aa2f13142ecfa9c97a367))
* **java_class:** fix java to ruby class ([7f4b0bc](https://github.com/boc-tothefuture/openhab-jruby/commit/7f4b0bc371c30c9258fcc9ed440332511c4caaca))

# [4.28.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.27.1...4.28.0) (2022-01-14)


### Features

* **timer:** add timers[id].cancel_all shorthand for timers[id].each(&:cancel) ([d820471](https://github.com/boc-tothefuture/openhab-jruby/commit/d820471d60b1c0bd4b766a4b8990b0f1980aa1d6))

## [4.27.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.27.0...4.27.1) (2022-01-10)


### Bug Fixes

* **ensure:** faulty ensure on boolean commands ([623a08e](https://github.com/boc-tothefuture/openhab-jruby/commit/623a08ec69f56040502a86ab72b129985f9f8e1f))
* **item_groups:** fix Item#groups returning nil sometimes ([20ae855](https://github.com/boc-tothefuture/openhab-jruby/commit/20ae8558e7a443eae2be412f69fdc25de8d4431b))

# [4.27.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.26.4...4.27.0) (2022-01-06)


### Features

* **item:** support reloading of references items ([64059cc](https://github.com/boc-tothefuture/openhab-jruby/commit/64059cca79d5dcd775ab8a8fe4154123a80f7cd3))

## [4.26.4](https://github.com/boc-tothefuture/openhab-jruby/compare/4.26.3...4.26.4) (2022-01-06)


### Bug Fixes

* **monthday:** fix monthday error when rolling over to another year ([2bf6aa9](https://github.com/boc-tothefuture/openhab-jruby/commit/2bf6aa95b8483fde3c5fafeb1cde243b959f2602))

## [4.26.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.26.2...4.26.3) (2022-01-02)


### Bug Fixes

* **test:** instead of sleep, wait for for persistence feature to be installed ([a926d73](https://github.com/boc-tothefuture/openhab-jruby/commit/a926d73b0c21866713096300dd3c33c316271cf4))

## [4.26.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.26.1...4.26.2) (2021-12-31)


### Bug Fixes

* **open_closed_type:** state not inverted with ! operator ([498b515](https://github.com/boc-tothefuture/openhab-jruby/commit/498b5155caf203f8103e171914ba67149f4bb76a))

## [4.26.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.26.0...4.26.1) (2021-12-29)


### Bug Fixes

* **docs:** fix link to Yard docs ([7ca4bce](https://github.com/boc-tothefuture/openhab-jruby/commit/7ca4bce1e098a41cbb773a4ccf485092b5a5ed31))

# [4.26.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.25.0...4.26.0) (2021-12-26)


### Bug Fixes

* **guard:** execute guard in main context ([b1f1fe0](https://github.com/boc-tothefuture/openhab-jruby/commit/b1f1fe08d37674c7ea7d0db91bf1780b46f20ff7))


### Features

* **watch:** add trigger for file/directory watching ([ed6352a](https://github.com/boc-tothefuture/openhab-jruby/commit/ed6352aaeceaf99a585db7e5012d96ee853f6974))

# [4.25.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.24.1...4.25.0) (2021-12-21)


### Features

* **month_day:** support keyword arguments to create monthday ([50f0f05](https://github.com/boc-tothefuture/openhab-jruby/commit/50f0f0532e349f7bb74b42c1badc388401ef241c))

## [4.24.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.24.0...4.24.1) (2021-12-14)


### Bug Fixes

* **timer_manager:** timers[nonexistent_id] should return nil ([550d9e0](https://github.com/boc-tothefuture/openhab-jruby/commit/550d9e09ce04e1050bcb0623bb2d5339359bb477))

# [4.24.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.23.0...4.24.0) (2021-12-05)


### Features

* **location:** support hashes for locations ([ae8ff6a](https://github.com/boc-tothefuture/openhab-jruby/commit/ae8ff6ac8fc4d2a3bb20875962776ba977ea7546))

# [4.23.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.22.2...4.23.0) (2021-12-05)


### Bug Fixes

* **monthday:** fix equality comparison against string and allow parsing single digit month-days ([a9d8b47](https://github.com/boc-tothefuture/openhab-jruby/commit/a9d8b471aa0de60c40cc534e31ebcd4f0e6b8b2a))


### Features

* **hsb:** add from/to hash support ([91876d0](https://github.com/boc-tothefuture/openhab-jruby/commit/91876d01aa8577480ef88b014530064ba0d3a6ca))

## [4.22.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.22.1...4.22.2) (2021-12-04)


### Bug Fixes

* **timed_command:** fix race condition for timed commands ([6f3edd3](https://github.com/boc-tothefuture/openhab-jruby/commit/6f3edd35c7edbe85369e39ec102648e839dee043))

## [4.22.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.22.0...4.22.1) (2021-12-04)


### Bug Fixes

* **hsb:** fix type in from_hsb ([9ebe0f2](https://github.com/boc-tothefuture/openhab-jruby/commit/9ebe0f2754424a2c31b2cb0083c9db8793f48360))

# [4.22.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.21.0...4.22.0) (2021-12-03)


### Features

* **datetime:** support ZonedDateTime objects as commands for DateTime items ([72287c1](https://github.com/boc-tothefuture/openhab-jruby/commit/72287c1bd9f4b9f7cc0b5ead296fa98e661f04a5))

# [4.21.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.20.0...4.21.0) (2021-12-02)


### Bug Fixes

* **logging:** log rule name or file name with log entries ([a003904](https://github.com/boc-tothefuture/openhab-jruby/commit/a00390483775484b3513c433c9257c784311a7ea))


### Features

* **attach:** support attachments on cron triggers ([70ef1dc](https://github.com/boc-tothefuture/openhab-jruby/commit/70ef1dca219551627781bd5b66af9a8d5c3ddf13))

# [4.20.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.19.1...4.20.0) (2021-12-01)


### Bug Fixes

* **rule:** rule return value caused namespace errors ([22fea0b](https://github.com/boc-tothefuture/openhab-jruby/commit/22fea0b1d98987f86ddfa4c1f34add397815e361))


### Features

* **timers:** support passing custom objects as timer duration ([0fb0bcf](https://github.com/boc-tothefuture/openhab-jruby/commit/0fb0bcf0c7821f54685763b67b0f35c55de0f6f8))

## [4.19.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.19.0...4.19.1) (2021-12-01)


### Bug Fixes

* **includes:** remove redundant includes ([23376c4](https://github.com/boc-tothefuture/openhab-jruby/commit/23376c4e6b224c4a17418e2dbaab18556435388f))

# [4.19.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.18.0...4.19.0) (2021-12-01)


### Bug Fixes

* **comparisons:** === should perform an exact type match for case statements ([3311e26](https://github.com/boc-tothefuture/openhab-jruby/commit/3311e268262cd15388f6422c18aa82b5dfc63c24))


### Features

* **channel_trigger:** allow setting channel triggers directly from thing/channel objects ([9d99ee6](https://github.com/boc-tothefuture/openhab-jruby/commit/9d99ee62c7f57f8050ce57b996efcf1387e7e52a))
* **uid:** make working with UIDs easier (string comparisons) ([5a89ac8](https://github.com/boc-tothefuture/openhab-jruby/commit/5a89ac8b6e2510519bce73075044d6422513fdde))

# [4.18.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.17.0...4.18.0) (2021-11-30)


### Features

* **switch:** accept boolean values ([605949c](https://github.com/boc-tothefuture/openhab-jruby/commit/605949cea2f6ca2f6e1ec15177c3038d8da26174))

# [4.17.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.16.0...4.17.0) (2021-11-30)


### Bug Fixes

* **trigger:** create multiple delayed triggers for array from/to states ([70d3b4a](https://github.com/boc-tothefuture/openhab-jruby/commit/70d3b4ac3f25e974e4a8bfc7a994316dea09bd65))


### Features

* **things:** easy access to channels from things, and items from channels ([813bc5d](https://github.com/boc-tothefuture/openhab-jruby/commit/813bc5d9574b49ea45720def1c98354c28dc8686))

# [4.16.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.15.1...4.16.0) (2021-11-30)


### Features

* **item:** add linked_thing and all_linked_things to items ([5a640c6](https://github.com/boc-tothefuture/openhab-jruby/commit/5a640c686914478166d3c853b653387bd341a40e))
* **linked_thing:** alias thing/things to linked_thing/all_linked_things ([9898b8a](https://github.com/boc-tothefuture/openhab-jruby/commit/9898b8aa2bb3bedf1fee6a64114446b4667c10d4)), closes [#427](https://github.com/boc-tothefuture/openhab-jruby/issues/427)
* **things:** add ability to lookup thing using ThingUID to things[] ([9650698](https://github.com/boc-tothefuture/openhab-jruby/commit/9650698bb6c80950cc22f9be4a59444773da2ff9))

## [4.15.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.15.0...4.15.1) (2021-11-24)


### Bug Fixes

* **rule:** rule method should return the rule object ([239403f](https://github.com/boc-tothefuture/openhab-jruby/commit/239403f31ac0385ceb90613e1c96a6ed759e7b40))

# [4.15.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.14.2...4.15.0) (2021-11-24)


### Bug Fixes

* **guard:** include attachment in guards' event ([61f387c](https://github.com/boc-tothefuture/openhab-jruby/commit/61f387c077e3d2c085cb639aa87dd51e32475d48))


### Features

* **trigger:** support creating triggers for any trigger type ([6a90d43](https://github.com/boc-tothefuture/openhab-jruby/commit/6a90d43dc19d372cea56f6874ac46404f86f3058))

## [4.14.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.14.1...4.14.2) (2021-11-22)


### Bug Fixes

* **comparisons:** fix comparison errors between two types ([d694bc8](https://github.com/boc-tothefuture/openhab-jruby/commit/d694bc8760f7bb5f63a48848cff5165779646e47))

## [4.14.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.14.0...4.14.1) (2021-11-20)


### Bug Fixes

* **timer:** remove redundant delegators ([932e82b](https://github.com/boc-tothefuture/openhab-jruby/commit/932e82b561c6a246a178160bb3dfa1b8a83dd594))

# [4.14.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.13.5...4.14.0) (2021-11-14)


### Bug Fixes

* **script_handling:** add tests ([70008fc](https://github.com/boc-tothefuture/openhab-jruby/commit/70008fcb83eb7be86273df1f4093ebc014cbc529))


### Features

* **script_callbacks:** make script_loaded/unloaded accessible ([4a5e33d](https://github.com/boc-tothefuture/openhab-jruby/commit/4a5e33d85c051e8b4418b02a005a494406118fd8)), closes [#316](https://github.com/boc-tothefuture/openhab-jruby/issues/316)

## [4.13.5](https://github.com/boc-tothefuture/openhab-jruby/compare/4.13.4...4.13.5) (2021-11-14)


### Bug Fixes

* **script_handling:** scriptLoaded and scriptUnloaded not executed ([4082280](https://github.com/boc-tothefuture/openhab-jruby/commit/4082280eef5519cc0efac0a3e53c366f327fc1a0))

## [4.13.4](https://github.com/boc-tothefuture/openhab-jruby/compare/4.13.3...4.13.4) (2021-11-10)


### Bug Fixes

* **actions:** call to_s to accept item as an argument ([9f770b3](https://github.com/boc-tothefuture/openhab-jruby/commit/9f770b3cb9c0a8610b5e7154efab04406a0e35a8))
* **dev:** add mac M1 platform to Gemfile.lock ([76fdbfd](https://github.com/boc-tothefuture/openhab-jruby/commit/76fdbfd6ca8dc6d0d1eafaa086611d85ea0ecd95))

## [4.13.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.13.2...4.13.3) (2021-11-08)


### Bug Fixes

* **binding:** move gem home default and mkdirs ([a9ccf3f](https://github.com/boc-tothefuture/openhab-jruby/commit/a9ccf3f1db4d2335c1509ffe56c83242926e097c))

## [4.13.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.13.1...4.13.2) (2021-11-08)


### Bug Fixes

* **binding:** fix binding support for gem ugprades ([07a1668](https://github.com/boc-tothefuture/openhab-jruby/commit/07a16681864f49e9613673988bbad0e09fd3fcba))

## [4.13.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.13.0...4.13.1) (2021-11-07)


### Bug Fixes

* **month_day:** test between guards with Time instead of TimeOfDay ([65bf3b1](https://github.com/boc-tothefuture/openhab-jruby/commit/65bf3b159255b56a2446059aeda535002d51639f))

# [4.13.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.12.1...4.13.0) (2021-11-06)


### Bug Fixes

* **test:** test against jruby plugin that fixes 3.2M2 reload bug ([bb98cb0](https://github.com/boc-tothefuture/openhab-jruby/commit/bb98cb091a8fb79578fcd834922eebc33aac394e))


### Features

* **percenttype:** add PercentType#scale and PercentType#to_byte ([54d2ec3](https://github.com/boc-tothefuture/openhab-jruby/commit/54d2ec3cb7a84eac5bb0341911f9fe16da81d105)), closes [#350](https://github.com/boc-tothefuture/openhab-jruby/issues/350)

## [4.12.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.12.0...4.12.1) (2021-11-06)


### Bug Fixes

* **dev:** target ruby 2.6 ([cdd3ea1](https://github.com/boc-tothefuture/openhab-jruby/commit/cdd3ea1c75c950b807a56f68cbd78ad68c59939d))
* **quantity:** fix comparison between integer on left and quantity on right ([b7f7531](https://github.com/boc-tothefuture/openhab-jruby/commit/b7f753110332b71f8b665e22562e2a02d3c86614)), closes [#352](https://github.com/boc-tothefuture/openhab-jruby/issues/352)

# [4.12.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.11.2...4.12.0) (2021-11-06)


### Features

* **build:** test against jruby 9.3 ([690699d](https://github.com/boc-tothefuture/openhab-jruby/commit/690699d61911cc4e67a4bad0b37d7f43328cf73e))

## [4.11.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.11.1...4.11.2) (2021-11-06)


### Bug Fixes

* **metadata:** return ruby hash inside metadata enumerator ([4347aa9](https://github.com/boc-tothefuture/openhab-jruby/commit/4347aa98966561c12c32a6695d6acadd6cedb2bf))

## [4.11.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.11.0...4.11.1) (2021-11-06)


### Bug Fixes

* **reentrant_timer:** reset the timer duration to the latest call ([e8e8b66](https://github.com/boc-tothefuture/openhab-jruby/commit/e8e8b666080a6cf0b47a08e13b9d4dcc8f9a9cbc))

# [4.11.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.10.3...4.11.0) (2021-11-05)


### Features

* **between:** support for month-day ranges ([f059c59](https://github.com/boc-tothefuture/openhab-jruby/commit/f059c59a173d322270e1c3053c94dba531e3beaa))

## [4.10.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.10.2...4.10.3) (2021-11-04)


### Bug Fixes

* **timer:** check the argument to reschedule ([d1e895f](https://github.com/boc-tothefuture/openhab-jruby/commit/d1e895ff243f7160bd2f54cfce5925ba07fabfff))

## [4.10.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.10.1...4.10.2) (2021-11-03)


### Bug Fixes

* **test:** added test coverage for mixed type between guards ([9030b3f](https://github.com/boc-tothefuture/openhab-jruby/commit/9030b3f9ca57b66d5f6865b6cbf8f3b501432587))

## [4.10.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.10.0...4.10.1) (2021-11-02)


### Bug Fixes

* **type:** allow comparison against incompatible types ([4ef6b2d](https://github.com/boc-tothefuture/openhab-jruby/commit/4ef6b2d0017c82c74f4d0ce82a7fb7e91681770c)), closes [#328](https://github.com/boc-tothefuture/openhab-jruby/issues/328)

# [4.10.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.9.0...4.10.0) (2021-11-02)


### Features

* **attachments:** adds attachments to triggers ([88d35c5](https://github.com/boc-tothefuture/openhab-jruby/commit/88d35c534d28b302e33c8e830b4bbe6763f57abe))

# [4.9.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.8.5...4.9.0) (2021-11-01)


### Features

* **guards:** guards only_if/not_if support arrays of items ([66cda53](https://github.com/boc-tothefuture/openhab-jruby/commit/66cda53ffec10a14b4c14931838c24e96bc655b1))

## [4.8.5](https://github.com/boc-tothefuture/openhab-jruby/compare/4.8.4...4.8.5) (2021-11-01)


### Bug Fixes

* **guard:** only_if/not_if should work on all item types ([1c717a8](https://github.com/boc-tothefuture/openhab-jruby/commit/1c717a81d18030ae60d935f4625fd3557e139754))

## [4.8.4](https://github.com/boc-tothefuture/openhab-jruby/compare/4.8.3...4.8.4) (2021-11-01)

## [4.8.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.8.2...4.8.3) (2021-10-31)


### Bug Fixes

* **triggers:** trigger methods return the trigger objects ([463a928](https://github.com/boc-tothefuture/openhab-jruby/commit/463a9283e195bd591504047b15ba7abc7b5ff264))

## [4.8.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.8.1...4.8.2) (2021-10-30)


### Bug Fixes

* **guards:** log exception and stack traces encountered when guard procs are executed ([68c5f4d](https://github.com/boc-tothefuture/openhab-jruby/commit/68c5f4dafb04779ac97e88c3612ab68443cf7377))

## [4.8.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.8.0...4.8.1) (2021-10-30)


### Bug Fixes

* **hsb:** fully qualify units class ([25196d5](https://github.com/boc-tothefuture/openhab-jruby/commit/25196d559f876521dc027546d071defb7c3a5b01))

# [4.8.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.7.1...4.8.0) (2021-10-29)


### Features

* **timer:** supports reentrant timers and timed commands for items ([08d8f16](https://github.com/boc-tothefuture/openhab-jruby/commit/08d8f16ab490a63e614415c1ecf057429acc4e45))

## [4.7.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.7.0...4.7.1) (2021-10-29)


### Bug Fixes

* **hsb:** convert csv strings to hsb value ([5aad833](https://github.com/boc-tothefuture/openhab-jruby/commit/5aad83310993e8d95b8e372cd257d572e81beb60))

# [4.7.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.6.2...4.7.0) (2021-10-27)


### Bug Fixes

* **changed:** changed trigger now supports multiple from values ([20bb64e](https://github.com/boc-tothefuture/openhab-jruby/commit/20bb64e01be2e4effc1886c02f4137375cea5725))
* **logging:** use the class name not "Class" for class-level loggers ([05b6217](https://github.com/boc-tothefuture/openhab-jruby/commit/05b62174729523e499f66c52d432fa4b913a59a5))


### Features

* **metadata:** allow assignment to existing metadata config ([02df58a](https://github.com/boc-tothefuture/openhab-jruby/commit/02df58aeea7bef3d75212476ddd615c30d2ac9d2))

## [4.6.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.6.1...4.6.2) (2021-10-24)


### Bug Fixes

* **number_item:** return false for number predicate methods when NULL ([f147277](https://github.com/boc-tothefuture/openhab-jruby/commit/f147277785f33fc7ab5d854a4fff0b9f786a2106))

## [4.6.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.6.0...4.6.1) (2021-10-24)


### Bug Fixes

* **timer:** cancel timers in a rule when rule is unloaded ([901a63e](https://github.com/boc-tothefuture/openhab-jruby/commit/901a63e59f5086b559fd84b1fdb2b13b3d4a7800))

# [4.6.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.5.0...4.6.0) (2021-10-20)


### Bug Fixes

* **quantity:** fix constructing quantity from numeric with | within rule ([42dbafb](https://github.com/boc-tothefuture/openhab-jruby/commit/42dbafb3e3cf634c1493ffd19b03fd0e03b07689)), closes [#319](https://github.com/boc-tothefuture/openhab-jruby/issues/319)
* **tests:** fix ensure_states tests fragility ([7a36c43](https://github.com/boc-tothefuture/openhab-jruby/commit/7a36c43f583068a3e9489b0199ce0c02d0581c2c)), closes [#304](https://github.com/boc-tothefuture/openhab-jruby/issues/304)


### Features

* **location:** support location items ([ceb224a](https://github.com/boc-tothefuture/openhab-jruby/commit/ceb224aa0e8dfd0d82910ac3eb780d8f11e78c00)), closes [#37](https://github.com/boc-tothefuture/openhab-jruby/issues/37)

# [4.5.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.4.0...4.5.0) (2021-10-19)


### Features

* **color:** support for color items and hsb type ([8f45492](https://github.com/boc-tothefuture/openhab-jruby/commit/8f454924247674e75eaaa8a93e90176fff1ead8e)), closes [#34](https://github.com/boc-tothefuture/openhab-jruby/issues/34)

# [4.4.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.3.0...4.4.0) (2021-10-19)


### Bug Fixes

* **actions:** fix say and play_media actions for PercentType change ([53d7e06](https://github.com/boc-tothefuture/openhab-jruby/commit/53d7e062ec09130cefe089c00f42c302ce745f02)), closes [#298](https://github.com/boc-tothefuture/openhab-jruby/issues/298)
* **docs:** added docs for ensure/ensure_state ([77904b1](https://github.com/boc-tothefuture/openhab-jruby/commit/77904b16288efc3b7b9d2eac470ffa128d109bb3))


### Features

* **ensure:** add ensure_states feature ([b06385b](https://github.com/boc-tothefuture/openhab-jruby/commit/b06385bb9be81ffdb42c86156e6f4b184a498710)), closes [#275](https://github.com/boc-tothefuture/openhab-jruby/issues/275)

# [4.3.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.2.0...4.3.0) (2021-10-19)


### Bug Fixes

* **null_comparison:** fix comparison between two number items in state NULL ([b3bf156](https://github.com/boc-tothefuture/openhab-jruby/commit/b3bf1563c0dddd2246b0060ded8a34df84794e4c)), closes [#298](https://github.com/boc-tothefuture/openhab-jruby/issues/298)


### Features

* **rules:** add terse rule syntax for simple rules ([1c4b774](https://github.com/boc-tothefuture/openhab-jruby/commit/1c4b7744553679f1296428e765d04dbc57cfe99c))

# [4.2.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.1.4...4.2.0) (2021-10-18)


### Features

* **types:** allow comparison and arithmetic directly against state types ([22e237f](https://github.com/boc-tothefuture/openhab-jruby/commit/22e237fa93ae373fd63f05b9eaa17c0a78905939))

## [4.1.4](https://github.com/boc-tothefuture/openhab-jruby/compare/4.1.3...4.1.4) (2021-10-11)


### Bug Fixes

* **dev:** add binstubs for yard ([e2f8053](https://github.com/boc-tothefuture/openhab-jruby/commit/e2f8053452872df7f7fb26da41af2905ebe32426))
* **dev:** don't generate documentation when installing gem for tests ([995b8fc](https://github.com/boc-tothefuture/openhab-jruby/commit/995b8fcb8afad0f3546eb0500da40febcb47c956))

## [4.1.3](https://github.com/boc-tothefuture/openhab-jruby/compare/4.1.2...4.1.3) (2021-10-10)


### Bug Fixes

* **docs:** update installation docs to reference version 4.x of the gem ([c486cad](https://github.com/boc-tothefuture/openhab-jruby/commit/c486cad67e70483b2d3398116d79ce0778aafeec))

## [4.1.2](https://github.com/boc-tothefuture/openhab-jruby/compare/4.1.1...4.1.2) (2021-10-08)


### Bug Fixes

* **items:** restore ability to add items arrays together ([4b318c1](https://github.com/boc-tothefuture/openhab-jruby/commit/4b318c1d4e02fe2789a9f20fa198fb2f6ad629a2)), closes [#288](https://github.com/boc-tothefuture/openhab-jruby/issues/288)

## [4.1.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.1.0...4.1.1) (2021-10-07)


### Bug Fixes

* **dev:** update gemfile and binstubs for use with MRI ([7fe0027](https://github.com/boc-tothefuture/openhab-jruby/commit/7fe002715d3aa51378f3c72ddf4c63c3b4c20e1e))

# [4.1.0](https://github.com/boc-tothefuture/openhab-jruby/compare/4.0.1...4.1.0) (2021-10-06)


### Features

* **decimal_type:** zero?, positive?, negative? predicates directly on DecimalType ([bd69a76](https://github.com/boc-tothefuture/openhab-jruby/commit/bd69a763ec81e15bd4626264af4bc29a279d393c))

## [4.0.1](https://github.com/boc-tothefuture/openhab-jruby/compare/4.0.0...4.0.1) (2021-10-05)


### Performance Improvements

* **things, items:** improves performance on array accessors '[]' ([24bb04b](https://github.com/boc-tothefuture/openhab-jruby/commit/24bb04b34cc13ebbd4906fe547e31154d55e737c))

# [4.0.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.9.4...4.0.0) (2021-10-05)


### Features

* **command:** add predicate methods for named commands ([a347bb5](https://github.com/boc-tothefuture/openhab-jruby/commit/a347bb5942e28825a4be5e2adc450bd033b91e0a))
* **group_item:** alias items to members ([8e91ffc](https://github.com/boc-tothefuture/openhab-jruby/commit/8e91ffccc8d4f0dd2cc8a72aedd502459f140028))
* **states:** add predicate methods to several states ([5f987cc](https://github.com/boc-tothefuture/openhab-jruby/commit/5f987cc1ce7f86e8ab02b411635f55c8bbc4210f)), closes [#237](https://github.com/boc-tothefuture/openhab-jruby/issues/237)
* **types:** ensure (almost) all command types are inspectable ([2073072](https://github.com/boc-tothefuture/openhab-jruby/commit/2073072920a3becdb280d67048ab3fb2817e86eb))


* feat(events)!: wrap event.state same as item.state ([cbe6e5c](https://github.com/boc-tothefuture/openhab-jruby/commit/cbe6e5c275a30f84ca2ee3e32f1e3ae773b48e7e))


### BREAKING CHANGES

*  * event.state returns nil it's NULL or UNDEF.
 * event.last renamed to event.was (the predicate methods make much more
  sense calling it was instead of last, similar to Rail's tracking of
  changed attributes).
 * event.was returns nil if's NULL or UNDEF

## [3.9.4](https://github.com/boc-tothefuture/openhab-jruby/compare/3.9.3...3.9.4) (2021-09-25)


### Bug Fixes

* **build:** have release process keep Gemfile.lock up to date ([178cf4d](https://github.com/boc-tothefuture/openhab-jruby/commit/178cf4de37e7a50106697d43b33f673319a3c4ea))

## [3.9.3](https://github.com/boc-tothefuture/openhab-jruby/compare/3.9.2...3.9.3) (2021-09-25)

## [3.9.2](https://github.com/boc-tothefuture/openhab-jruby/compare/3.9.1...3.9.2) (2021-09-25)


### Bug Fixes

* **dev:** ignore lockfile for file named gems.rb ([8e31e0d](https://github.com/boc-tothefuture/openhab-jruby/commit/8e31e0d882a77c6a0422015ac5dd06c0b0c7ab9c))
* **release:** pin npm release versions to prevent build failures on upgrade of semantec release ([e1dc2a3](https://github.com/boc-tothefuture/openhab-jruby/commit/e1dc2a329e085ab7a0092762a0d3cd8c8df92737))

## [3.9.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.9.0...3.9.1) (2021-09-17)


### Bug Fixes

* **tests:** speed up tests by avoiding unnecessary work ([64c759c](https://github.com/boc-tothefuture/openhab-jruby/commit/64c759c9ee7b483f909db8e10b02467c0e3a6767))
* **tests:** speed up tests by forcing openhab to find rules ([d05a9e5](https://github.com/boc-tothefuture/openhab-jruby/commit/d05a9e51f15e7683b66ab52797ee2d4bd20a24ff))

# [3.9.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.8.3...3.9.0) (2021-09-17)


### Features

* **load_path:** apply $RUBYLIB ([29b6a34](https://github.com/boc-tothefuture/openhab-jruby/commit/29b6a34f050e82788f2e18d5de8e0025207de2c3))

## [3.8.3](https://github.com/boc-tothefuture/openhab-jruby/compare/3.8.2...3.8.3) (2021-09-16)


### Bug Fixes

* **docs:** make shields in readme actual links ([962eec7](https://github.com/boc-tothefuture/openhab-jruby/commit/962eec794e05ae0f4ac507dcf2f34b1a33ff085a))

## [3.8.2](https://github.com/boc-tothefuture/openhab-jruby/compare/3.8.1...3.8.2) (2021-09-15)


### Bug Fixes

* **dev:** add binstubs ([a425401](https://github.com/boc-tothefuture/openhab-jruby/commit/a425401ca5a588960a81ecaaf793be140c3a316f))

## [3.8.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.8.0...3.8.1) (2021-09-15)


### Bug Fixes

* **build:** commit the Gemfile.lock ([17def5c](https://github.com/boc-tothefuture/openhab-jruby/commit/17def5c097fd95cc844c8651e155cfdbe631b512))

# [3.8.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.7.4...3.8.0) (2021-09-15)


### Features

* **duration:** support duration methods on Float too ([fae9daf](https://github.com/boc-tothefuture/openhab-jruby/commit/fae9daf8b0dd0d3b854652a54663c4fb5d963cc8)), closes [#263](https://github.com/boc-tothefuture/openhab-jruby/issues/263)

## [3.7.4](https://github.com/boc-tothefuture/openhab-jruby/compare/3.7.3...3.7.4) (2021-09-15)


### Bug Fixes

* **test:** test against released version of openhab 3.1 and set default to 3.1 ([b8d09c1](https://github.com/boc-tothefuture/openhab-jruby/commit/b8d09c106ae708107ac75bcb66406b66e483b7ee))

## [3.7.3](https://github.com/boc-tothefuture/openhab-jruby/compare/3.7.2...3.7.3) (2021-09-15)


### Bug Fixes

* **build:** updated to new version of jruby scripting ([ae8b5a2](https://github.com/boc-tothefuture/openhab-jruby/commit/ae8b5a276676f6509e8862f73276997bafa38cd5))

## [3.7.2](https://github.com/boc-tothefuture/openhab-jruby/compare/3.7.1...3.7.2) (2021-09-14)


### Bug Fixes

* **docs:** remove duplicated "compare" in a few places ([2a9af7b](https://github.com/boc-tothefuture/openhab-jruby/commit/2a9af7b2ae4eed5668218d9ec01f4585369d6a3c))

## [3.7.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.7.0...3.7.1) (2021-09-14)


### Bug Fixes

* **test:** fix rubocop violations against newest rubocop ([e8b859b](https://github.com/boc-tothefuture/openhab-jruby/commit/e8b859b795ac57fb1873b199f2e7723313240433))

# [3.7.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.6.4...3.7.0) (2021-06-04)


### Features

* **quantity:** implement positive?, negative?, and zero? for quantity and dimensioned numberitem ([0d2c43c](https://github.com/boc-tothefuture/openhab-jruby/commit/0d2c43ca99db6abeef068adff7dca5f3bdf71703))

## [3.6.4](https://github.com/boc-tothefuture/openhab-jruby/compare/3.6.3...3.6.4) (2021-06-04)


### Bug Fixes

* **items:** decorated items could not be used as hash keys ([a4ff086](https://github.com/boc-tothefuture/openhab-jruby/commit/a4ff0869171ff10c1bae505fe3bc3af480d0cb54))

## [3.6.3](https://github.com/boc-tothefuture/openhab-jruby/compare/3.6.2...3.6.3) (2021-06-03)


### Bug Fixes

* improve reliability of some tests ([22bc48e](https://github.com/boc-tothefuture/openhab-jruby/commit/22bc48e677b2021c28366ca9b57b06ca91a10e54))

## [3.6.2](https://github.com/boc-tothefuture/openhab-jruby/compare/3.6.1...3.6.2) (2021-06-02)


### Bug Fixes

* **items:** format BigDecimal state as a string the parser accepts ([c752711](https://github.com/boc-tothefuture/openhab-jruby/commit/c752711b7057c819c1a372a9d35e1e85bf4c54b5))

## [3.6.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.6.0...3.6.1) (2021-06-02)

# [3.6.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.5.0...3.6.0) (2021-06-01)


### Features

* **build:** support testing of multiple versions of openhab ([600bc88](https://github.com/boc-tothefuture/openhab-jruby/commit/600bc88b281332f907948f65f59b11f7f66948c6))

# [3.5.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.4.3...3.5.0) (2021-06-01)


### Bug Fixes

* **store_states:** error when given a decorated item ([ae7e1bc](https://github.com/boc-tothefuture/openhab-jruby/commit/ae7e1bcf250a3bac18d080efc7b966397cb84279))


### Features

* add oh_item to item wrappers through def_item_delegator ([079314f](https://github.com/boc-tothefuture/openhab-jruby/commit/079314f3c9213e5e0b3d29e2824a22e2c36d8a0b))

## [3.4.3](https://github.com/boc-tothefuture/openhab-jruby/compare/3.4.2...3.4.3) (2021-05-20)


### Bug Fixes

* **build:** updated version of OpenHab ([ef1b792](https://github.com/boc-tothefuture/openhab-jruby/commit/ef1b7923e10ba67800eef7aae32b3d5eb0d5e729))

## [3.4.2](https://github.com/boc-tothefuture/openhab-jruby/compare/3.4.1...3.4.2) (2021-04-02)


### Bug Fixes

* **metadata:** convert loaded metadata config into Ruby objects ([aa8e2b7](https://github.com/boc-tothefuture/openhab-jruby/commit/aa8e2b78987d792d6b2299df6e262e68716827ca))

## [3.4.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.4.0...3.4.1) (2021-04-02)


### Bug Fixes

* **dependency:** swapped mimemagic for marcel for mime type detection ([b1ec891](https://github.com/boc-tothefuture/openhab-jruby/commit/b1ec8915a05dff6236677df1a0e3e115b8cb0d51))

# [3.4.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.3.0...3.4.0) (2021-03-22)


### Features

* **thing:** add boolean methods for checking thing's status ([58bda12](https://github.com/boc-tothefuture/openhab-jruby/commit/58bda12449d72c7ac1d8e1ee1d7c2876897a0851))

# [3.3.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.2.1...3.3.0) (2021-03-16)


### Features

* **persistence:** convert HistoricItem methods to directly return its state ([942d7ea](https://github.com/boc-tothefuture/openhab-jruby/commit/942d7ea22edafc697b5a3bf8c222a1ecb1860551))

## [3.2.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.2.0...3.2.1) (2021-03-11)


### Bug Fixes

* handle native java exceptions in clean_backtrace ([a6f7be4](https://github.com/boc-tothefuture/openhab-jruby/commit/a6f7be47c476e43fb7e3fd146fb02d4c07b6fc4a))

# [3.2.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.1.2...3.2.0) (2021-03-10)


### Features

* support more comparisons ([3898d2d](https://github.com/boc-tothefuture/openhab-jruby/commit/3898d2da40994e322ffb2773fe35184debf0d261))

## [3.1.2](https://github.com/boc-tothefuture/openhab-jruby/compare/3.1.1...3.1.2) (2021-03-09)


### Bug Fixes

* **scope:** change execution block binding to be object that based a block to rule ([b529684](https://github.com/boc-tothefuture/openhab-jruby/commit/b5296844e6a677452388dfb70e743f18a66d3fd6))

## [3.1.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.1.0...3.1.1) (2021-03-08)


### Bug Fixes

* **rollershutter_item:** add safe navigation and nil checks ([1e98464](https://github.com/boc-tothefuture/openhab-jruby/commit/1e984646d50f97fd3ccd933e548c08e4f8290704))

# [3.1.0](https://github.com/boc-tothefuture/openhab-jruby/compare/3.0.1...3.1.0) (2021-03-08)


### Features

* **image:** support for image items ([dacc7a8](https://github.com/boc-tothefuture/openhab-jruby/commit/dacc7a8531dcbe256c16a7ac8685ecb0c7e5dcc1))

## [3.0.1](https://github.com/boc-tothefuture/openhab-jruby/compare/3.0.0...3.0.1) (2021-03-03)


### Bug Fixes

* triggering on multiple items caused a stack overflow ([a1fac1d](https://github.com/boc-tothefuture/openhab-jruby/commit/a1fac1d84269fb462acd8e378c8f5f460e2d447b))

# [3.0.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.27.1...3.0.0) (2021-03-02)


### Features

* **groups:** groups now act as items ([210e507](https://github.com/boc-tothefuture/openhab-jruby/commit/210e50721adbf908a2f888cae7f46fc1687be4f9))


### BREAKING CHANGES

* **groups:** `items` no longer acts as a indicator to rules to
trigger on member changes, it has been replaced with `members`

## [2.27.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.27.0...2.27.1) (2021-03-02)

# [2.27.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.26.1...2.27.0) (2021-03-02)


### Features

* **player:** add support for player items ([70418ab](https://github.com/boc-tothefuture/openhab-jruby/commit/70418abfa0c504ed819e15c0508ad05e486fcf0d))

## [2.26.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.26.0...2.26.1) (2021-03-02)


### Performance Improvements

* **logging:** use block syntax to log method calls ([9657e72](https://github.com/boc-tothefuture/openhab-jruby/commit/9657e72c4d80b2c7adb722de428b830efb75e75f))

# [2.26.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.25.2...2.26.0) (2021-03-02)


### Features

* add stack trace to errors ([572114e](https://github.com/boc-tothefuture/openhab-jruby/commit/572114e74f688bc85925f0f33d2cf0bc3e06d4f8))

## [2.25.2](https://github.com/boc-tothefuture/openhab-jruby/compare/2.25.1...2.25.2) (2021-02-28)


### Performance Improvements

* **datetime:** delegate more methods directly to ZonedDateTime ([ea31954](https://github.com/boc-tothefuture/openhab-jruby/commit/ea3195402b5c4179090feafaba2d53476342251d))

## [2.25.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.25.0...2.25.1) (2021-02-28)

# [2.25.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.24.0...2.25.0) (2021-02-24)


### Features

* **groups:** support command and << ([dd140aa](https://github.com/boc-tothefuture/openhab-jruby/commit/dd140aa6f28f6138e197fdc2274f960ff304664e))

# [2.24.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.23.3...2.24.0) (2021-02-23)


### Features

* **groups:** adds supports for item groups ([127ab17](https://github.com/boc-tothefuture/openhab-jruby/commit/127ab17a69ec2ff2eac8674bba1c3ee2102a4fa9))

## [2.23.3](https://github.com/boc-tothefuture/openhab-jruby/compare/2.23.2...2.23.3) (2021-02-21)


### Bug Fixes

* **persistence:** selective conversion to Quantity ([3187de7](https://github.com/boc-tothefuture/openhab-jruby/commit/3187de7bdb1bea47e8ba8d288332da5c227e3892))

## [2.23.2](https://github.com/boc-tothefuture/openhab-jruby/compare/2.23.1...2.23.2) (2021-02-21)

## [2.23.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.23.0...2.23.1) (2021-02-20)

# [2.23.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.22.1...2.23.0) (2021-02-20)


### Bug Fixes

* **metadata:** convert value to string before assignment ([dba5db7](https://github.com/boc-tothefuture/openhab-jruby/commit/dba5db7d56f25ea279723c653c154c65c3fe030a))


### Features

* **event:** add event.state for update trigger ([d4eb4f7](https://github.com/boc-tothefuture/openhab-jruby/commit/d4eb4f78043ac108e54c0491affb72b383397b45))

## [2.22.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.22.0...2.22.1) (2021-02-20)


### Bug Fixes

* **changed:** for parameter with thing chaged trigger ([cd08922](https://github.com/boc-tothefuture/openhab-jruby/commit/cd08922fe7c9f4b2687b0b19000ecc3ba687bc9e))

# [2.22.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.21.0...2.22.0) (2021-02-19)


### Features

* add conversion operator for DecimalType to Quantity ([42bc5de](https://github.com/boc-tothefuture/openhab-jruby/commit/42bc5de8321d6e5b4554afd84fd5759d672bf992))

# [2.21.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.20.3...2.21.0) (2021-02-18)


### Features

* **persistence:** automatically convert to quantity for dimensioned items ([7e352d4](https://github.com/boc-tothefuture/openhab-jruby/commit/7e352d4cc1b4ff8ab50e409cf0ef56f4a6d74fae))

## [2.20.3](https://github.com/boc-tothefuture/openhab-jruby/compare/2.20.2...2.20.3) (2021-02-18)


### Bug Fixes

* **changed_duration:** stringitem from/to comparison didn't work ([21721e7](https://github.com/boc-tothefuture/openhab-jruby/commit/21721e74a7595de83d94cd2a9143ebde4b36938b))

## [2.20.2](https://github.com/boc-tothefuture/openhab-jruby/compare/2.20.1...2.20.2) (2021-02-18)

## [2.20.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.20.0...2.20.1) (2021-02-18)


### Bug Fixes

* **items:** to_s did not include UNDEF and NULL ([71f3de4](https://github.com/boc-tothefuture/openhab-jruby/commit/71f3de4c1f3fde6412ebe1748550a62e989187e0))

# [2.20.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.19.3...2.20.0) (2021-02-18)


### Features

* add dig-method to top level metadata ([2975cd5](https://github.com/boc-tothefuture/openhab-jruby/commit/2975cd565fb7dbf8c994fcb306d40ae75f2e8c03))

## [2.19.3](https://github.com/boc-tothefuture/openhab-jruby/compare/2.19.2...2.19.3) (2021-02-18)


### Bug Fixes

* **rule:** otherwise blocks are always executed ([dd5d5e5](https://github.com/boc-tothefuture/openhab-jruby/commit/dd5d5e5cd6a6eb02b57e5e70d34a27e512bc0d0e))

## [2.19.2](https://github.com/boc-tothefuture/openhab-jruby/compare/2.19.1...2.19.2) (2021-02-16)


### Bug Fixes

* **changed_duration:** guards not evaluated for changed duration ([48a63e8](https://github.com/boc-tothefuture/openhab-jruby/commit/48a63e82db6b82cdcf7a8855681db1fa65f23abc))

## [2.19.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.19.0...2.19.1) (2021-02-15)


### Bug Fixes

* **changed_duration:** cancel 'changed for' timer correctly ([1bf4aa3](https://github.com/boc-tothefuture/openhab-jruby/commit/1bf4aa390e8671e926fa44505cedd8f07d1d4260))

# [2.19.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.18.0...2.19.0) (2021-02-15)


### Features

* add RollershutterItem ([f5801d9](https://github.com/boc-tothefuture/openhab-jruby/commit/f5801d90b6998379db58c8462619d8f13332f0fa))

# [2.18.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.17.0...2.18.0) (2021-02-14)


### Features

* add DateTime Item type ([a3cc139](https://github.com/boc-tothefuture/openhab-jruby/commit/a3cc139d87b2df344bb1f0f78c3a68558e3e4fd5))

# [2.17.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.16.4...2.17.0) (2021-02-12)


### Features

* **units:** import OpenHAB common units for UoM ([351a776](https://github.com/boc-tothefuture/openhab-jruby/commit/351a77694fc89dcde9f93501324d91d03819fbd8))

## [2.16.4](https://github.com/boc-tothefuture/openhab-jruby/compare/2.16.3...2.16.4) (2021-02-12)


### Bug Fixes

* **changed_duration:** timer reschedule duration bug ([6bc8862](https://github.com/boc-tothefuture/openhab-jruby/commit/6bc8862f1d8b7631ef0ff79ac9599433e53a7259))

## [2.16.3](https://github.com/boc-tothefuture/openhab-jruby/compare/2.16.2...2.16.3) (2021-02-12)

## [2.16.2](https://github.com/boc-tothefuture/openhab-jruby/compare/2.16.1...2.16.2) (2021-02-11)


### Bug Fixes

* decorate items[itemname], event.item, and triggered item ([ce4ef03](https://github.com/boc-tothefuture/openhab-jruby/commit/ce4ef03afc3a9f10e96af17fccd61a0acf84cc4d))

## [2.16.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.16.0...2.16.1) (2021-02-11)


### Performance Improvements

* **timeofdayrangeelement:** subclass Numeric to make comparisons more efficient ([c2482e8](https://github.com/boc-tothefuture/openhab-jruby/commit/c2482e832fa3a4803bafef71217c6cfe1fdd2bed))

# [2.16.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.15.0...2.16.0) (2021-02-10)


### Features

* support comparisons between various numeric item/state types ([510d6db](https://github.com/boc-tothefuture/openhab-jruby/commit/510d6db9041afc91e261b43afd4d8e4b3ad135d3))

# [2.15.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.14.3...2.15.0) (2021-02-09)


### Features

* add Persistence support ([9cab1ff](https://github.com/boc-tothefuture/openhab-jruby/commit/9cab1ff24e2b2f87b0558385cd1c82d623547df6))

## [2.14.3](https://github.com/boc-tothefuture/openhab-jruby/compare/2.14.2...2.14.3) (2021-02-09)


### Bug Fixes

* multiple delayed triggers overwrite the previous triggers ([6f14429](https://github.com/boc-tothefuture/openhab-jruby/commit/6f14429113375907a39207bc25d75108897d61ca))

## [2.14.2](https://github.com/boc-tothefuture/openhab-jruby/compare/2.14.1...2.14.2) (2021-02-08)

## [2.14.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.14.0...2.14.1) (2021-02-05)


### Bug Fixes

* **number_item:** make math operations and comparisons work with Floats ([3b29aa9](https://github.com/boc-tothefuture/openhab-jruby/commit/3b29aa967f909e80400ed78406c680405b4974f4))

# [2.14.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.13.1...2.14.0) (2021-02-03)


### Features

* **logging:** append rule name to logging class if logging within rule context ([00c73a9](https://github.com/boc-tothefuture/openhab-jruby/commit/00c73a98de63eec31f7d2f24137e3581b6f66b60))

## [2.13.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.13.0...2.13.1) (2021-02-02)

# [2.13.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.12.0...2.13.0) (2021-02-02)


### Features

* **dimmeritem:** dimmeritems can now be compared ([aa286dc](https://github.com/boc-tothefuture/openhab-jruby/commit/aa286dcd8f55d7a7ecd84ed6b0e360cb52103a1c))

# [2.12.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.11.1...2.12.0) (2021-02-02)


### Bug Fixes

* return nil for items['nonexistent'] instead of raising an exception ([4a412f8](https://github.com/boc-tothefuture/openhab-jruby/commit/4a412f81daf46c86469d8badeac2327a6c1816d3))


### Features

* add Item.include? to check for item's existence ([1a8fd3a](https://github.com/boc-tothefuture/openhab-jruby/commit/1a8fd3aad11fb0549dc2c7308f26946ffb8e899c))

## [2.11.1](https://github.com/boc-tothefuture/openhab-jruby/compare/2.11.0...2.11.1) (2021-02-01)


### Bug Fixes

* **group:**  support for accessing triggering item in group updates ([6204f0a](https://github.com/boc-tothefuture/openhab-jruby/commit/6204f0a8f33e08abddcc130b46a2fe39c5f4bb49))

# [2.11.0](https://github.com/boc-tothefuture/openhab-jruby/compare/2.10.1...2.11.0) (2021-02-01)


### Features

* Add Duration.to_s ([b5b9c81](https://github.com/boc-tothefuture/openhab-jruby/commit/b5b9c8176f995ad996ac481c4c23c614bd5f54f7))

## 2.10.0
### Changed
- Library now released as a Ruby Gem

## 2.9.0
### Added
- Support OpenHAB Actions

## 2.8.1
### Fixed
- Fixed StringItem comparison against a string

## 2.8.0
### Added
- Support for accessing item metadata namespace, value, and configuration

## 2.7.0
### Added
- SwitchItem.toggle to toggle a SwitchItem similar to SwitchItem << !SwitchItem

## 2.6.1
### Fixed
- Race condition with `after` block
- Unknown constant error in certain cases uses `between` blocks

## 2.6.0
### Added
- `TimeOfDay.between?` to check if TimeOfDay object is between supplied range
### Fixed
- Reference in rules to TimeOfDay::ALL_DAY


## 2.5.1
### Fixed
- Corrected time of day parsing to be case insensitive
- Merge conflict

## 2.5.0
### Added
- `between` can be used throughout rules systems
#### Changed
- TimeOfDay parsing now supports AM/PM

## 2.4.0
### Added
- Support to allow comparison of TimeOfDay objects against strings
- Support for storing and restoring Item states

## 2.3.0
### Added
- Support for rule description

## 2.2.1
### Fixed
- `!` operator on SwitchItems now returns ON if item is UNDEF or NULL

## 2.2.0
### Added
- Support for thing triggers in rules

### Changed
- Updated docs to point to OpenHAB document for script locations

## 2.1.0 
### Added
- Timer delegate for 'active?', 'running?', 'terminated?'

## 2.0.1
### Fixed
- Logging of mod and/or inputs can cause an exception of they are nil
- Timers (after) now available inside of rules

### Changed
 - DSL imports now shared by OpenHAB module and Rules Module

## 2.0.0
### Added
- Timer delegate for `after` method that supports reschedule

### Changed
- **Breaking:** `after` now returns a ruby Timer delegate

## 1.1.0
### Added
- Added support for channels triggers to rules
 
### Changed
- Fixed documentation for changed/updated/receive_command options

## 1.0.0
### Changed
- **Breaking:** Changed commanded method for rules to received_command

## 0.2.0
### Added
- Ability to execute rules based on commands sent to items, groups and group members
- Ability to send updates from item objects

### Changed
- Fixed documentation for comparing dimensioned items against strings

## 0.1.0
### Added
- Support for item updates within rules languages
### Changed
- Installation instructions to specify using latest release rather than a specific version

## 0.0.1 
- Initial release
