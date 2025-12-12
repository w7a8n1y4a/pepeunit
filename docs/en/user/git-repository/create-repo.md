# Creating a Repo

::::info Where to find it?
There are two ways:
1. On the instance main page, find the chip icon button in the top right corner
1. On the instance main page, find the search button in the top left corner. Select the `Registry` entity and use filters to find the one you need. Click the `Pick` button. After that, just click `Create Repo`
::::

## Choosing a RepositoryRegistry

It is enough to click `Pick` in the search modal window. If the [RepositoryRegisty](/en/definitions#repositoryregistry) you need is missing, you can create a new one by clicking the `Create Registry` button.

::::danger
This is set only once at creation time
::::

## Target branch

The `Target branch` is the default [Git branch](/en/definitions#git-branch) of the [Git](/en/definitions#git) repository, intended for correct update behavior and [Unit](/en/definitions#unit) creation. Usually it is `master`, `main` or `release`.

::::info
Can be changed later
::::

## Name of your Repo

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

## Compilable flag

Usually the meaning of this flag can be found in the repository [Readme](/en/definitions#readme-md) of the [Git](/en/definitions#git) repository.

Set the flag to `True` for [Compilable](/en/definitions#compilable) repositories and to `False` for [Interpretable](/en/definitions#interpretable) ones.

::::warning
The value of this flag will affect the [initial retrieval of deployment files](/en/user/unit/create-physic-unit#получение-фаилов-развертывания) for the [Unit](/en/definitions#unit)
::::

::::info
Can be changed later
::::


