<!--
# @title Testing Your Rules
# @description Instructions on how to write tests for your own openHAB automation rules with JRuby Scripting
-->

# Testing

`openhab-scripting` includes framework classes to allow you to write unit tests
for your openHAB rules written in JRuby. It loads up a limited actual openHAB runtime
environment. Because it is a limited environment, with no actual bindings or things,
you may need to stub out those actions in your tests. The autoupdate manager is
running, so any commands sent to items that aren't marked as `autoupdate="false"` will
update automatically.

## Usage

You must run tests on a system with an actual openHAB instance installed, with your
configuration. JRuby >= 10.0.0.1 must also be installed, though it's recommended you
use the same version of JRuby that openHAB is using internally.

- Install and activate JRuby (by your method of choice - chruby, rbenv, etc.).
- Either create an empty directory, or use `$OPENHAB_CONF` itself (the former
   is untested)
- Create a `Gemfile`, with the following contents (you can configure your actual
  openHAB Gemfile to point here, ensure both environments stay in sync):

```ruby
source "https://rubygems.org"

plugin "bundler-openhab-stub"

group :development do
  gem "rake", "~> 13.0", require: false
end

group :test do
  gem "rspec", "~> 3.11"
  gem "timecop"
end

group :openhab do
  gem "openhab-scripting", "~> 5.0"

  # include any other gems you want to use in your rules
end
```

- Run `bundle install`
- Run `bundle exec rspec --init`
- Edit the generated `spec/spec_helper.rb` to satisfy your preferences, and
 add:

```ruby
require "rubygems"
require "bundler"

Bundler.require(:default, :openhab, :test)

require "openhab/rspec"

# if you have any automatic requires setup in jrubyscripting's config,
# (besides `openhab`), you need to manually require them here
```

- Create some specs! An example of `spec/switches_spec.rb`:

```ruby
RSpec.describe "switches.rb" do
  describe "gFullOn" do
    it "works" do
      GuestDownlights_Dimmer.update(0)
      GuestDownlights_Scene.update(1.3)
      expect(GuestDownlights_Dimmer.state).to eq 100
    end

    it "sets some state" do
      rules["my rule"].trigger
      expect(GuestDownlights_Scene.state).to be_nil
    end

    it "triggers a rule expecting an event" do
      rules["my rule 2"].trigger(Struct.new(:item).new(GuestDownlights_Scene))
      expect(GuestDownlights_Scene.state).to be_nil
    end
  end
end
```

- Run your specs: `bundle exec rspec`

### Maintaining the test instance

The test harness reuses a `.karaf` directory in your project directory. To update
its copy of your openHAB installation add a `Rakefile`:

```ruby
require "openhab/karaf/tasks"

OpenHAB::Karaf::Tasks.new
```

The tasks default to `OpenHAB::RSpec::Configuration.karaf_path`. To override it
for the tasks, configure them with a block:

```ruby
OpenHAB::Karaf::Tasks.new do |tasks|
  tasks.karaf_path = ENV["OPENHAB_RSPEC_KARAF_PATH"]
end
```

This will add new Rake tasks:

```shell
bundle exec rake karaf:rebuild
bundle exec rake karaf:refresh
```

`karaf:rebuild` completely removes `.karaf` and creates a new clone from your
installed openHAB instance. Use it after upgrading openHAB or when you need a
fresh test environment. It builds the clone without starting the runtime.

`karaf:refresh` replaces only `.karaf/jsondb` and `.karaf/persistence` with fresh
copies from openHAB's userdata directory. This will update your test copy of
openHAB with changes to managed items, things, and the latest persisted data.

### Spec Writing Tips

- By default ruby files are looked for in `$OPENHAB_CONF/automation/ruby` and in `$OPENHAB_CONF/automation/jsr223`. You can override and/or append to this by setting the `openhab_automation_search_paths` RSpec configuration setting in your `spec_helper.rb`. This can be useful to add staging directory for testing your rules.

 ```ruby
RSpec.configure do |config|
  config.openhab_automation_search_paths += "/my/staging/directory"
end
 ```

