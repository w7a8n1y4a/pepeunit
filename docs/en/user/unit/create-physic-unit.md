# Creating a Unit physically

## Configuring the environment

Open the [Unit](/en/definitions#unit) modal window and click the green `Set Env Variable` button; you will see the variables that need to be filled in.

Usually, [Unit Developers](/en/development-pepeunit/mechanics/roles#unit-developer) preconfigure them for correct operation of the [Unit](/en/definitions#unit), but some of them, such as `WIFI_SSID` and `WIFI_PASS`, must be filled with your own values.

You can find hints about the functional purpose of each variable by clicking the remote repository link `Documentation Link`; there, [Unit Developers](/en/development-pepeunit/mechanics/roles#unit-developer) usually describe the meaning of each variable.

After you click `Update`, the variables you added will be saved.

::::info
Environment variables are stored in an [encrypted](/en/development-pepeunit/mechanics/cipher) form.
::::

::::warning
The `reset` button allows you to reset the variables to the state provided by the [Unit Developer](/en/development-pepeunit/mechanics/roles#unit-developer). This state is the result of the [env generation algorithm](/en/development-pepeunit/mechanics/alg-env).
::::

::::danger
Until you click `Update`, the [system variables](/en/developer/files/struct-env-example-json) with the `PU_` prefix will be regenerated every time the variables are requested. After clicking `Update` they become fixed.
::::

## Getting deployment files

Depending on whether your [Repo](/en/definitions#repo) is [Compilable](/en/definitions#compilable) or not, the process of obtaining files will differ:

### Compilable Repo

You need to download two components of your future [Unit](/en/definitions#unit):

1. The compiled part from the `Compiled Firmware Platforms` tab, which contains links to [platforms](/en/developer/release-assets) for the current [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) of the [Unit](/en/definitions#unit).
1. An [archive](/en/developer/files/struct-archive-update) from the `Firmware with env.json and schema.json` tab.

You must place the files from the [archive](/en/developer/files/struct-archive-update) in the same directory as the [platform](/en/developer/release-assets) you selected so that they can see each other.

### Interpretable Repo

It is enough to download the [archive](/en/developer/files/struct-archive-update) from the `Firmware with env.json and schema.json` tab — it will contain all the files you need. After extracting the [archive](/en/developer/files/struct-archive-update), you will be ready to move to the next stage.

::::info
For [Micropython](/en/definitions#micropython) you must first install the interpreter on the physical [Unit](/en/definitions#unit).
::::

## First deployment

Typically, you need to upload the files obtained in the previous step to your physical device and satisfy its startup conditions.

For microcontrollers such as `esp32, stm ...`, you need to upload the files into `flash` memory and start the device by pressing the `reset` button.

For `Desktop` applications it is usually enough to run the binary file or invoke the required file via the interpreter command.

::::warning
There cannot be a universal rule here, because [Units](/en/definitions#unit) can be very different. Usually [Unit Developers](/en/development-pepeunit/mechanics/roles#unit-developer) leave instructions on how to make the [Unit](/en/definitions#unit) work correctly in the repository [Readme](/en/definitions#readme-md) of the [Git](/en/definitions#git) project.
::::


