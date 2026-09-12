# Integration tests

::::tip Why is this needed?
A run on a live instance checks the main [Backend](/en/deployment/dependencies/backend) scenarios. The log shows what works, and that log can be attached to an `issue`
::::

## Run

Available only to an [Administrator](/en/development-pepeunit/mechanics/roles#admin).

1. Click the `Domain` node on the home page
1. Click `Integration Tests`
1. In [Operation Tasks](/en/user/operation-task/operation-tasks) wait for `Success` or `Error`

The same run is available in the [Telegram Bot](/en/definitions#telegram-bot) via the `/control` command. There is no cooldown between runs. While tests are running, the public instance state shows `Running`.

## Result

In [Operation Tasks](/en/user/operation-task/operation-tasks) open the `Integration Tests` row and the icon in the `Result` column. The `Task Result` modal shows the full `pytest` log; you can copy it.

The [Backend](/en/deployment/dependencies/backend) takes a short summary from the final line, for example `total 241, passed 231, skipped 10, failed 0, error 0 in 174.21s`. The success percentage `(passed + xpassed) / executed * 100` is written to the public instance state.

Status | Meaning
-- | --
`Running` | Still running
`Success` | `pytest` finished with exit code `0`
`Warning` | The task failed, but some tests passed
`Error` | The run failed or the percentage cannot be parsed

This status and percentage are visible to everyone: the `Tests` column in [Instances](/en/user/instance/instances), the `Identity` block in the instance card, and the `state.integration_tests_*` fields in `GET /pepeunit/api/v1/instances/current`. Trusted neighbors take the same state when polling.

::::info
If tests have not been run for a long time, the fields in `/current` are empty. Diagnosis needs a fresh run
::::

## How to attach to an issue

1. Copy the log from `Task Result`
1. Paste it into an `issue` in the relevant repository: [Backend](https://github.com/w7a8n1y4a/pepeunit_backend), [Frontend](https://github.com/w7a8n1y4a/pepeunit_frontend), [Documentation](https://github.com/w7a8n1y4a/pepeunit). The repository list is on the [map](/en/development-pepeunit/maps)

## Variables

The tests read [Backend ENV](/en/deployment/env-variables/backend). Disabled `PU_FF_*` flags remove the related scenarios from the run. `PU_TEST_INTEGRATION_CLEAR_DATA=False` keeps test data for manual inspection.

::::info
Defaults, ranges, and a console run are described in [Backend integration tests](/en/development-pepeunit/tests/integration-test)
::::
