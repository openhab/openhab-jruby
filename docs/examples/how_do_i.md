# @title How Do I...?

# How Do I...?

### Get the Thing Linked to an Item

```ruby
linked_thing = My_Item.thing
thing_uid = My_Item.thing.uid
```

### Get All Linked Things

An item can be linked to multiple things.

```ruby
My_Item.things.each do |thing|
  logger.info("Thing: #{thing.uid}")
end
```

## Groups

### Get the Members or All Members of a Group

```ruby
# direct members
gTest.members

# direct members and all their descendents
gTest.all_members
```

### Intersection of Two Groups

Group members work like a [Ruby array](https://ruby-doc.org/core-2.6/Array.html) 
so you can use `&` for intersection, `|` for union, and `-` for difference.

```ruby
curtains_in_family_room = gFamilyRoom.members & gCurtains.members
```

### Iterate Over Members of a Group

```ruby
gTest.members.each do |item|
  # process item
end

# Iterate over all members, including members of members
gTest.all_members.each do |item|
  # process item
end
```

### Filter Members of a Group

```ruby
members_that_are_on = gTest.members.select(&:on?)

# exclude state
members_that_are_not_on = gTest.members.reject(&:on?)

# Filter with code:
high_temperatures = gTemperatures.members.select(&:state?).select { |item| item.state > 30 | '°C' }
```

See [Accessing elements in a Ruby array](https://ruby-doc.org/core-2.6/Array.html#class-Array-label-Accessing+Elements).

### Get a sorted list of Group members matching a condition

```ruby
sorted_items_by_battery_level = gBattery.members
                                        .select(&:state?) # only include non NULL / UNDEF members
                                        .select { |item| item.state < 20 } # select only those with low battery
                                        .sort_by(&:state) 
```

### Get a List of Values Mapped from the Members of a Group

```ruby
battery_levels = gBattery.select(&:state?) # only include non NULL / UNDEF members
                         .sort_by(&:state)
                         .map { |item| "#{item.label}: #{item.state}" } # Use item state default formatting
```

### Perform Arithmetic on Values from Members of a Group

```ruby
weekly_rainfall = gRainWeeklyForecast.members.sum(&:state)
```

## Rules

### Create a Rule

```ruby
rule 'my first rule' do
  received_command My_Switch, to: ON
  run do
    My_Light.on
  end
end
```

This applies to file-based rules. See {OpenHAB::DSL::Rules::Builder}

### Create a Rule with One Line of Code

```ruby
received_command(My_Switch, to: ON) { My_Light.on }
```

This applies to file-based rules. See {OpenHAB::DSL::Rules::Terse Terse Rules}

### Create a Rule in the Main UI

See [Creating Rules in the UI](docs/usage/ui-rules.md)

### Get the Triggering Item

```ruby
event.item
```

### Get the Triggering Item's Name

```ruby
event.item.name
```

### Get the Triggering Item's Label

```ruby
event.item.label
```

### Get the Triggering Item's State

```ruby
event.state
```

or

```ruby
event.item.state
```

```ruby
# Item can be compared against their state
if event.item.state == ON
  # do something
end
# or (preferable)
if event.item.on?
  # do something
end
```

### Get the Triggering Item's Previous State

```ruby
event.was
```

Example:

```ruby
if event.was.on?
  # do something
end
```

### Compare Triggering Item's State Against Previous State

```ruby
event.state > event.was
```

### Get the Received Command

```ruby
event.command
```

Example:

```ruby
if event.command.on?
  # do something
end
```

### Create a Member-of-Group Trigger

```ruby
rule 'Trigger by Member of' do
  changed gGroupName.members
  run do |event|
    logger.info "Triggered item: #{event.item.name}"
  end
end
```

### Run a Rule on Start Up

```ruby
rule 'initialize things' do
  on_load # This triggers whenever the script (re)loads
  run { logger.info 'Here we go!' }
end
```

### Use Multiple Triggers

```ruby
rule 'multiple triggers' do
  changed Switch1, to: ON
  changed Switch2, to: ON
  run { |event| logger.info "Switch: #{event.item.name} changed to: #{event.state}" }
end
```

When the trigger conditions are the same, the triggers can be combined

```ruby
rule 'multiple triggers' do
  changed Switch1, Switch2, to: ON
  run { |event| logger.info "Switch: #{event.item.name} changed to: #{event.state}" }
end
```

### Use Multiple Conditions

```ruby
rule 'multiple conditions' do
  changed Button_Action, to: ['single', 'double']
  run { |event| logger.info "Action: #{event.state}" }
end
```

### Create a Simple Cron Rule

```ruby
rule 'run every day' do
  every :day, at: '2:35pm'
  run { Amazon_Echo_TTS << "It's time to pick up the kids!" }
end
```

```ruby
rule 'run every 5 mins' do
  every 5.minutes
  run { logger.info 'openHAB is awesome' }
end
```

```ruby
rule 'Anniversary Reminder' do
  every '10-15' # Trigger on 15th of October at midnight
  run do
    things['mail:smtp:mymailthing'].send_mail('me@example.com', 'Anniversary Reminder!', 'Today is your anniversary!') 
  end
end
```

See {OpenHAB::DSL::Rules::Builder.every Every Trigger}

### Create a Complex Cron Rule

```ruby
rule 'cron rule' do
  cron '0 0,15 15-19 L * ?'
  run { logger.info 'Cron run' }
end
```

or an easier syntax:

```ruby
rule 'cron rule' do
  cron second: 0, minute: '0,15', hour: '15-19', dom: 'L'
  run { logger.info 'Cron run' }
end
```

See {OpenHAB::DSL::Rules::Builder.cron Cron Trigger}

### Use Rule Guards

```ruby
rule 'motion sensor' do
  updated Motion_Sensor, to: ON
  only_if { Sensor_Enable.on? } # Run rule only if Sensor_Enable item is ON
  not_if { Sun_Elevation.positive? } # and not while the sun is up
  run { LightItem.on }
end
```

See {OpenHAB::DSL::Rules::BuilderDSL#only_if only_if}, {OpenHAB::DSL::Rules::BuilderDSL#not_if not_if}

### Restrict Rule Executions to Certain Time of Day

```ruby
rule 'doorbell' do
  updated DoorBell_Button, to: 'single'
  between '6am'..'8:30pm'
  run { play_sound 'doorbell_chime.mp3' }
end
```

### Stop a Rule if the Triggering Item’s State is NULL or UNDEF

Use `next` within a file-based rule, because it's in a block:

```ruby
next unless event.item.state?
```

Use `return` within a UI rule:

```ruby
return unless event.item.state?
```

### Suppress Item State Flapping

Only execute a rule when an item state changed and stayed the same for a period of time. This method 
can only be done using a file-based rule.

```ruby
rule 'Announce pool temperature' do
  changed Pool_Temperature, for: 10.minutes # Only when temp is stable for at least 10 minutes
  only_if { Pool_Heater.on? } # And only when the pool heater is running
  run { say "The pool temperature is now #{Pool_Temperature.state}" }
end
```


## Use Actions

See [Actions](docs/usage/misc/actions.md)

### Publish an MQTT Message

```ruby
things['mqtt:broker:mybroker'].publish_mqtt('topic/name', 'payload')
```

### Send an Email

```ruby
things['mail:smtp:mymailthing'].send_mail('me@example.com', 'Subject', 'message body')
```

### Play Sound Through the Default Audio Sink

```ruby
play_sound 'sound_file.mp3'
```

### Execute a Command

```ruby
Exec.executeCommandLine('/path/to/program')
```

## Date/Time

### Use ZonedDateTime

```ruby
ZonedDateTime.now + 30.minutes
# or
30.minutes.from_now # Return a ZonedDateTime
```

### Convert ZonedDateTime to Ruby Time

```ruby
ZonedDateTime.now.to_time
```

### Convert Ruby Time to ZonedDateTime

```ruby
Time.now.to_zoned_date_time
```

### Work with LocalTime

```ruby
if Time.now > LocalTime.parse('7am')
  logger.info 'Wake up!'
end
```

```ruby
# The range can cross midnight
if Time.now.between?('10pm'..'5am')
  logger.info 'Sleep time'
end
```

See {OpenHAB::CoreExt::Java::LocalTime LocalTime}

### Work with MonthDay

```ruby
if MonthDay.now == MonthDay.parse('02-14')
  logger.info "Happy Valentine's Day!"
end
```

See {OpenHAB::CoreExt::Java::MonthDay MonthDay}

For more examples, see [Working With Time](../usage/misc/time.md)


### Get the UID of a Rule 

This applies to file-based rules:

```ruby
rule_obj = rule 'my rule name' do
  received_command My_Item
  run do
    # rule code here
  end
end

rule_uid = rule_obj.uid
```

### Get the UID of a Rule by Name

```ruby
rule_uid = rules.find { |rule| rule.name == 'This is the name of my rule' }.uid
```

### Enable or Disable a Rule by UID

```ruby
rules[rule_uid].enable
rules[rule_uid].disable
```

### Run a rule by UID

```ruby
rules[rule_uid].trigger
```

### Use a Java Class

```ruby
java_import java.time.format.DateTimeFormatter

formatter = DateTimeFormatter.of_pattern('yyyy MM dd')
```

```ruby
formatter = Java::JavaTimeFormat::DateTimeFormatter.of_pattern('yyyy MM dd')
```

See: [Calling Java from JRuby](https://github.com/jruby/jruby/wiki/CallingJavaFromJRuby)
