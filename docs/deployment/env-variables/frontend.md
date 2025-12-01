# Frontend

:::warning
Ручное заполнение обычно не требуется, нужно заполнить только основные переменные т.к. есть [файл генерации .env файлов для сервисов](/deployment/docker/deploy#заполнение-первичного-env-фаила)
:::

:::warning
У [Frontend](/definitions#frontend) нет значений по умолчанию.
:::

Переменная | Пример | Зачем нужна?
-- | -- | --
`VITE_INSTANCE_NAME` | `example.com` | Используется для генерации ссылок между разными `Node` основного графа
`VITE_SELF_URI` | `https://example.com/` | Используется для тегов `og:url` и `og:image` в `index.html`
`VITE_BACKEND_URI` | `https://example.com/pepeunit/graphql` | Используется для отправки [GQL](/definitions#gql) запросов к [Backend](/definitions#backend)
