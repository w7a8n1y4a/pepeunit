# Integration tests - Backend

::::tip What is the role of integration tests?
Integration tests verify the correctness of the main application scenarios. Thanks to these tests, [Backend](/en/deployment/dependencies/backend) developers can be confident in changes to the codebase
::::

::::warning
The test scenarios validate only the `business logic`; they do not attempt to verify how any specific API layer works
::::

The tests talk to an already running [Backend](/en/deployment/dependencies/backend). Names of created entities contain a hash of `PU_DOMAIN` so that several instances do not collide. Starting the run from the [Frontend](/en/deployment/dependencies/frontend) and inspecting the log are described in the [integration tests guide](/en/user/notification/integration-tests).

## Run from the console

1. Configure the [Backend ENV variables](/en/deployment/env-variables/backend), including the variables below
1. Start the [Backend](/en/deployment/dependencies/backend) using one of the commands below; the number of `workers` can be arbitrary:
   ```
   uvicorn app.main:app --host 0.0.0.0 --port 8555 --log-level info --workers 4
   gunicorn app.main:app -b 0.0.0.0:8555 --workers=4 -k uvicorn.workers.UvicornWorker --log-level=info
   ```
1. Run integration tests:
   ```
   make test-integration
   ```
   or directly:
   ```
   uv run pytest tests -v
   ```

An [Administrator](/en/development-pepeunit/mechanics/roles#admin) can start the same run with the `Integration Tests` button on the `Domain` node or with the `/control` command in the [Telegram Bot](/en/definitions#telegram-bot). The [Backend](/en/deployment/dependencies/backend) runs `uv run pytest tests -v` in the background and writes the progress to a [notification](/en/definitions#notification) of type `Integration Tests`.

## Integration testing variables

Variable | Default | Values | Purpose
-- | -- | -- | --
`PU_TEST_INTEGRATION_CLEAR_DATA` | `True` | `True` / `False` | Test data is always deleted at the start of a run. If `True`, the same cleanup runs at the end. If `False`, the data stays, the instance's own [Instance](/en/definitions#instance) is restored, and if [Grafana](/en/deployment/dependencies/grafana) is enabled a demo [Dashboard](/en/definitions#dashboard) `test0_*` is kept for manual debugging
`PU_TEST_INTEGRATION_GITHUB_PUBLIC_REPO_URL` | `https://github.com/w7a8n1y4a/github_unit_pub_test.git` | `http` / `https`, not empty, `≤ 512` chars | Public [GitHub](/en/definitions#github) test repository
`PU_TEST_INTEGRATION_GITLAB_PUBLIC_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/gitlab_unit_pub_test.git` | `http` / `https`, not empty, `≤ 512` chars | Public [GitLab](/en/definitions#gitlab) test repository
`PU_TEST_INTEGRATION_UNIVERSAL_REPO_URL` | `https://git.pepemoss.com/pepe/pepeunit/units/universal_test_unit.git` | `http` / `https`, not empty, `≤ 512` chars | Universal test [Unit](/en/definitions#unit)
`PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE` | `False` | `True` / `False` | Enables private repository scenarios. When `True`, a non-empty `PU_TEST_INTEGRATION_PRIVATE_REPO_JSON` is required
`PU_TEST_INTEGRATION_PRIVATE_REPO_JSON` | empty | JSON, `≤ 8192` chars | Object with a `data` field: a list of repositories. Each has `link`, `username`, `pat_token`, `is_public`, and `platform` (`Github` or `Gitlab`). Required and must be valid JSON when `PU_TEST_INTEGRATION_PRIVATE_REPO_ENABLE=True`
`PU_TEST_INTEGRATION_TELEGRAM_CHAT_ID` | empty | empty or a chat id, `≤ 32` chars | Chat id of the test [User](/en/development-pepeunit/mechanics/roles#user) in [Telegram](/en/definitions#telegram). An empty value substitutes a random id. The id from this variable must not belong to any other [User](/en/development-pepeunit/mechanics/roles#user) of the instance; otherwise the test fails at an early stage

::::warning
The `PU_FF_*` feature-flag set also affects coverage: scenarios for disabled features are removed from the run
::::

::::warning
A run from the [Frontend](/en/deployment/dependencies/frontend) or the [Telegram Bot](/en/definitions#telegram-bot) creates a [notification](/en/definitions#notification): the full `pytest` log opens from the `Integration Tests` row, and the public instance state updates the `state.integration_tests_*` fields in `GET /pepeunit/api/v1/instances/current`. The log can be [attached to an issue](/en/user/notification/integration-tests#how-to-attach-to-an-issue)
::::