- See {OpenHAB::RSpec::Helpers} for all helper methods available in specs.
- All items are reset to {NULL} before each spec.
- `on_load` triggers are _not_ honored. Items will be reset to {NULL} before
   the next spec anyway, so just don't waste the energy running them. You
   can still trigger rules manually.
- Other rule triggers, such as watchers, can be tested with
   {OpenHAB::Core::Rules::Rule#trigger trigger}.
- You can trigger channels directly with {OpenHAB::RSpec::Helpers#trigger_channel}.
- Timers aren't triggered automatically. Use the {OpenHAB::RSpec::Helpers#execute_timers}
   helper to execute any timers that are ready to run. The `timecop` gem is
   automatically included, so use `Timecop.travel(5.seconds)` (for example)
   to travel forward in time and have timers ready to execute. Note that this
   includes implicit timers created by rules that use the `for:` feature, as well
   as time-based rule triggers. Recurring triggers fire once per call and then
   advance to their next future occurrence, skipping missed occurrences.
   Item updates reschedule item-based time triggers; disabling or removing a rule
   cancels its pending triggers.
- Logging levels can be changed in your code. Setting a log level for a logger
   further up the chain (separated by dots) applies to all loggers underneath
   it.

```ruby
OpenHAB::Log.logger("org.openhab.core.automation.internal.RuleEngineImpl").level = :debug
OpenHAB::Log.gem_root.level = :debug
OpenHAB::Log.root.level = :debug
OpenHAB::Log.events.level = :info
```

- Differing from when openHAB loads rules, all rules are loaded into a single
   JRuby execution context, so changes to globals in one file will affect other
   files. In particular, this applies to ids for reentrant timers will now share
   a single namespace among all files.
- Some actions may not be available; you should stub them out if you use them.
   Core actions like {OpenHAB::Core::Actions#notify}, {OpenHAB::Core::Actions::Voice#say},
   and {OpenHAB::Core::Actions::Audio#play_sound} are stubbed to only log a message
   (at debug level).
- You may want to avoid rules from firing while setting up the proper state for
   a test. In that case, use the {OpenHAB::RSpec::Helpers#suspend_rules} helper.
- Item persistence is enabled by default using an in-memory store that only
   tracks changes to items.
- The {OpenHAB::RSpec::Helpers#install_addon} helper can be used to install an
   addon like `binding-astro` if you need to be able to create things from your
   rules. Note that the addon isn't actually allowed to start, just be installed to
   make type metadata from XML available.
- If you have any Things in your openHAB instance that take two minutes to come
  online due to missing type metadata, you can force them to initialize
  immediately by calling {OpenHAB::RSpec::Helpers#initialize_missing_thing_types}.
- You can add a `binding.irb` call in to a spec (or your rule file) to break
  execution at that point and allow you to explore the current state of things
  with a REPL.

## Configuration

To change the test instance location, set
`OpenHAB::RSpec::Configuration.karaf_path` before requiring `openhab/rspec`.
For example, in `spec/spec_helper.rb`, you can use an environment variable:

```ruby
require "openhab/rspec/configuration"

OpenHAB::RSpec::Configuration.karaf_path = ENV["OPENHAB_RSPEC_KARAF_PATH"]

require "openhab/rspec"
```

Then run `OPENHAB_RSPEC_KARAF_PATH=/path/to/test-instance bundle exec rspec`.
The environment variable is read by this example configuration; the harness
defaults to `.karaf` in the current working directory. Use the same configuration
in your `Rakefile` before creating the tasks to share the location.

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

```ruby
OpenHAB::Transform.compass("59 °")
OpenHAB::Transform.compass("30", param: "7")
OpenHAB::Transform::Ruby.compass("59 °")
```

They're loaded into a sub-JRuby engine, just like they run in openHAB.

## IRB

If you would like to use a REPL sandbox to play with your items,
create bin/console with the following contents, and then run it:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"

Bundler.require(:default, :openhab)

require "irb"

begin
  require "openhab/rspec"

  autorequires
  load_rules
  load_transforms
rescue => e
  puts e.backtrace
  raise
end

IRB.start(__FILE__)
```
