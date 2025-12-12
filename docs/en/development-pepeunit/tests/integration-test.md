# Integration tests - Backend

::::tip What is the role of integration tests?
Integration tests verify the correctness of the main application scenarios. Thanks to these tests, [Backend](/en/deployment/dependencies/backend) developers can be confident in changes to the codebase.
::::

::::warning
The test scenarios validate only the `business logic`; they do not attempt to verify how any specific API layer works.
::::

## Run

1. Configure additional [Backend ENV variables](/en/deployment/env-variables/backend):

    Backend variable | What it does
    -- | --
    `PU_TEST_INTEGRATION_CLEAR_DATA` | Deletes all test-related data at the beginning and the end of the test. If set to `False`, the data will not be deleted at the end of the test — useful for debugging.
    `PU_TEST_INTEGRATION_PRIVATE_REPO_JSON` | Points to private repositories in [GitLab](/en/definitions#gitlab) and [GitHub](/en/definitions#github). The structure of these repos is the same as for public ones; links to them are specified in `tests.integration.conftest.py`.
1. Start the [Backend](/en/deployment/dependencies/backend) using one of the commands below; the number of `workers` can be arbitrary:
   ```
   uvicorn app.main:app --host 0.0.0.0 --port 8555 --log-level info --workers 4
   gunicorn app.main:app -b 0.0.0.0:8555 --workers=4 -k uvicorn.workers.UvicornWorker --log-level=info
   ```
1. Run integration tests with:
   ```
   pytest tests -v
   ```


