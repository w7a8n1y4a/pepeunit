# Creating a Unit

A `Unit` is a device or a program created from a [Repo](/user/repo). It has its own version, environment, and token. Creating one requires signing in and at least one `Repo`.

`Units` → `Create unit`. Or `Repositories` → `Repo` → `Create unit`: then the `Repo` is already chosen.

Cell | What to set
-- | --
`Select repository` | The `Repo` the `Unit` is created from. The list is searched by address
`Name` | 4 to 20 characters: Latin letters, digits, `_`, `.`, `-`
`Visibility` | `Public`, `Internal`, or `Private`, `Internal` by default. See [Visibility](/development-pepeunit/mechanics/visibility)
`Branch` | The branch of the `Repo` the program is taken from
`Updates` | Program type, update mode, commit, and platform
`Create` | Creates the `Unit`

## Updates

In `Updates` you choose:

- Program type: `Compilable` or `Interpreted`. A compilable one needs a `Platform`
- Mode: `Auto-update` or `Manual`. With `Manual` you must choose a `Commit`
- For auto-update: take the latest commit of the branch or only tagged commits. A compilable `Unit` takes only tags

Defaults: interpreted, auto-update, tags only. How the version is chosen and when a `Unit` is updated: [Update system](/development-pepeunit/mechanics/update-system). All of this can be changed later in the `Settings` of the `Unit`.

## After creation

The `Unit` is created but does not work yet: it needs environment variables and a run on a device, see [Running a Unit on a device](/user/unit/create-physic-unit).

Pepeunit creates the `UnitIO` itself - inputs and outputs from `schema_example.json` of the version, see [Inputs and outputs](/user/unit/io).
