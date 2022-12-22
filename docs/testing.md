# @title Testing Your Rules

# Testing

`openhab-jrubyscripting` includes framework classes to allow you to write unit tests
for your openHAB rules written in JRuby. It loads up a limited actual openHAB runtime
environment. Because it is a limited environment, with no actual bindings or things,
you may need to stub out those actions in your tests. The autoupdate manager is
running, so any commands sent to items that aren't marked as `autoupdate="false"` will
update automatically.

## Usage

You must run tests on a system with an actual openHAB instance installed, with your
configuration. JRuby >= 9.3.8.0 must also be installed.

 * Install and activate JRuby (by your method of choice - chruby, rbenv, etc.).
 * Either create an empty directory, or use `$OPENHAB_CONF` itself (the former
   is untested)
 * Create a `Gemfile` with the following contents (or add to an existing one):
```ruby
source "https://rubygems.org"

group(:test) do
  gem "rspec", "~> 3.11"
  gem "openhab-jrubyscripting", "~> 0.1"
  gem "timecop"
end

group(:rules) do
  # include any gems you reference from `gemfile` calls in your rules so that
  # they'll already be available in the rules, and won't need to be
  # re-installed on every run, slowing down spec runs considerably
end
```
 * Run `gem install bundler`
 * Run `bundle install`
 * Run `bundle exec rspec --init`
 * Edit the generated `spec/spec_helper.rb` to satisfy your preferences, and
 add:
```ruby
require "rubygems"
require "bundler"

Bundler.require(:default, :test)

require "openhab/rspec"

# if you have any automatic requires setup in jrubyscripting's config,
# (besides `openhab`), you need to manually require them here
```
 * Create some specs! An example of `spec/switches_spec.rb`:
```ruby
RSpec.describe "switches.rb" do
  describe "gFullOn" do
    it "works" do
      GuestCans_Dimmer.update(0)
      GuestCans_Scene.update(1.3)
      expect(GuestCans_Dimmer.state).to eq 100
    end

    it "sets some state" do
      rules["my rule"].trigger
      expect(GuestCans_Scene.state).to be_nil
    end

    it "triggers a rule expecting an event" do
      rules["my rule 2"].trigger(Struct.new(:item).new(GuestCans_Scene))
      expect(GuestCans_Scene.state).to be_nil
    end
  end
end
```
 * Run your specs: `bundle exec rspec`

Bonus, if you want to play in a sandbox to explore what's available (either for
specs or for writing rules) via a REPL, run `bundle console`, and inside of that
run `Bundler.require(:test)`. It will first load up the openHAB dependencies,
and then load rules in, then drop you into IRB.

### Spec Writing Tips

 * By default ruby files are looked for in `$OPENHAB_CONF/automation/ruby` and in `$OPENHAB_CONF/automation/jsr223`. You can override and/or append to this by setting the `openhab_automation_search_paths` RSpec configuration setting in your `spec_helper.rb`. This can be useful to add staging directory for testing your rules.
 ```ruby
RSpec.configure do |config|
  config.openhab_automation_search_paths += "/my/staging/directory"
end
 ```
 * See {OpenHAB::RSpec::Helpers} for all helper methods available in specs.
 * All items are reset to {NULL} before each spec.
 * `on_load` triggers are _not_ honored. Items will be reset to {NULL} before
   the next spec anyway, so just don't waste the energy running them. You
   can still trigger rules manually.
 * Rule triggers besides item related triggers (such as cron or watchers)
   are not triggered. You can test them with {OpenHAB::Core::Rules::Rule#trigger trigger}.
 * You can trigger channels directly with {OpenHAB::RSpec::Helpers#trigger_channel}.
 * Timers aren't triggered automatically. Use the {OpenHAB::RSpec::Helpers#execute_timers}
   helper to execute any timers that are ready to run. The `timecop` gem is
   automatically included, so use `Timecop.travel(5.seconds)` (for example)
   to travel forward in time and have timers ready to execute. Note that this
   includes implicit timers created by rules that use the `for:` feature.
 * Logging levels can be changed in your code. Setting a log level for a logger
   further up the chain (separated by dots) applies to all loggers underneath
   it.
```ruby
OpenHAB::Log.logger("org.openhab.core.automation.internal.RuleEngineImpl").level = :debug
OpenHAB::Log.gem_root.level = :debug
OpenHAB::Log.root.level = :debug
OpenHAB::Log.events.level = :info
```
 * Sometimes items are set to `autoupdate="false"` in production to ensure the
   devices responds, but you don't really care about the device in tests, you
   just want to check if the effects of a rule happened. You can enable
   autoupdating of all items by calling {OpenHAB::RSpec::Helpers#autoupdate_all_items}
   from either your spec itself, or a `before` block.
 * Differing from when openHAB loads rules, all rules are loaded into a single
   JRuby execution context, so changes to globals in one file will affect other
   files. In particular, this applies to ids for reentrant timers will now share
   a single namespace among all files.
 * Some actions may not be available; you should stub them out if you use them.
   Core actions like {OpenHAB::Core::Actions#notify}, {OpenHAB::Core::Actions::Voice#say},
   and {OpenHAB::Core::Actions::Audio#play_sound} are stubbed to only log a message
   (at debug level).
 * You may want to avoid rules from firing while setting up the proper state for
   a test. In that case, use the {OpenHAB::RSpec::Helpers#suspend_rules} helper.
 * Item persistence is enabled by default using an in-memory store that only
   tracks changes to items.
 * The {OpenHAB::RSpec::Helpers#install_addon} helper can be used to install an
   addon like `binding-astro` if you need to be able to create things from your
   rules. Note that the addon isn't actually allowed to start, just be installed to
   make type metadata from XML available.

## Configuration

There are a few environment variables you can set to help the gem find the
necessary dependencies. The default should work for an OpenHABian install
or installation on Ubuntu or Debian with .debs. You may need to customize them
if your installation is laid out differently. Additional openHAB or Karaf
specific system properties will be set the same as openHAB would.

| Variable           | Default                 | Description                                                         |
| ------------------ | ----------------------- | ------------------------------------------------------------------- |
| `$OPENHAB_HOME`    | `/usr/share/openhab`    | Location for the openHAB installation                               |
| `$OPENHAB_RUNTIME` | `$OPENHAB_HOME/runtime` | Location for openHAB's private Maven repository containing its JARs |

## Transformations

Ruby transformations _must_ have a magic comment `# -*- mode: ruby -*-` in them to be loaded.
Then they can be accessed as a method on {OpenHAB::Transform} based on the filename:

```
OpenHAB::Transform.compass("59 °")
OpenHAB::Transform.compass("30", param: "7")
OpenHAB::Transform::Ruby.compass("59 °")
```

They're loaded into a sub-JRuby engine, just like they run in openHAB.

## IRB

If you would like to use a REPL sandbox to play with your items,
you can run `bundle console`. You may want to create an `.irbrc`
with the following contents to automatically boot things up:

```ruby
# frozen_string_literal: true

require "rubygems"
require "bundler"

Bundler.require(:default, :development, :test)

require "openhab/rspec"

launch_karaf
autorequires
set_up_autoupdates
load_rules
load_transforms
```
