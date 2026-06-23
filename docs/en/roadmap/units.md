# Unit ideas

Type | Name | Description
-- | -- | --
Adapter | Meshtastic <-> MQTT | Study the protocol. To avoid publishing the entire air, an authorization mechanism based on the existing keys needs to be designed, possibly using AES-256 encryption
Adapter | LoRa <-> MQTT | Study the protocol. A criterion for skipping unnecessary data needs to be designed
Adapter | ZigBee <-> MQTT | Study the protocol. The adapter must act as a station
Actuator | LED strips | Control RGB and regular LED strips
Actuator | LED notifications | WS2812B RGB LED, each notification has its own color
Sensor | Motion sensors | Need to study what options exist. There are also presence sensors. Event publishing
Sensor | 220V grid monitoring | Voltage, current, power, frequency, minimum frequency, maximum frequency. Need to configure peaks that will be treated as events
Sensor | Hall sensor | Measure magnetic field strength
Module | Game Unit | Similar to streaming, but designed for N users with input. Lobby creation by unique Unit UUIDs and their names. The game should have an asset so streams only transmit coordinates
Module | Diesel heater | Status model, On/Off, emergency shutdown. Unit duplication may be needed so they know which one is in which status. Unit duplication is mandatory
Module | ESP32 with camera | Must be able to work with an S3 bucket using tokens. Snapshots on request, timelapse with and without power saving. Shooting parameter setup. Rotation support through additional hardware
Module | Antenna positioning | Stepper motors, worm gears. The main wheels should have magnetic absolute-position encoders. Worm shafts should have safety clutches. Wi-Fi + Meshtastic/LoRa control
Module | Scales | Handheld scales on a load cell with a frame shaped like a square stainless steel rod, about 8x8 mm, with special slots for convenient measurements. Load cell, screen, 18650, control encoder. Newtons/grams. Single/streaming measurement
Module | Mouse | Modular. Preferably a steel / titanium enclosure. The mouse module itself is in a default frame, potted in epoxy, and moisture/waterproof. Electrical parts are inserted into the mouse like cartridges. The mouse is designed to be indestructible
Control | LoRa/Meshtastic control remote | Sending pre-recorded commands. Screen, 18650, buttons. Ideally mounted on the back cover of a phone through MagSafe
Control | Server Unit for garage | Tg Bot, adapter integration. On/Off by timer. Ability to block activation. Output basic information to Telegram messages on a schedule. Flexible on/off scenarios
Control | Hotkey sniffer | Type-C (1 keyboard input and 3-4 outputs). Analyzes the character stream. Reacts to hotkeys. Sends preconfigured commands to topics and swaps devices (KVM)
Control | Pipeline trigger | Each sequential press activates a new stage or stages of some tasks. It should have a colored LED to indicate execution of the current task. Linear and cyclic modes
Control | Scheduler | Tg Bot. Action scheduling with cancellation support. The main action is applied after a configured time. While this time is running, the action can be cancelled
Control | Wi-Fi module for Flipper | Input/Output. Better to design a universal API for interaction
Extension | Unit Bar | 5V splitter

## Garage automation

- Fully autonomous system
- Based on a microcomputer with ClickHouse support
- Communication with the outside world through polling

### Main elements

Number of Units | Exists? | Purpose | Installation location
-- | -- | -- | --
N | Yes | 220V relay | Everywhere
3 | Yes | BME280 + MZ-H19B weather stations; outside can be without CO2 | House, garage, outside
N | Yes | DS18B20 temperature sensors | Cellar, milling machine, lathe
N | Yes | OLED with encoders: information screens / remotes, max 5 fps | Garage, house, bathhouse?
1 | No | LoRa/Meshtastic adapter | Next to the Pepeunit server
N | No | Portable control remotes on Meshtastic/LoRa | On the back cover of a phone
4 | No | Antenna positioning | City, garage, intermediate
N | No | 220V grid monitoring | In garage and house electrical panels
N | No | Motion sensors | Everywhere indoors
N | No | Hall sensors | On doors
1 | No | Server Unit | Server
1 | No | Diesel heater | Garage
