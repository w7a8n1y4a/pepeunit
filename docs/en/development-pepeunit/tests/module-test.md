# Module tests - Backend

Module tests check individual parts of the [Backend](/deployment/dependencies/backend) without a database, a broker or a network. They run in seconds, so they run on every commit. Coverage is still small.

## Running

You can run module testing with the command:
```bash
make test-module
```
or directly:
```bash
uv run pytest app -v
```

The tests live next to the code, in `test_*.py` files inside `app/`. Pytest stops at the first failure (`--maxfail=1`).

To run the tests on every commit, copy `.pre-commit-config.example.yaml` to `.pre-commit-config.yaml`: before a commit, `Ruff` (check and formatting) and `make test-module` will run. Manually: `pre-commit run --all-files`.

## What is checked

File | What it checks
-- | --
`app/services/auth/test_auth_service.py` | `JwtAuthService`: parsing of `User`, `Unit` and `Backend` tokens, an expired and an invalid token, a blocked agent, an unknown type. `TgBotAuthService`: login by `telegram_chat_id`, a blocked and a not found `User`
`app/services/auth/test_authorization_service.py` | `AuthorizationService`: agent types and [roles](/development-pepeunit/mechanics/roles) (`Owner` includes `Admin`, `Admin` includes `User`, `Admin` is not `Owner`), the creator and the `Unit` as owners, `Public`, `Internal` and `Private` [visibility](/development-pepeunit/mechanics/visibility), list restrictions by [permissions](/development-pepeunit/mechanics/permission)
`app/services/auth/test_challenge.py` | `ChallengeService`: check of the `ML-DSA-87` public key, one-time use of the `challenge`, a wrong signature, the domain and the lifetime, see [Key login](/development-pepeunit/mechanics/authentication)
`app/configs/test_error_codes.py` | The error code catalog: the `/error_codes` route, the `PUER` prefix in the error text, each entity has its own code domain, `Python` and `Golang` ([DataPipe](/deployment/dependencies/datapipe)) codes are unique, every declared code is used
