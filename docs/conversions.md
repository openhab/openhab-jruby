<!-- 
# @title Rule Conversions
# @description Some examples in converting your openHAB rules from other scripting languages to JRuby Scripting
 -->

# Conversion Examples

## JSScripting

```java
var email = "juliet@capulet.org"

rules.JSRule({
  name: "Balcony Lights ON at 5pm",
  description: "Light will turn on when it's 5:00pm",
  triggers: [triggers.GenericCronTrigger("0 0 17 * * ?")],
  execute: (event) => {
    items.getItem("BalconyLights").sendCommand("ON");
    actions.NotificationAction.sendNotification(email, "Balcony lights are ON");
  },
  tags: ["Balcony", "Lights"],
  id: "BalconyLightsOn"
});
```

Ruby

```ruby
EMAIL = "juliet@capulet.org"

rule "Balcony Lights ON at 5pm" do
  description "Light will turn on when it's 5:00pm"
  every :day, at: '5pm' # This can be written as: `cron "0 0 17 * * ?"` if preferred
  tags %w[Balcony Lights]
  uid "BalconyLightsOn"
  run do |event|
    BalconyLights.on
    NotificationAction.send_notification(EMAIL, "Balcony lights are ON")
  end
end
```

Terse rules

JRubyScripting supports {OpenHAB::DSL::Rules::Terse Terse syntax} as well as the normal,
more traditional syntax.

---
JS:

```java
// Basic rule, when the BedroomLight1 is changed, run a custom function
rules.when().item('BedroomLight1').changed().then(e => {
    console.log("BedroomLight1 state", e.newState)
}).build();
```

Ruby:

```ruby
# Basic rule, when the BedroomLight1 is changed, run a custom function
changed(BedromLight1) { |event| logger.info "#{event.item.name} state #{event.state}" }
```

---
JS:

```java
// Turn on the kitchen light at SUNSET
rules.when().timeOfDay("SUNSET").then().sendOn().toItem("KitchenLight").build("Sunset Rule","turn on the kitchen light at SUNSET");
```

Ruby:

```ruby
# Turn on the kitchen light at SUNSET
channel("astro:sun:home:set#event", name: "Sunset Rule", description: "turn on the kitchen light at SUNSET") { KitchenLight.on }
```

---
JS:

```java
// Turn off the kitchen light at 9PM and tag rule
rules.when().cron("0 0 21 * * ?").then().sendOff().toItem("KitchenLight").build("9PM Rule", "turn off the kitchen light at 9PM", ["Tag1", "Tag2"]);
```

Ruby:

```ruby
# Turn off the kitchen light at 9PM
every(:day, at: '9pm', name: "9PM Rule", description: "turn off the kitchen light at 9PM", tags: %w[Tag1 Tag2]) { KitchenLight.off }
```

---
JS:

```java
// Set the colour of the hall light to pink at 9PM, tag rule and use a custom ID
rules.when().cron("0 0 21 * * ?").then().send("300,100,100").toItem("HallLight").build("Pink Rule", "set the colour of the hall light to pink at 9PM", ["Tag1", "Tag2"], "MyCustomID");
```

Ruby:

```ruby
# Set the colour of the hall light to pink at 9PM and use a custom ID
every(:day, at: '9pm', id: "MyCustomID", name: "Pink Rule", description: "set the colour of the hall light to pink at 9PM", tags: %w[Tag1 Tag2]) { HallLight << "300,100,100" }
```

---
JS:

```java
// When the switch S1 status changes to ON, then turn on the HallLight
rules.when().item('S1').changed().toOn().then(sendOn().toItem('HallLight')).build("S1 Rule");
```

Ruby:

```ruby
# When the switch S1 status changes to ON, then turn on the HallLight
changed(S1, to: ON, name: "S1 Rule") { HallLight.on }
```

---
JS:

```java
// When the HallLight colour changes pink, if the function fn returns true, then toggle the state of the OutsideLight
rules.when().item('HallLight').changed().to("300,100,100").if(fn).then().sendToggle().toItem('OutsideLight').build();
```

