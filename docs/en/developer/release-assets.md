# Compiling for different platforms

A compiled program cannot simply be unpacked from a Git repository: it has to be built. So that a [User](/development-pepeunit/mechanics/roles#user) does not have to build it themselves, ready-made binary files are attached to GitLab or GitHub releases.

Files with arbitrary names can be attached to a release. Such name and link pairs are called assets. Pepeunit reads them through the GitLab and GitHub APIs on every Repo synchronization and matches a release with a Tag.

On this mechanism Pepeunit updates compiled Units automatically. For this to work, the [Developer](/development-pepeunit/mechanics/roles#unit-developer) must build the program for every platform and attach it to every release, and must not change the name of the same platform from release to release.

## How it works in Pepeunit

1. A compiled Unit works only with Tags, a commit without a Tag does not suit it
1. When a Unit is created, a platform is chosen: this is the asset name
1. Having found an asset with that name in the release of the needed version, Pepeunit sends the Unit a link to it in the [UPDATE](/developer/mqtt/default-mqtt-command#update-updatepepeunit) command
1. If the release has no such asset, the Unit is neither created nor updated

## Example of good asset naming between releases
- Release 1.0.0: linux-amd64, macos
- Release 1.0.1: linux-amd64, esp8266-generic, macos
- Release 1.1.0: linux-amd64, esp8266-generic, macos
- Release 1.2.0: linux-amd64, esp8266-generic
- Release 1.3.0: linux-amd64, esp8266-generic, macos

What happens for each platform:
- linux-amd64: the Unit is updated through all versions
- esp8266-generic: a Unit can be created starting from version 1.0.1, after that updates go as usual
- macos: the Unit is updated up to version 1.1.0, the update stops at version 1.2.0 and resumes from version 1.3.0

## Example of bad asset naming between releases
- Release 1.0.0: linux-amd64-1.0.0, macos-one
- Release 1.0.1: linux-amd64-1.0.1, esp8266-and-esp8266-generic, macos-two
- Release 1.1.0: linux-amd64-1.1.0, esp8266-generic, macos-three
- Release 1.2.0: linux-amd64-1.2.0, esp8266-and-esp8266-generic

Here the names change from release to release, so automatic update does not work. Only manual update remains: you will have to choose the platform for each version by hand.
