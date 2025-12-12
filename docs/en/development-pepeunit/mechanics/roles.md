# User roles and Unit capabilities

## Roles

::::tip What is the purpose of `User` roles in the system?
The `User` role affects their capabilities when using a [Pepeunit](/en/conception/overview) instance, as well as how they interact with [RepositoryRegisty](/en/definitions#repositoryregistry), [Repo](/en/definitions#repo), [Unit](/en/definitions#unit) and [UnitNode](/en/definitions#unitnode) entities.
::::

### Unit Developer

The `Unit Developer` is the creator of [Git](/en/definitions#git) repositories in [GitLab](/en/definitions#gitlab) or [GitHub](/en/definitions#github). By using [RepositoryRegisty](/en/definitions#repositoryregistry) for their own purposes, they indirectly interact with [Pepeunit](/en/conception/overview) via their code, which is used by `Users` in the form of [RepositoryRegisty](/en/definitions#repositoryregistry), [Repo](/en/definitions#repo) and [Unit](/en/definitions#unit) entities.

::::tip Capabilities of a `Unit Developer`
- Can modify [Git](/en/definitions#git) repositories in [GitLab](/en/definitions#gitlab) or [GitHub](/en/definitions#github)
::::

### User

The `User` is a person registered in a [Pepeunit](/en/conception/overview) instance.

::::tip Capabilities of an ordinary `User`
- Can create [RepositoryRegisty](/en/definitions#repositoryregistry), [Repo](/en/definitions#repo), [Unit](/en/definitions#unit) and [UnitNode](/en/definitions#unitnode)
- Can see all [RepositoryRegisty](/en/definitions#repositoryregistry) records, including private ones
- Cannot create a [Repo](/en/definitions#repo) from a private [RepositoryRegisty](/en/definitions#repositoryregistry) without specifying [access credentials](/en/user/git-repository/create-repository-registry#access-to-a-private-repository)
- Can access entities whose [visibility level](/en/development-pepeunit/mechanics/visibility) is `Public`, `Internal` or `Private` (if [permission](/en/development-pepeunit/mechanics/permission) is granted)
::::

### Admin

The `Administrator` is the owner acting as a moderator, with full control over the [Pepeunit](/en/conception/overview) instance.

::::tip Capabilities of an `Administrator`
- Block `Users` who violate the terms of use of the instance
- View all [RepositoryRegisty](/en/definitions#repositoryregistry), [Repo](/en/definitions#repo), [Unit](/en/definitions#unit) and [UnitNode](/en/definitions#unitnode) entities; their interaction capabilities are equivalent to those they would have if appropriate [visibility](/en/development-pepeunit/mechanics/visibility) were granted
- Cannot obtain [encrypted](/en/development-pepeunit/mechanics/cipher) data directly through [Pepeunit](/en/conception/overview), but has the technical ability to decrypt any [encrypted](/en/development-pepeunit/mechanics/cipher) information in the instance
::::

### Bot

An external agent — a regular internet `User` or any program that has not gone through the authorization stage.

::::tip Capabilities of an external agent
- Can view all public records from [RepositoryRegisty](/en/definitions#repositoryregistry)
- Can interact only with entities whose [visibility level](/en/development-pepeunit/mechanics/visibility) is `Public`
::::


