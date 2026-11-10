# Running a Unit on a device

A created [Unit](/user/unit/create-unit) has to be moved to the device by hand once. After that it updates itself: [Update system](/development-pepeunit/mechanics/update-system).

## Environment variables

`Units` → `Unit` → `Environment variables`. The cell exists only for the creator of the `Unit`. The `env.json` editor opens.

The [Unit developer](/development-pepeunit/mechanics/roles#unit-developer) has usually already set up the variables, but some must be filled with your own data, for example `WIFI_SSID` and `WIFI_PASS`. What each variable means is written in the README of the repository: the link to it is in `Summary` of the `Repo`.

Button | What it does
-- | --
`Save` | Writes the variables to the instance [encrypted](/development-pepeunit/mechanics/cipher)
`Reset` | Deletes the saved variables: what remains is what the [env.json generation algorithm](/development-pepeunit/mechanics/alg-env) returns

:::warning
Keys from [env_example.json](/developer/files/struct-env-example-json) must not be removed: with a missing variable `Save` returns an error.
:::

:::danger
Until you tap `Save`, `PU_SECRET_KEY` and `PU_ENCRYPT_KEY` are created anew each time `env.json` is issued: the archive and the next `Update environment` will give different keys. Tap `Save` before downloading the files, even if you changed nothing.:::

## Files for the device

`Units` → `Unit` → `Manage unit`. The set of files differs depending on the type of the program.

### Interpreted Unit

`Program archives` → `ZIP`, `TAR`, or `TGZ`. The archive holds the whole program, `env.json`, and `schema.json`.

### Compiled Unit

Two sets of files are needed:

1. `Platforms` → the link to the build for your platform, see [Compilation for different platforms](/developer/release-assets). The cell exists only for compilable `Unit`
1. `Program archives` → the archive. It holds only `env.json` and `schema.json`

Put the files from the archive next to the build so that the program can see them. More: [Archive structure](/developer/files/struct-archive-update).

## First run

Upload the files to the device and start it.

- Microcontrollers (`esp32`, `stm`): files go to `flash`, start with the `reset` button
- `Micropython`: the interpreter is installed on the device first
- Desktop programs: run the binary file or use the interpreter command

There is no single rule: the order of starting is described in the README of the repository.

When the `Unit` gets in touch, its state and version appear in `Unit` → `Information`, and its messages appear in `Manage unit` → `Logs`. If they did not appear, see [Managing a Unit](/user/unit/manage).
