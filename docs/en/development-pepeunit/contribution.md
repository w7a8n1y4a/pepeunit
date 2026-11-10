# Want to contribute to development?


## Repositories
All `core` repositories are collected on the [Repository map](/development-pepeunit/maps).

The main development platform is GitLab. To register, contact [@w7a8n1y4a](https://t.me/w7a8n1y4a). All `core` repositories are mirrored on GitHub so that it is easier for [Users](/development-pepeunit/mechanics/roles#user) to leave `issues`.

The Client and Server repositories have a `Makefile`. List of commands: `make help`.

## What to run before a commit

Repository | What to check
-- | --
Server | `make lint` (`Ruff`) and `make test-module` ([module tests](/development-pepeunit/tests/module-test), also run by pre-commit), and before changing logic, the [integration tests](/development-pepeunit/tests/integration-test) as well
Client | `flutter test`: the tests compare the router with the screen tree, check the documentation (links, anchors, table of contents) and the error texts
Deploy | Run `python3 make_env.py` on the `.env.local.example` sample and make sure `.env` and the configs in `data/` are built

In CI, Server goes through the stages `build`, `security`, `deploy` and `test` (module, integration and two load tests), and on a tag also `tag`. Security checks: `trivy`, `osv-scanner`, `govulncheck` and `semgrep`. Client goes through `build`, `security` and `deploy_dev`.

## What to change together with the code

Some of the rules are checked by tests, some rely on agreement. A change is considered complete if it includes:

What changed | What to add in the same change
-- | --
A new route or cell in the client | A row in `lib/library/screen_tree.dart` and a tip file `tooltip/ru/<screen>.<cell>.md`
A new documentation article | An `.md` file and a row in `docs/ru/sidebar.json`, plus its translation in `docs/en/` and a row in `docs/en/sidebar.json`
A new Backend error code | A row in the client's `lib/locale/error_texts.dart`: the client test compares the file with the Backend table when the repositories lie side by side
A new entity, role or field in the API | An update to [entities](/development-pepeunit/mechanics/entities), [roles](/development-pepeunit/mechanics/roles) and the matching article of this section
A new instance setting or `pu_ff_*` flag | A row in [instance settings](/deployment/instance-settings) and in the markers of the [integration tests](/development-pepeunit/tests/integration-test#flags-and-coverage), if the flag enables scenarios
A new migration | A file in `alembic/versions/` (`alembic revision -m 'name'`, applied by `make migrate`), and for ClickHouse a file in `clickhouse/migrations/`

:::warning
The client works only with Backend versions from its compatibility window (`backendCompatible` in `lib/api/backend_version.dart`). If you change the API in an incompatible way, check this window.
:::

## TBD

Pepeunit repositories follow the `TBD` development methodology.

`Trunk Based Development (TBD)` means the whole team works in one main branch, `master`, while auxiliary branches `feature/best_feature_name` live for hours or days. Changes are integrated often, and the branch is always ready for release. Compared with `Git Flow`, this speeds up development and reduces merge conflicts.

`TBD` implies `feature flags (FF)` to turn functionality on and off in deployed instances. In Pepeunit these are the `pu_ff_*` flags in [instance settings](/deployment/instance-settings), changed by the [Owner](/development-pepeunit/mechanics/roles#owner).

## Commit naming convention

Commit names follow the [COMMITLINT example](https://www.commitvalidator.dev/) system: it keeps the Git history readable, makes it easier to find changes and speeds up code review.

Examples of commit names:
1. `feat(unit_service): add new function`
2. `fix(tests, unit_service): hotfix logic create UnitIO`
3. `refactor(permission_service): add new permission and rest for creator UnitIO`
4. `resolve(conflicts): resolve`
5. `ci(Dockerfile): change packages`
