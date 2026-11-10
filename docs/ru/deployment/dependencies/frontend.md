# Frontend

## Frontend в широком смысле

Два сервиса: `Frontend` и [Grafana](/deployment/dependencies/grafana). Вместе они дают [Пользователям](/development-pepeunit/mechanics/roles#user) доступ к [Backend](/deployment/dependencies/backend).

## Frontend-сервис

Веб-версия клиента Pepeunit. Образ `w7a8n1y4a/pepeunit`, контейнер `frontend`, исходники в [`pepeunit`](/development-pepeunit/maps). Клиент написан на `Flutter` и отдаётся как набор статических файлов. Порт в контейнере 80, на хосте 5292. Сам ничего не хранит и общается с [Backend](/deployment/dependencies/backend) по REST.

Те же исходники собираются в нативные приложения для `Android`, `iOS`, `Linux`, `macOS` и `Windows`. В `docker compose` они не входят, инстанс в них выбирается в разделе `Сеть`. Ссылки на сборки есть в клиенте: `Библиотека` → `О приложении`.

### Как клиент узнаёт свой инстанс

Адрес инстанса `make_env.py` собирает из файла настроек, а веб-клиент подключается к нему при загрузке. Если адрес пустой, клиент работает с тем сервером, с которого загружен.

Клиент и [Backend](/deployment/dependencies/backend) должны быть совместимы: этой версии клиента подходит `Backend` `1.5.x`.

### Кэширование

После обновления образа пользователь получает новую версию без очистки кэша.

:::info
[Переменные окружения](/deployment/env-variables/frontend)
:::
