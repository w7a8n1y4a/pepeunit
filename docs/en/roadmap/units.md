# Unit ideas

Type | Name | Description
-- | -- | --
Adapter | Meshtastic <-> MQTT | Figure out the protocol. To avoid publishing the whole airwaves, an authorization based on the keys already built in must be devised, possibly based on aes256 encryption
Adapter | LoRa <-> MQTT | Figure out the protocol. A criterion for skipping the unneeded traffic must be devised
Adapter | ZigBee <-> MQTT | Figure out the protocol. The adapter must be a coordinator station. CC2652P - Ebyte E72-2G4M20S1E, RF-Star RF-BM-2652P2 or esp-idf + esp32c6, which would allow a gateway on 1 device. The main idea is that all traffic is parsed in python, and zigpy there helps turn it into a usable network that can be addressed. The logic itself moves entirely to the server python layer with a config
Actor | LED strips | Control of RGB and ordinary strips
Actor | LED notifications | An RGB WS2812B LED, with its own color for each notification
Sensor | Motion sensors | Need to study what exists. There are also presence sensors. Publishing events
Sensor | 220 mains monitoring | Voltage, Current, Power, Frequency, minimum frequency, maximum frequency. Peaks that count as events must be configured
Sensor | Hall sensor | Measure the magnitude of the magnetic field
Sensor | Microphone | Audio stream
Module | Game Unit | An analog of streaming, but designed for N users with data input. Creating lobbies by unique unit uuids and their names. The game must have an asset, so that only coordinates are passed through the streams
Module | Diesel heater | Status model, On/Off, Emergency shutdown, Duplication of Unit may be needed here, so that they know which of them is in which status. Duplication of Unit is mandatory
Module | ESP32 with camera | Must be able to work with an s3 bucket, by tokens. Snapshots on request, Timelapse with and without power saving. Setting the shooting parameters. Support for rotation through additional hardware
Module | Antenna positioning | Stepper motors, worm gears. The main wheels must have absolute-position magnetic encoders. The worm shafts must have safety clutches. Control by wifi + meshtastic/lora
Module | Scales | Handheld scales with a load cell and a frame in the form of a square stainless steel spike ~ 8x8 mm with special notches for convenient measurements. Load cell, screen, 18650, control encoder. Newtons/grams. Single/Streaming measurement
Module | Mouse | Modular. Preferably a steel / titanium body. The mouse module itself in a default frame is then potted in epoxy and is moisture and water proof. The electrical parts are inserted into the mouse like cartridges. The mouse is designed to be indestructible
Control | Lora/Meshtastic remote control | Sending pre-recorded commands. Screen, 18650, buttons. Ideally on the back cover of a phone via MagSafe
Control | Server Unit for the Garage | Tg Bot, integration with adapters. On/Off by timer. The ability to block switching on. Output of basic information into tg messages by time. Flexible on/off scenarios
Control | Hotkey sniffer | type-c (1 keyboard input and 3-4 outputs). Analyzes the stream of characters. Reacts to hotkeys. Sending pre-defined commands to topics and swapping devices (kvm).
Control | Pipeline trigger | Pressing it in sequence activates a new stage or stages of some tasks each time, there must be a colored LED to indicate the progress of the current task. Linear and cyclic modes
Control | Scheduler | Tg Bot. Planning actions with the ability to cancel. The main action is applied after a set time. While this time runs, the action can be canceled
Control | Wifi module for flipper | Input/Output. Better to devise a universal API for interaction
Extension | Unit Bar | 5v splitter

## Garage automation

- A fully autonomous system
- Based on a microcomputer with clickhouse support
- Communication with the outside world through polling

### Main elements

Number of Unit | Exists? | Purpose | Installation place
-- | -- | -- | --
N | Yes | 220 relay | Everywhere
3 | Yes | Weather stations bme280 + mz-h19b outdoors can be without co2 | House, garage, outdoors
N | Yes | Temperature sensors ds18b20 | Cellar, Milling shop, Lathe shop
N | Yes | OLED with encoders - information screens - remotes, 5 fps maximum | Garage, House, Sauna?
1 | No | Lora/Meshtastic adapter | Next to the Pepeunit server
N | No | Portable control remotes on Meshtastic/LoRa | On the back cover of a phone
4 | No | Antenna positioning | City, Garage, Intermediate
N | No | 220 mains monitoring | In the garage and house panels
N | No | Motion sensors | Everywhere indoors
N | No | Hall sensors | On doors
1 | No | Server Unit | Server
1 | No | Diesel heater | Garage
