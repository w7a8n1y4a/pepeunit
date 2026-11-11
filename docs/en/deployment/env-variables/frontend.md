# Frontend

[Frontend](/deployment/dependencies/frontend) is a ready-made web application; it needs one variable.

Variable | Value | What is it for?
-- | -- | --
INSTANCE_URL | Built from `PU_SECURE`, `PU_DOMAIN`, `PU_APP_PREFIX` and `PU_API_V1_PREFIX`, for example `https://unit.example.com/pepeunit/api/v1/instances/current` | Address of the favorite instance of the client. It is optional. If empty, there is no favorite: the person picks one in the instance search

:::info
There is no need to set it by hand: the value is computed from the [settings file](/deployment/docker/deploy#settings-file). The client also knows a few instances out of the box and lists them in the instance search, so the choice is never empty. A local instance is added with the "Add locally" form. Native apps read the variable only if it was given at build time, so usually they have no favorite.

The container also takes the public address of the client from this variable for link previews (Open Graph tags): it is the host of `INSTANCE_URL`, and the client is assumed to be served at the root of that host. If the variable is empty, the preview has no `og:url`, and the image is a relative path.
:::
