# Unit Ideas

## Simple Actors

### Notifications/Reminders
1. WS2812B RGB LED, a unique color for each notification
1. Should work in pair with a Python Unit

### Motion Sensors

1. Also known as presence sensors
1. Research available options

### 220V Grid Monitoring

1. Output to topics: Voltage, Current, Power, Frequency, minimum frequency, maximum frequency
1. Think about better ways to analyze frequency

### Meshtastic Adapter

1. Should convert Meshtastic to MQTT commands
1. Should convert MQTT to Meshtastic
1. Should plug into a server Unit via standard topics

### LED Strips

1. Control of RGB and regular strips

### Game Unit

1. Similar to streaming, but designed for two users with input
1. Lobby creation by unique unit UUIDs and their names
1. The game should have an asset so that only coordinates are transmitted via streams

## Complex Actors

### Diesel Heater

1. Status model
1. On/Off
1. Emergency shutdown
1. Possibly requires Unit duplication so that they know each other's status and duplicate the control

### ESP32 with Camera

Should be combined with an additional service that can store snapshots, e.g. MinIO, specified simply in settings. Preferably sends data to MinIO by itself, sends UUID or equivalent to the /pepeunit topic

1. Operating modes
    - Snapshots on demand
    - Timelapse with and without power saving
1. Shooting parameters
    - Resolution
    - Exposure, etc.

### Antenna Positioning

1. Based on stepper motors
1. Worm gears
1. Control should work both via Wi-Fi and via some other protocol, possibly better to build them on Meshtastic

### Scales

Handheld scales on a load cell with a frame in the shape of a square stainless steel rod ~8x8 mm with special slots for convenient measurements

1. Components
    - Load cell
    - 18650
    - Display
    - Encoder
1. Output type
    - Newtons
    - Grams
1. Operating modes
    - Manual — single measurements
    - Dynamic — streaming values at a set interval

### Mouse

Very difficult to make, at least a proper casting setup is needed

1. Mouse with modular design
1. Preferably a steel/titanium case
1. The mouse module itself in the default frame is potted in epoxy and is moisture/waterproof
1. The module is inserted into the mouse like a cartridge, ideally the sensor should be made the same way
1. The mouse is designed for total indestructibility

## Control

### Server Unit for Garage

1. Everything via TG bot
1. Integration with Meshtastic adapter
1. On/off by timer
1. Ability to block activation
1. Output of basic information to TG messages on schedule
1. Flexible on/off scenarios

### Meshtastic Control Remote

1. Without Wi-Fi or the ability to switch to this mode
1. Sending pre-defined commands via buttons
1. Sending commands
1. Possibly with a display for convenience
1. Ideally mounted on a phone via MagSafe + built-in battery

### Hotkey Sniffer on ESP8266
- With switching between multiple Type-C devices, 1 keyboard input and 3 or 4 outputs. Intercepts the character stream from the keyboard and forwards it to the input of a device or a series of devices, also allows switching between devices via hotkeys — a simple KVM switch. Essentially allows controlling infrastructure without a PC. Display for showing the last pressed keys.

### Pipeline Trigger on ESP8266
- Sequential presses each time activate a new stage or stages of tasks, should have a color LED to indicate the current task's execution. Linear and cyclic modes.

### Scheduler
- Server unit with a TG bot, via polling
- Planning actions with the ability to cancel
- The main action is applied after a set time
- While the time is running, the action can be cancelled

### Wi-Fi Module for Flipper Based on ESP32
- Control of what is possible via MQTT and receiving external data, ability to receive notifications, etc.
- Connects to Wi-Fi only for sending messages, which will greatly save the Flipper's battery

## Extensions

### Unit Bar

1. Power strip for a large number of Units with a power supply

## Garage Automation

- Fully autonomous system built on RPI
- All external communication via bots on polling
- Someday we'll give it an IP, but only when super stable internet is available at the cottage

### Main Elements

Number of Units | Purpose | Installation Location
-- | -- | --
N | Relay for lights via 220V floodlights | Outdoors
N | Relay for heaters at workstations | Garage
N | Relay for other types of heaters / fairy lights / pumps / loads | Everywhere
3 | Weather stations BME280 + MH-Z19B, outdoors can be without CO2 | House, garage, outdoors
N | Temperature sensors DS18B20 | Cellar, milling machine, lathe
N | OLED with encoders — info displays and on/off screens, max 5 FPS | Garage, House, Sauna?
1 | Diesel heater | Garage
1 | Server orchestration Unit: TG bot, on/off by timer and for a duration, ability to block activation, parameter output on boards on schedule, flexible scenarios | Server
N | Portable control remotes on Meshtastic | On the back of a phone
N | Motion sensors, preferably presence sensors, scenario triggers | Everywhere
N | 220V grid monitoring to know current and voltage | In garage and house electrical panels
4 | Antenna positioning | City, 2x Talagi and Garage
1 | Meshtastic adapter | House at the cottage

### Stages

1. 
