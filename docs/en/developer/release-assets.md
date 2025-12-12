# Compilation for different platforms

Due to the specifics of [Compilable](/en/definitions#compilable) programs, the way they are delivered to [Users](/en/development-pepeunit/mechanics/roles#user) differs from [Interpretable](/en/definitions#interpretable) ones. To avoid forcing the end [User](/en/development-pepeunit/mechanics/roles#user) to constantly compile the source code to obtain a binary, the [Git](/en/definitions#git) repository hosting platforms [GitLab](/en/definitions#gitlab) and [GitHub](/en/definitions#github) provide a release system.

Each release can include binary files with specific names; such pairs are typically called `assets`. [GitLab](/en/definitions#gitlab) and [GitHub](/en/definitions#github) allow you to obtain the mapping between an asset name and the URL to the binary file via their [API](/en/definitions#api).

::::info
Based on this mechanism, [Pepeunit](/en/conception/overview) can update [Compilable](/en/definitions#compilable) repositories automatically. The only requirement is that `assets` names must be consistent across different releases.
::::

::::warning
If the [Developer](/en/development-pepeunit/mechanics/roles#unit-developer) of a [Compilable](/en/definitions#compilable) [Unit](/en/definitions#unit) wants to add automatic update support in [Pepeunit](/en/conception/overview), they will have to compile and upload versions of their program for each platform to [GitLab](/en/definitions#gitlab) or [GitHub](/en/definitions#github). The asset name for the same platform must remain identical across all releases.
::::

## Example of good asset naming across releases

- `Release 1.0.0` – `linux-amd64` `macos`
- `Release 1.0.1` – `linux-amd64` `esp8266-generic` `macos`
- `Release 1.1.0` – `linux-amd64` `esp8266-generic` `macos`
- `Release 1.2.0` – `linux-amd64` `esp8266-generic`
- `Release 1.3.0` – `linux-amd64` `esp8266-generic` `macos`

Let’s consider how [Pepeunit](/en/conception/overview) behaves in this scenario for each platform: `linux-amd64`, `esp8266-generic`, and `macos`:

- for `linux-amd64` – the [Unit](/en/definitions#unit) will be updated normally for all versions
- for `esp8266-generic` – the [Unit](/en/definitions#unit) can be created starting from version `1.0.1`, and updates will then continue normally
- for `macos` – the [Unit](/en/definitions#unit) will be updated normally up to version `1.1.0`; automatic updates will then be interrupted but will resume starting from version `1.3.0`

## Example of bad asset naming across releases

- `Release 1.0.0` – `linux-amd64-1.0.0` `macos-one`
- `Release 1.0.1` – `linux-amd64-1.0.1` `esp8266-and-esp8266-generic` `macos-two`
- `Release 1.1.0` – `linux-amd64-1.1.0` `esp8266-generic` `macos-three`
- `Release 1.2.0` – `linux-amd64-1.2.0` `esp8266-and-esp8266-generic`

In this case, [Pepeunit](/en/conception/overview) will not be able to automatically update the [Unit](/en/definitions#unit). Only manual updates will work correctly; the platform-specific binary for each version will have to be downloaded manually.

## Summary

- If the structure of `assets` names differs between releases, only manual updates of the [Unit](/en/definitions#unit) are guaranteed to work correctly.
- If the structure of `assets` names is consistent within a [Unit](/en/definitions#unit), [Pepeunit](/en/conception/overview) can automatically build update URLs for [Compilable](/en/definitions#compilable) [Units](/en/definitions#unit) across versions.


