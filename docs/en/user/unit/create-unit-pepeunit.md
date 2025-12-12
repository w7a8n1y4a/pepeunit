# Creating a Unit in Pepeunit

::::info Where to find it?
Open the [Repo](/en/definitions#repo) you need and find the green-highlighted `Create Unit` button.
::::

## Name of your Unit

Requirements:
1. Must be unique within the current instance
1. Length from `4` to `20` characters
1. Allowed characters: `a-z, A-Z, 0-9 and _.-`

::::info
Can be changed later
::::

## Visibility level

Choose a [visibility level](/en/development-pepeunit/mechanics/visibility).

::::info
Can be changed later
::::

## Auto-update block

There are two modes:

1. `Auto-update = True` — in this mode the [Unit](/en/definitions#unit) follows the [Repo](/en/definitions#repo) according to the [mass update flags](/en/user/git-repository/settings-repo.md).
1. `Auto-update = False` — manual update mode for the [Unit](/en/definitions#unit); requires you to specify a [branch](/en/definitions#git-branch) and a [commit](/en/definitions#git-commit).

## Platform selection for Compilable Repos

This option is available only for [Units](/en/definitions#unit) that are created from [Compilable](/en/definitions#compilable) [Repos](/en/definitions#repo). Each item in the selector is a ready-made binary version of the application that corresponds to a target [Tag](/en/definitions#git-tag).

[Read more about the pre-compilation system](/en/developer/release-assets).

::::info
These parameters are taken from the `assets` of [Git](/en/definitions#git) repository releases. [Unit Developers](/en/development-pepeunit/mechanics/roles#unit-developer) usually store precompiled versions of their applications there: compiled microcontroller firmware, `.exe` files, `.bin` files, etc. [GitLab](/en/definitions#gitlab) and [GitHub](/en/definitions#github) also include release archives there: `zip`, `tar`, and so on.
::::


