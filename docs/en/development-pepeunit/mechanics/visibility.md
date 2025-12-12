# Visibility levels - Public, Internal and Private

::::tip What does the visibility level affect?
The `visibility level` of an entity determines who can obtain information about it and/or interact with it.
::::

Visibility level | State
-- | --
`Public` | Grants [access](/en/development-pepeunit/mechanics/permission) to everyone
`Internal` | Grants [access](/en/development-pepeunit/mechanics/permission) to the entity only for authorized [Users](/en/development-pepeunit/mechanics/roles.html#user) of the instance or for all [Unit](/en/definitions#unit) instances that belong to the instance
`Private` | Grants [access](/en/development-pepeunit/mechanics/permission) to the entity only for its creator and agents specified by the creator. Works within the instance.

::::danger
The [RepositoryRegisty](/en/definitions#repositoryregistry) entity is unique and has only two visibility types: `Public` and `Private`. Granting access to a `Private` entity works differently and is based on [access credentials](/en/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория) entered by [Users](/en/development-pepeunit/mechanics/roles.html#user).

The creator cannot grant access themselves; this is dictated by the `business logic` of this entity.
::::

## Capabilities of entity creators

The creator has `full control` over managing their entities.

### RepositoryRegistry
- Change their own [access credentials](/en/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория)
- View repository size
- Create a [Repo](/en/definitions#repo) based on a [RepositoryRegisty](/en/definitions#repositoryregistry)
- Update the [Git](/en/definitions#git) repository inside [Pepeunit](/en/conception/overview)
- Delete a [RepositoryRegisty](/en/definitions#repositoryregistry) if it has no related [Repo](/en/definitions#repo)

### Repo

- View distribution of [Unit](/en/definitions#unit) by versions
- Create [Unit](/en/definitions#unit) based on a [Repo](/en/definitions#repo)
- Update all related [Unit](/en/definitions#unit)
- Configure [Repo](/en/definitions#repo)
- Grant [permissions](/en/development-pepeunit/mechanics/permission)
- Delete a [Repo](/en/definitions#repo) if it has no related [Unit](/en/definitions#repo)

### Unit

- View information about the current version of a [Unit](/en/definitions#unit)
- View information about the state of a [Unit](/en/definitions#unit)
- Set [env.json](/en/definitions#env-json)
- Download `Firmware` and compiled packages
- Send update commands over [MQTT](/en/definitions#mqtt): `Firmware`, `Schema` and `Env`
- Configure a [Unit](/en/definitions#unit)
- Grant [permissions](/en/development-pepeunit/mechanics/permission)
- Delete a [Unit](/en/definitions#unit)

### UnitNode

- View state
- Set values with sending to `Input` via [MQTT](/en/definitions#mqtt)
- Create connections for `Input`
- Configure [UnitNode](/en/definitions#unitnode)
- Grant [permissions](/en/development-pepeunit/mechanics/permission)
- Manage all aspects of [DataPipe](/en/deployment/dependencies/datapipe)

## Capabilities of agents for visible entities

Agents have limited [access](/en/development-pepeunit/mechanics/permission) to foreign entities that they can see using the `visibility system`:

### RepositoryRegistry
- Change their own [access credentials](/en/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория)
- View repository size. Available for both `Private` and `Public` repositories regardless of [access credentials](/en/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория)
- Create a [Repo](/en/definitions#repo) based on a [RepositoryRegisty](/en/definitions#repositoryregistry). For `Public` — available to everyone; for `Private` — only if the [access credentials](/en/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория) have status `Valid`
- Update the [Git](/en/definitions#git) repository inside [Pepeunit](/en/conception/overview). For `Public` — available to everyone; for `Private` — only if the [access credentials](/en/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория) have status `Valid`

### Repo

- View distribution of [Unit](/en/definitions#unit) by versions
- Create [Unit](/en/definitions#unit) based on a [Repo](/en/definitions#repo)

### Unit

- View information about the current version of a [Unit](/en/definitions#unit)
- View information about the state of a [Unit](/en/definitions#unit)

### UnitNode

- View state
- Set values with sending to `Input` via [MQTT](/en/definitions#mqtt)
- Create connections for `Input`


