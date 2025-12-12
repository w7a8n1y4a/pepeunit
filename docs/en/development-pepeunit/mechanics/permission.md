# Working with permissions

::::info What does granting permission mean?
A [User](/en/development-pepeunit/mechanics/roles.html#user) can find your entity via search and perform a number of actions described in the [capabilities of agents for visible entities](/en/development-pepeunit/mechanics/visibility#возможности-агентов-для-видимых-сущностеи).
::::

::::warning
The permission system works only for entities whose [visibility level](/en/development-pepeunit/mechanics/visibility) is `Private`.
::::

::::danger
Access to a `Private` [RepositoryRegisty](/en/definitions#repositoryregistry) is based on [access credentials](/en/user/git-repository/create-repository-registry#доступ-до-закрытого-репозитория) and ignores the system described below.
::::

## Creating a permission

1. Open the menu of the [Repo](/en/definitions#repo), [Unit](/en/definitions#unit) or [UnitNode](/en/definitions#unitnode) entity.
1. Click the `Permission` button.
1. You will see a list of agents that can interact with this entity.
1. To add a new agent, click `Pick Agent`.
1. Select the agent type: [User](/en/development-pepeunit/mechanics/roles#user) or [Unit](/en/definitions#unit).
1. Find the desired agent and click `add` next to it.

## Deleting a permission

1. Open the menu of the [Repo](/en/definitions#repo), [Unit](/en/definitions#unit) or [UnitNode](/en/definitions#unitnode) entity.
1. Click the `Permission` button.
1. You will see a list of agents that can interact with this entity.
1. To remove an agent, click `delete`.