Ruby:

```ruby
# When the HallLight colour changes pink, if the function fn returns true, then toggle the state of the OutsideLight
changed(HallLight, to: "300,100,100") { OutsideLight.toggle if fn }
```

---
JS:

```java
// When the HallLight receives a command, send the same command to the KitchenLight
rules.when().item('HallLight').receivedCommand().then().sendIt().toItem('KitchenLight').build("Hall Light", "");
```

Ruby:

```ruby
# When the HallLight receives a command, send the same command to the KitchenLight
received_command(HallLight) { |event| KitchenLight << event.command }
```

---
JS:

```java
// When the HallLight is updated to ON, make sure that BedroomLight1 is set to the same state as the BedroomLight2
rules.when().item('HallLight').receivedUpdate().then().copyState().fromItem('BedroomLight1').toItem('BedroomLight2').build();
```

Ruby:

```ruby
# When the HallLight is updated to ON, make sure that BedroomLight1 is set to the same state as the BedroomLight2
updated(HallLight) { BedroomLight2 << BedroomLight1.state }
```

## DSL

```java
rule "Snap Fan to preset percentages"
when Member of CeilingFans changed
then
  val fan = triggeringItem
  switch fan {
    case fan.state > 0 && fan.state < 25 : {
      logInfo("Fan", "Snapping {} to 25%", fan.name)
      sendCommand(fan, 25)
    }
    case fan.state > 25 && fan.state < 66 : {
      logInfo("Fan", "Snapping {} to 66%", fan.name)
      sendCommand(fan, 66)
    }
    case fan.state > 66 && fan.state < 100 : {
      logInfo("Fan", "Snapping {} to 100%", fan.name)
      sendCommand(fan, 100)
    }
    default: {
      logInfo("Fan", "{} set to snapped percentage, no action taken", fan.name)
    }
  }
end
```

Ruby

```ruby
rule 'Snap Fan to preset percentages' do
  changed CeilingFans.members
  run do |event|
    snapped = case event.state
              when 0..25 then 25
              when 25..66 then 66
              when 66..100 then 100
              else next # perhaps it changed to NULL/UNDEF
              end

    if event.item.ensure.command(snapped) # returns false if already in the same state
      logger.info("Snapping #{event.item.name} to #{snapped}")
    else
      logger.info("#{event.item.name} set to snapped percentage, no action taken.")
    end
  end
end
```

## Python

```python
@rule("Use Supplemental Heat In Office")
@when("Item Office_Temperature changed")
@when("Item Thermostats_Upstairs_Temp changed")
@when("Item Office_Occupied changed")
@when("Item OfficeDoor changed")
def office_heater(event):
  office_temp = ir.getItem("Office_Temperature").getStateAs(QuantityType).toUnit(ImperialUnits.FAHRENHEIT).floatValue()
  hall_temp = items["Thermostats_Upstairs_Temp"].floatValue()
  therm_status = items["Thermostats_Upstairs_Status"].intValue()
  heat_set = items["Thermostats_Upstairs_Heat_Set"].intValue()
  occupied = items["Office_Occupied"]
  door = items["OfficeDoor"]
  difference = hall_temp - office_temp
  degree_difference = 2.0
  trigger = occupied == ON and door == CLOSED and heat_set > office_temp and difference > degree_difference

  if trigger:
    events.sendCommand("Lights_Office_Outlet","ON")
  else:
    events.sendCommand("Lights_Office_Outlet","OFF")
```

Ruby

```ruby
rule "Use supplemental heat in office" do
  changed Office_Temperature, Thermostats_Upstairs_Temp, Office_Occupied, OfficeDoor
  run do
    trigger = Office_Occupied.on? &&
              OfficeDoor.closed? &&
              Thermostat_Upstairs_Heat_Set.state > Office_Temperature.state &&
              Thermostat_Upstairs_Temp.state - Office_Temperature.state > 2 | "°F"
    Lights_Office_Outlet.ensure << trigger # send a boolean command to a SwitchItem, but only if it's different
  end
end
```
