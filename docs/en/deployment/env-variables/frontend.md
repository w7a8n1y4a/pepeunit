# Frontend

[Frontend](/deployment/dependencies/frontend) is a ready-made web application; it needs one variable.

Variable | Value | What is it for?
-- | -- | --
INSTANCE_URL | Built from `PU_SECURE`, `PU_DOMAIN`, `PU_APP_PREFIX` and `PU_API_V1_PREFIX`, for example `https://unit.example.com/pepeunit/api/v1/instances/current` | Address of the instance the web client connects to. If empty, the client uses the server it was loaded from

:::info
There is no need to set it by hand: the value is computed from the [settings file](/deployment/docker/deploy#settings-file). Native apps do not read this variable; in them the instance is chosen manually.
:::
