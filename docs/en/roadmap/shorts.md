# Ideas for YouTube Shorts

## 1. Disposable IoT devices

> IoT is seriously sick, and here is why

> This is a dividing head, a useful thing for a mill operator

> After 6 years, only this photo remains from the original schematic

> Its code was written the way embedded developers like it — packed with hardcoded values. To change any pin or parameter you have to recompile everything

> Projects like this appear by the thousands. They work, but repeating them is almost impossible; it is easier to build from scratch

> Pepeunit exists so IoT devices can not only be assembled, but also reproduced. Without archaeology.

## 2. Nobody needs your IoT project

> Why does nobody need your IoT project?

> Simple: your code cannot be used without changes and recompilation

> Every user has to become a developer just to compile the project

> Pepeunit breaks that model.

> The developer publishes their work on GitLab or GitHub

> Pepeunit looks at those repositories and lets you configure environments for specific devices

> The user only needs to take the prepared archive and flash the end device

> One developer is enough for many users

## 3. Your devices are too smart

> Why does extra logic inside actuators hurt IoT systems?

> Imagine a greenhouse: two temperature sensors and two actuators — a fan and a heater

> The fan and the heater read the sensors themselves and decide when to turn on

> To add a CO2 sensor to the greenhouse, you have to reflash the fan and the heater

> In Pepeunit, sensors publish data, actuators execute commands, and a controlling Unit does the analysis and control

> With this architecture, sensors and actuators become reusable in other projects. You only need to write a new controlling Unit

## 4. Which of these is an IoT device?

> Which of these is an IoT device: a laptop, a server, or a microcontroller?

> The correct answer is yes

> In Pepeunit, any device is a Unit program. Only the roles differ

> Microcontrollers measure values and drive relays

> A server runs complex logic around the clock: from Telegram bots to image processing

> A laptop is a great visualizer and control panel

> The hardware does not matter — the Unit inputs and outputs do
