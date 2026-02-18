# Unit Ideas

## Actors

Each Unit must have a set of ff_:
1. ff_ physical configuration — enabling/disabling sensors and actors
1. ff_ software features
1. ff_ power-saving mode type
1. ff_ connection loss handling type

### Button + Encoder

1. ff for encoder presence/absence
1. Press types:
    - single with a configured duration
    - double
    - triple
    - long
1. Debounce handling
1. Setting messages for each press type via env — a dedicated topic for this — a dedicated topic for the button
1. Dedicated topic per button press type — one, double, triple, long
1. Encoder rotation left/right — dedicated topic for encoder right/left

### Microclimate Station with bme280 and mh-z19b — esp8266
- Same concept as ds18b20, but publishes to separate topics: temperature, humidity, pressure, and CO2

### Screen + Encoder

1. ff_ for encoder connection
1. Dedicated topic for receiving a full frame
1. Dedicated topic for rendering text/partial frame by coordinates (N units can write to a single screen)
1. Topic for clearing the frame
1. Encoder sends data the same way as in the Button + Encoder unit; it must interact with the streaming Unit
1. The concept is that the device is dumb — it only receives images and sends encoder signals if an encoder is present
1. Joystick support (one or two) should be added in the future

### Video Streaming

1. CLI Unit in Python
1. Playback control via built-in menu for displays
1. Ability to skip video
1. Ability to remotely trigger conversion to text
1. Ability to pause
1. Ability to view video info: framerate and duration

### Segment Display + Encoder

1. Similar to OLED but with segments; may be better replaced with a larger OLED with esp32

### Notifications / Reminders

1. RGB LED — each notification has its own color
1. Must work in pair with a Python Unit

### Garage Unit

1. Plain Python
2. Absorbs all custom garage logic
3. N button topics, N actor topics, 1 screen output topic and 1 encoder input topic

### Game Unit

1. Similar to streaming, but designed for two players with data input
1. Lobby creation based on unique unit UUIDs and their names
1. The game must have an asset so that only coordinates are sent over streams

### esp32 with Camera

Must be paired with an additional service that can store snapshots, e.g. MinIO, specified simply in settings. Preferably sends data to MinIO directly; publishes a UUID or equivalent to the /pepeunit topic.

1. Operating modes
    - Snapshots on demand
    - Timelapse with and without power saving
1. Capture parameters
    - Resolution
    - Exposure, etc.

### Scales

Handheld scales using a load cell with a square stainless steel rod frame ~8×8 mm and special slots for convenient measurements.

1. Components
    - Load cell
    - 18650 battery
    - Screen
    - Encoder
1. Output type
    - Newtons
    - Grams
1. Operating modes
    - Manual — individual measurements
    - Dynamic — streaming values at a configured interval

## Control

### Hotkey App in Go
- Tracks hotkeys and sends a configured set of parameters

### Hotkey Sniffer on esp8266
- Switches between multiple `type-c` devices; 1 keyboard input and 3 or 4 outputs. Intercepts the keyboard character stream and forwards it to one or more devices; also allows switching between devices via hotkeys — a basic KVM switch. Effectively allows managing infrastructure without a PC. Screen for displaying the last pressed keys.

### Pipeline Trigger on esp8266
- Each sequential press activates a new stage or stages of a task; should have a color LED to indicate the current task's execution status. Linear and cyclic modes.

### Scheduler
- Server-side unit with a Telegram bot via polling
- Action scheduling with cancellation support
- The main action is applied after a configured delay
- During that delay the action can be cancelled

### WiFi Module for Flipper based on esp32
- Control of supported functions via MQTT and receiving external data, ability to receive notifications, etc.
- Connects to WiFi only for sending messages, which significantly saves the Flipper's battery

## Extensions

### Unit Bar

1. A power strip / network filter for a large number of Units with a built-in power supply
