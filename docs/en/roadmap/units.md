# Unit Ideas

## Wi‑Fi relay
- Based on esp8266 in a standard mechanical and DIN‑rail form factor; ideally also reflash Sonoff relays for the same purpose.

## Trigger on esp8266
- State switcher, the simplest input device into an MQTT broker — literally a button.

## Pipeline trigger on esp8266
- Sequential presses activate a new stage or stages of some tasks each time; must have an RGB LED to indicate the currently running task. Linear and cyclic modes.

## Action handler
- Scheduling actions with the ability to cancel.
- The main action is applied after a specified delay.
- While this delay is running, the action can be canceled.

## Wi‑Fi module for Flipper based on esp32
- Control anything that can be controlled via MQTT and receive data from the outside, with the ability to receive notifications, etc.
- Connect to Wi‑Fi only to send messages; this will save the Flipper's battery a lot.

## Hotkey desktop application in Go
- Tracking hotkeys, like the next item, but without low‑level interception.

## Hotkey sniffer on esp8266
- With switching between several `type-c` devices: 1 input from the keyboard and 3 or 4 outputs. Intercepts the stream of symbols from the keyboard and sends it to the input of some device or a series of devices; also allows switching between devices via hotkeys — a simple KVM switch. Essentially allows you to control some infrastructure without a computer.

## esp32 with camera
- For very cheap monitoring of anything — snapshots on demand.

## esp8266 microclimate station on bme280 and mh-z19b
- A very compact device for measuring humidity, temperature, pressure and CO2. For outdoor use, you can simply remove the CO2 sensor.

## Reflashable Sonoff ready‑made devices
- Can replace many of the things listed here; factory housing is a huge bonus.

## Segment picker in Go
- An application that creates a picker around the cursor, where you select a segment by moving the mouse in that direction.

## Fan with adjustable thrust vector
- A regular 120 mm cooler, but so that its direction can be adjusted using some motors.

## Mini scales
- Load cell.
- Two plates should come out of the device between which you can measure force.