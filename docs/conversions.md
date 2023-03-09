<!-- 
# @title Rule Conversions
# @description Some examples in converting your openHAB rules from other scripting languages to JRuby Scripting
 -->

# Conversion Examples

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
  trigger = occupied == ON && door == CLOSED && heat_set > office_temp && difference > degree_difference 

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
              Thermostate_Upstairs_Heat_Set.state > Office_Temperature.state &&
              Thermostat_Upstairs_Temp.state - Office_Temperature.state > 2 | "°F"
    Lights_Office_Outlet.ensure << trigger # send a boolean command to a SwitchItem, but only if it's different
  end
end
```
