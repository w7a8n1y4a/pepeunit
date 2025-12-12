import type { DefaultTheme } from 'vitepress'

export const pepeDescription =
  'Документация федеративной IoT платформы Pepeunit.'

export function nav(): DefaultTheme.NavItem[] {
  return [
    {
      text: 'Demo',
      link: 'https://unit.pepeunit.com'
    },
    {
      text: 'Docs',
      link: '/conception/overview',
      activeMatch: '/'
    }
  ]
}

export function sidebarGuide(): DefaultTheme.SidebarItem[] {
  return [
    {
      text: 'Концепция',
      collapsed: false,
      items: [
        { text: 'Обзор', link: '/conception/overview' },
        { text: 'Определения', link: '/definitions' }
      ]
    },
    {
      text: 'Развёртывание',
      collapsed: false,
      items: [
        { text: 'Схема взаимодействия сервисов', link: '/deployment/schema' },
        {
          text: 'Зависимости',
          collapsed: true,
          items: [
            { text: 'PostgreSQL', link: '/deployment/dependencies/postgresql' },
            { text: 'ClickHouse', link: '/deployment/dependencies/clickhouse' },
            { text: 'Redis', link: '/deployment/dependencies/redis' },
            { text: 'EMQX', link: '/deployment/dependencies/emqx' },
            { text: 'Backend', link: '/deployment/dependencies/backend' },
            { text: 'DataPipe', link: '/deployment/dependencies/datapipe' },
            { text: 'Frontend', link: '/deployment/dependencies/frontend' },
            { text: 'Grafana', link: '/deployment/dependencies/grafana' },
            { text: 'Nginx', link: '/deployment/dependencies/nginx' },
            { text: 'Prometheus', link: '/deployment/dependencies/prometheus' },
            { text: 'Logporter', link: '/deployment/dependencies/logporter' },
            { text: 'Loki', link: '/deployment/dependencies/loki' },
            { text: 'Promtail', link: '/deployment/dependencies/promtail' }
          ]
        },
        {
          text: 'Docker',
          collapsed: true,
          items: [
            { text: 'Установка Docker и Compose', link: '/deployment/docker/install-docker' },
            { text: 'Развёртывание', link: '/deployment/docker/deploy' },
            { text: 'Бэкапы и Обновление', link: '/deployment/docker/backup-update' },
            { text: 'Полезные команды', link: '/deployment/docker/commands' }
          ]
        },
        { text: 'Конфигурации Nginx', link: '/deployment/nginx' },
        {
          text: 'Переменные окружения',
          collapsed: true,
          items: [
            { text: 'Backend', link: '/deployment/env-variables/backend' },
            { text: 'DataPipe', link: '/deployment/env-variables/data-pipe' },
            { text: 'Frontend', link: '/deployment/env-variables/frontend' },
            { text: 'PostgreSQL', link: '/deployment/env-variables/postgresql' },
            { text: 'ClickHouse', link: '/deployment/env-variables/clickhouse' },
            { text: 'EMQX', link: '/deployment/env-variables/emqx' },
            { text: 'Grafana', link: '/deployment/env-variables/grafana' }
          ]
        },
        { text: 'Мониторинг', link: '/deployment/monitoring' }
      ]
    },
    {
      text: 'Руководство пользователя',
      collapsed: false,
      items: [
        {
          text: 'Управление Git Repository',
          collapsed: true,
          items: [
            { text: 'Создание RepositoryRegistry', link: '/user/git-repository/create-repository-registry' },
            { text: 'Создание Repo', link: '/user/git-repository/create-repo' },
            { text: 'Настройка Repo', link: '/user/git-repository/settings-repo' }
          ]
        },
        {
          text: 'Unit',
          collapsed: true,
          items: [
            { text: 'Создание Unit в Pepeunit', link: '/user/unit/create-unit-pepeunit' },
            { text: 'Создание физического Unit', link: '/user/unit/create-physic-unit' },
            { text: 'Обновление Unit', link: '/user/unit/update-unit' },
            { text: 'Настройка UnitNode', link: '/user/unit/settings-unit-node' },
            { text: 'Output->Input связи между UnitNode', link: '/user/unit/edge-unit-node' }
          ]
        },
        {
          text: 'DataPipe',
          collapsed: true,
          items: [
            { text: 'Настройка DataPipe', link: '/user/datapipe/datapipe' },
            { text: 'Примеры DataPipe', link: '/user/datapipe/example' },
            { text: 'Импорт данных в DataPipe', link: '/user/datapipe/import' }
          ]
        },
        {
          text: 'Grafana',
          collapsed: true,
          items: [
            { text: 'Создание Dashboard', link: '/user/grafana/create' },
            { text: 'Синхронизация с Grafana', link: '/user/grafana/sync' }
          ]
        }
      ]
    },
    {
      text: 'Разработчику Unit',
      collapsed: false,
      items: [
        { text: 'Алгоритм создания Unit', link: '/developer/alg-create-unit' },
        {
          text: 'Файлы',
          collapsed: true,
          items: [
            { text: 'Структура GIT репозитория', link: '/developer/files/struct-git-repo' },
            { text: 'schema_example.json', link: '/developer/files/struct-schema-example-json' },
            { text: 'schema.json', link: '/developer/files/struct-schema-json' },
            { text: 'env_example.json', link: '/developer/files/struct-env-example-json' },
            { text: 'env.json', link: '/developer/files/struct-env-json' },
            { text: 'pepeunit.toml', link: '/developer/files/struct-pepeunit-toml' },
            { text: 'readme.md', link: '/developer/files/struct-readme' },
            { text: '.gitignore', link: '/developer/files/struct-gitignore' },
            { text: '.pepeignore', link: '/developer/files/struct-pepeignore' },
            { text: 'Архив обновлений', link: '/developer/files/struct-archive-update' }
          ]
        },
        {
          text: 'Библиотеки Unit',
          collapsed: true,
          items: [
            { text: 'Pepeunit Framework', link: '/developer/libraries/framework' },
            { text: 'Micropython', link: '/developer/libraries/micropython' },
            { text: 'Golang', link: '/developer/libraries/golang' },
            { text: 'Python', link: '/developer/libraries/python' }
          ]
        },
        {
          text: 'MQTT Взаимодействие',
          collapsed: true,
          items: [
            { text: 'Стандартные MQTT команды Pepeunit', link: '/developer/mqtt/default-mqtt-command' },
            { text: 'Стандартные MQTT топики состояния', link: '/developer/mqtt/state-mqtt-send' },
            { text: 'Структура сообщений в MQTT топиках', link: '/developer/mqtt/struct-topic-messages' }
          ]
        },
        { text: 'Хранилище состояний Unit', link: '/developer/state-storage-unit' },
        { text: 'Компиляция для разных платформ', link: '/developer/release-assets' }
      ]
    },
    {
      text: 'Разработчику Pepeunit',
      collapsed: true,
      items: [
        { text: 'Карта репозиториев', link: '/development-pepeunit/maps' },
        {
          text: 'Механики',
          collapsed: true,
          items: [
            { text: 'Система Ролей', link: '/development-pepeunit/mechanics/roles' },
            { text: 'Система Видимости', link: '/development-pepeunit/mechanics/visibility' },
            { text: 'Система Доступов', link: '/development-pepeunit/mechanics/permission' },
            { text: 'Система Обновлений', link: '/development-pepeunit/mechanics/update-system' },
            { text: 'Шифрование', link: '/development-pepeunit/mechanics/cipher' },
            { text: 'Генерация env.json у Unit', link: '/development-pepeunit/mechanics/alg-env' }
          ]
        },
        {
          text: 'Тесты Backend',
          collapsed: true,
          items: [
            { text: 'Модульные', link: '/development-pepeunit/tests/module-test' },
            { text: 'Интеграционные', link: '/development-pepeunit/tests/integration-test' },
            { text: 'Нагрузочные', link: '/development-pepeunit/tests/load-test' }
          ]
        },
        { text: 'Вклад', link: '/development-pepeunit/contribution' }
      ]
    },
    {
      text: 'Дорожная карта',
      collapsed: true,
      items: [
        { text: '> 1.0.0 Units', link: '/roadmap/units' },
        { text: '> 1.0.0 Уведомления Telegram', link: '/roadmap/alerts' },
        { text: '> 1.0.0 Сравнение инстансов', link: '/roadmap/comparison' },
        { text: '> 1.0.0 Рефактор фронтенда', link: '/roadmap/frontend-refactor' },
        { text: '> 2.0.0 Монетизация', link: '/roadmap/monetisation' },
        { text: '> 2.0.0 Федерация', link: '/roadmap/federation' }
      ]
    }
  ]
}


