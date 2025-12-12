# Want to contribute?

## Repositories

::::tip
You can find all `core` repositories on the [Repository map](/en/development-pepeunit/maps).
::::

::::tip
The main development platform is [GitLab](/en/definitions#gitlab). To register, contact [@w7a8n1y4a](https://t.me/w7a8n1y4a). All `core` repositories have mirrors on [GitHub](/en/definitions#github) to make it easier for [Users](/en/development-pepeunit/mechanics/roles#user) to create `issues`.

Each development repository contains a `Makefile` and a [readme.md](/en/definitions#readme-md) with important notes about how the code works.
::::

## TBD

The [Pepeunit](/en/conception/overview) repositories follow the `TBD` development methodology.

::::info
`Trunk Based Development (TBD)` is a development methodology where the whole team works in a single main [branch](/en/definitions#git-branch) `master`, and any auxiliary [branches](/en/definitions#git-branch) like `feature/best_feature_name` live for a strictly short time (`hours or days`). All changes are integrated frequently, and the main [branch](/en/definitions#git-branch) is kept ready for release.

`TBD` also implies using `feature flags (FF)` to enable and disable functionality in deployed instances.

This approach significantly speeds up development compared to `Git Flow`, reduces merge conflicts and increases code stability.
::::

## Commit naming convention

::::info
The commit naming convention follows [COMMITLINT example](https://www.commitvalidator.dev/) and helps quickly understand the essence of each change, improving the clarity of the development history.
  
Key benefits:
- Improves readability and structure of [Git](/en/definitions#git) history
- Simplifies searching for specific changes and analyzing root causes of issues

A unified naming style facilitates collaboration under the `TBD` methodology and speeds up code review.
::::

Examples of [commit](/en/definitions#git-commit) messages:
1. `feat(unit_service): add new function`
2. `fix(tests, unit_service): hotfix logic create UnitNode`
3. `refactor(permission_service): add new permission, rest, gql and mutatuion for creator UnitNode`
4. `resolve(conflicts): resolve`
5. `ci(Dockerfile): change packages`

::::danger
[Commits](/en/definitions#git-commit) that do not follow this format will not be accepted in `MR`.
::::


