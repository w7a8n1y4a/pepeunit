# Frontend

::::warning
Manual editing is usually not required; you typically only need to fill in the main variables because there is a [file that generates .env files for services](/en/deployment/docker/deploy#filling-the-primary-env-file).
::::

::::warning
The [Frontend](/en/deployment/dependencies/frontend) has no default values.
::::

Variable | Example | Purpose
-- | -- | --
`VITE_INSTANCE_NAME` | `example.com` | Used to generate links between different `Node` objects in the main graph
`VITE_SELF_URI` | `https://example.com/` | Used for the `og:url` and `og:image` tags in `index.html`
`VITE_BACKEND_URI` | `https://example.com/pepeunit/graphql` | Used to send [GQL](/en/definitions#gql) requests to the [Backend](/en/deployment/dependencies/backend)


