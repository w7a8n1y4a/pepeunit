# Integration tests - Backend

Integration tests check the main scenarios of the application so that [Backend](/deployment/dependencies/backend) developers can change the codebase with confidence. The scenarios check only the `business logic`, not the work of the API layers.

The tests work with real [PostgreSQL](/deployment/dependencies/postgresql), [ClickHouse](/deployment/dependencies/clickhouse), [Redis](/deployment/dependencies/redis) and [EMQX](/deployment/dependencies/emqx): Backend services are called directly, while the `Unit` update, MQTT and [DataPipe](/deployment/dependencies/datapipe) scenarios also call the running Backend over HTTP.

:::danger
The tests create and delete instance data. Test users and entities get names with a hash of `PU_DOMAIN`, so that several instances do not overlap, and before a run such leftovers of the previous run are deleted. The tests temporarily replace the `Owner` role and return it to the previous owner at the end.
:::

## Running from the console

1. Configure the [Backend ENV variables](/deployment/env-variables/backend), including the variables below
1. Start the Backend together with DataPipe:
   ```
   make start
   ```
   The command builds DataPipe, starts it and the Backend on port `5291` with two workers. In Docker the Backend listens on port `5000` and is started through `gunicorn`, see [Backend](/deployment/dependencies/backend)
1. Run integration testing:
   ```
   make test-integration
   ```
   or directly:
   ```
   uv run pytest tests -v
   ```

The same run can be started by an [Admin](/development-pepeunit/mechanics/roles#admin) from the client or the Telegram Bot, see [operations](/development-pepeunit/mechanics/operations). The Backend runs `uv run pytest tests -v` in the background, and the full log arrives as a notification of type `IntegrationTests`. The public state of the instance updates the `state.integration_tests_*` fields in `GET /pepeunit/api/v1/instances/current`, so other instances see the result.

## What is checked

The files live in `tests/integration/services/` and run in numbered order. Pytest stops at the first failure.

File | Area
-- | --
`01_user_test.py` | Registration, [key](/development-pepeunit/mechanics/authentication) login, the `Admin` and `Owner` roles, blocking, Grafana login, Telegram binding
`02_repo_test.py` | [Repo](/development-pepeunit/mechanics/entities#repo): creation, commits, synchronization, private ones
`03_unit_test.py` | `Unit`: creation, names, [update](/development-pepeunit/mechanics/update-system) rules, [env.json](/development-pepeunit/mechanics/alg-env), firmware, MQTT commands and the check of MQTT permissions
`04_unit_io_test.py` | `UnitIO`, `Link`, DataPipe settings and data
`05_permission_test.py` | [Permission](/development-pepeunit/mechanics/permission) and [visibility](/development-pepeunit/mechanics/visibility)
`06_metrics_test.py` | Instance metrics for `Bot`, `User` and `Backend`
`07_grafana_test.py` | `Dashboard` and panels
`08_icon_test.py` | Icons of `User`, `Unit` and `UnitGroup`
`09_unit_group_test.py` | `UnitGroup`
`10_instance_settings_test.py` | Instance settings available only to the [Owner](/development-pepeunit/mechanics/roles#owner), limits, restart
`11_peer_test.py` | [Peer](/development-pepeunit/mechanics/federation): adding, trust, polling
`12_operation_task_test.py` | [Operations](/development-pepeunit/mechanics/operations)
`13_notification_test.py` | Notifications and their settings
`99_end_test.py` | Final check and cleanup

## Integration test variables

Variable | Default | Values | What it does
-- | -- | -- | --
`PU_TEST_INTEGRATION_CLEAR_DATA` | `True` | `True` / `False` | At the start of a run the test data is always deleted. If `True`, the same cleanup is done at the end. If `False`, the data stays, your own `Peer` is restored, and when [Grafana](/deployment/dependencies/grafana) is enabled, the demonstration `Dashboard` `test0_*` is kept for manual debugging
`PU_TEST_INTEGRATION_GITHUB_PUBLIC_REPO_URL` | `https://github.com/w7a8n1y4a/github_unit_pub_test.git` | `http` / `https`, not empty, `≤ 512` chars | Public GitHub test repository
`PU_TEST_INTEGRATION_GITLAB_PUBLIC_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test.git` | `http` / `https`, not empty, `≤ 512` chars | Public GitLab test repository
`PU_TEST_INTEGRATION_UNIVERSAL_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit.git` | `http` / `https`, not empty, `≤ 512` chars | Universal test Unit
`PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE` | `False` | `True` / `False` | Enables the private repository scenarios. With `True`, a non-empty `PU_TEST_INTEGRATION_PRIVATE_REPO_JSON` is required
`PU_TEST_INTEGRATION_PRIVATE_REPO_JSON` | empty | JSON, `≤ 8192` chars | An object with a `data` field: a list of repositories. Each has `link`, `username`, `pat_token`, `is_public` and `platform` (`Github` or `Gitlab`). Required and must be valid JSON when `PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE=True`
`PU_TEST_INTEGRATION_TELEGRAM_CHAT_ID` | empty | empty or chat id, `≤ 32` chars | Telegram chat id of the test [User](/development-pepeunit/mechanics/roles#user). An empty value substitutes a random id. The id must not belong to any other `User` of the instance, otherwise the test breaks at the early stages

## Flags and coverage

Scenarios of disabled features are removed from the run by `pytest` markers. The run looks at the `pu_ff_*` flags in [instance settings](/deployment/instance-settings) and at the test variables, so the result must be read together with the list of skipped scenarios:

Marker | Needed to run
-- | --
`grafana` | `pu_ff_grafana_integration_enable`
`datapipe` | `pu_ff_datapipe_enable`
`last_value` | `pu_ff_datapipe_enable` and `pu_datapipe_default_last_value_enable`
`telegram` | `pu_ff_telegram_bot_enable`
`prometheus` | `pu_ff_prometheus_enable`
`federation` | `pu_ff_federation_enable`
`notification` | `pu_ff_notification_enable`
`private_repo` | `PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE` and a non-empty list of repositories
