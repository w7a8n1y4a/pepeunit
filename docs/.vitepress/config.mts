import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

// https://vitepress.dev/reference/site-config
export default withMermaid(defineConfig({
  head:[
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/vitepress-logo-mini.svg' }],
    ['link', { rel: 'icon', type: 'image/png', href: '/favicon.ico'}],
    ['meta', { name: 'theme-color', content: '#00bf30' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: 'Pepeunit Docs' }],
    ['meta', { property: 'og:site_name', content: 'Pepeunit Docs' }],
    ['meta', { property: 'og:description', content: 'Documentation of Federated IoT Platform | Open-Source | AGPL v3' }],
    ['meta', { property: 'og:image', content: 'https://pepeunit.com/pepeunit-og.jpg' }],
    ['meta', { property: 'og:url', content: 'https://pepeunit.com/' }],
  ],
  markdown: {
    languageAlias: {
      'micropython': 'python'
    }
  },
  title: 'Pepeunit Docs',
  description: 'Documentation of Federated IoT Platform | Open-Source | AGPL v3',
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: '/main_icon_small.png',
    nav: [
      { text: 'Demo', link: 'https://unit.pepeunit.com' },
      { text: 'Docs', link: '/conception/overview' }
    ],

    sidebar: [
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
              { text: 'Promtail', link: '/deployment/dependencies/promtail' },
            ]
          },
          {
            text: 'Docker',
            collapsed: true,
            items: [
              { text: 'Установка Docker и Compose', link: '/deployment/docker/install-docker' },
              { text: 'Развёртывание', link: '/deployment/docker/deploy' },
              { text: 'Бэкапы и Обновление', link: '/deployment/docker/backup-update' },
              { text: 'Полезные команды', link: '/deployment/docker/commands' },
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
              { text: 'Grafana', link: '/deployment/env-variables/grafana' },
            ]
          },
          { text: 'Мониторинг', link: '/deployment/monitoring' },
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
              { text: 'Настройка Repo', link: '/user/git-repository/settings-repo' },
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
              { text: 'Настройка Output→Input связи между UnitNode', link: '/user/unit/edge-unit-node' },
            ]
          },
          {
            text: 'DataPipe',
            collapsed: true,
            items: [
              { text: 'Настройка DataPipe', link: '/user/datapipe/datapipe' },
              { text: 'Примеры DataPipe', link: '/user/datapipe/example' },
              { text: 'Импорт данных в DataPipe', link: '/user/datapipe/import' },
            ]
          },
          {
            text: 'Grafana',
            collapsed: true,
            items: [
              { text: 'Создание Dashboard', link: '/user/grafana/create' },
              { text: 'Синхронизация с Grafana', link: '/user/grafana/sync' },
            ]
          },
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
              { text: 'Архив обновлений', link: '/developer/files/struct-archive-update' },
            ]
          },
          {
            text: 'Библиотеки Unit',
            collapsed: true,
            items: [
              { text: 'Pepeunit Framework', link: '/developer/libraries/framework' },
              { text: 'Micropython', link: '/developer/libraries/micropython' },
              { text: 'Golang', link: '/developer/libraries/golang' },
              { text: 'Python', link: '/developer/libraries/python' },
            ]
          },
          {
            text: 'MQTT Взаимодействие',
            collapsed: true,
            items: [
              { text: 'Стандартные MQTT команды Pepeunit', link: '/developer/mqtt/default-mqtt-command' },
              { text: 'Стандартные MQTT топики состояния', link: '/developer/mqtt/state-mqtt-send' },
              { text: 'Структура сообщений в MQTT топиках', link: '/developer/mqtt/struct-topic-messages' },
            ]
          },
          { text: 'Хранилище состояний Unit', link: '/developer/state-storage-unit' },
          { text: 'Компиляция для разных платформ', link: '/developer/release-assets' },
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
              { text: 'Генерация env.json у Unit', link: '/development-pepeunit/mechanics/alg-env' },
            ]
          },
          {
            text: 'Тесты Backend',
            collapsed: true,
            items: [
              { text: 'Модульные', link: '/development-pepeunit/tests/module-test' },
              { text: 'Интеграционные', link: '/development-pepeunit/tests/integration-test' },
              { text: 'Нагрузочные', link: '/development-pepeunit/tests/load-test' },
            ]
          },
          { text: 'Вклад', link: '/development-pepeunit/contribution' },
        ]
      },
      {
        text: 'Дорожная карта',
        collapsed: true,
        items: [
          { text: 'Доработки', link: '/roadmap/revisions' },
          { text: '> 1.0.0 Units', link: '/roadmap/units' },
          { text: '> 1.0.0 Уведомления Telegram', link: '/roadmap/alerts' },
          { text: '> 1.0.0 Сравнение инстансов', link: '/roadmap/comparison' },
          { text: '> 1.0.0 Рефактор фронтенда', link: '/roadmap/frontend-refactor' },
          { text: '> 2.0.0 Монетизация', link: '/roadmap/monetisation' },
          { text: '> 2.0.0 Федерация', link: '/roadmap/federation' },
        ]
      }
    ],

    search: {
      provider: 'local'
    },

    socialLinks: [
      {
        icon: {
          svg: '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" clip-rule="evenodd" viewBox="0 0 512 360.726"><path d="M456.035 10.769c22.031 5.926 39.377 23.386 45.265 45.56C512 96.516 512 180.363 512 180.363s0 83.846-10.7 124.037c-5.888 22.17-23.234 39.631-45.265 45.559-39.928 10.767-200.034 10.767-200.034 10.767s-160.107 0-200.035-10.767C33.937 344.031 16.587 326.57 10.7 304.4 0 264.209 0 180.363 0 180.363S0 96.516 10.7 56.329c5.887-22.174 23.237-39.634 45.266-45.56C95.894 0 256.001 0 256.001 0s160.106 0 200.034 10.769zm-252.398 245.72l133.818-76.122-133.818-76.131v152.253z"/></svg>'
        },
        link: 'https://www.youtube.com/@pepeunit'
      },
      {
        icon: {
          svg: '<svg width="800px" height="800px" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="m20.665 3.717-17.73 6.837c-1.21.486-1.203 1.161-.222 1.462l4.552 1.42 10.532-6.645c.498-.303.953-.14.579.192l-8.533 7.701h-.002l.002.001-.314 4.692c.46 0 .663-.211.921-.46l2.211-2.15 4.599 3.397c.848.467 1.457.227 1.668-.785l3.019-14.228c.309-1.239-.473-1.8-1.282-1.434z"/></svg>'
        },
        link: 'https://t.me/pepeunit'
      },
      {
        icon: {
          svg: '<svg width="800px" height="800px" viewBox="0 -28.5 256 256" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" preserveAspectRatio="xMidYMid"><g><path d="M216.856339,16.5966031 C200.285002,8.84328665 182.566144,3.2084988 164.041564,0 C161.766523,4.11318106 159.108624,9.64549908 157.276099,14.0464379 C137.583995,11.0849896 118.072967,11.0849896 98.7430163,14.0464379 C96.9108417,9.64549908 94.1925838,4.11318106 91.8971895,0 C73.3526068,3.2084988 55.6133949,8.86399117 39.0420583,16.6376612 C5.61752293,67.146514 -3.4433191,116.400813 1.08711069,164.955721 C23.2560196,181.510915 44.7403634,191.567697 65.8621325,198.148576 C71.0772151,190.971126 75.7283628,183.341335 79.7352139,175.300261 C72.104019,172.400575 64.7949724,168.822202 57.8887866,164.667963 C59.7209612,163.310589 61.5131304,161.891452 63.2445898,160.431257 C105.36741,180.133187 151.134928,180.133187 192.754523,160.431257 C194.506336,161.891452 196.298154,163.310589 198.110326,164.667963 C191.183787,168.842556 183.854737,172.420929 176.223542,175.320965 C180.230393,183.341335 184.861538,190.991831 190.096624,198.16893 C211.238746,191.588051 232.743023,181.531619 254.911949,164.955721 C260.227747,108.668201 245.831087,59.8662432 216.856339,16.5966031 Z M85.4738752,135.09489 C72.8290281,135.09489 62.4592217,123.290155 62.4592217,108.914901 C62.4592217,94.5396472 72.607595,82.7145587 85.4738752,82.7145587 C98.3405064,82.7145587 108.709962,94.5189427 108.488529,108.914901 C108.508531,123.290155 98.3405064,135.09489 85.4738752,135.09489 Z M170.525237,135.09489 C157.88039,135.09489 147.510584,123.290155 147.510584,108.914901 C147.510584,94.5396472 157.658606,82.7145587 170.525237,82.7145587 C183.391518,82.7145587 193.761324,94.5189427 193.539891,108.914901 C193.539891,123.290155 183.391518,135.09489 170.525237,135.09489 Z" ></path></g></svg>'
        },
        link: 'https://discord.gg/bTAF2mxzuN'
      },
      { 
        icon: {
          svg: '<svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>GitLab</title><path d="m23.6004 9.5927-.0337-.0862L20.3.9814a.851.851 0 0 0-.3362-.405.8748.8748 0 0 0-.9997.0539.8748.8748 0 0 0-.29.4399l-2.2055 6.748H7.5375l-2.2057-6.748a.8573.8573 0 0 0-.29-.4412.8748.8748 0 0 0-.9997-.0537.8585.8585 0 0 0-.3362.4049L.4332 9.5015l-.0325.0862a6.0657 6.0657 0 0 0 2.0119 7.0105l.0113.0087.03.0213 4.976 3.7264 2.462 1.8633 1.4995 1.1321a1.0085 1.0085 0 0 0 1.2197 0l1.4995-1.1321 2.4619-1.8633 5.006-3.7489.0125-.01a6.0682 6.0682 0 0 0 2.0094-7.003z"/></svg>',
        },
        link: 'https://git.pepemoss.com/pepe/pepeunit/pepeunit.git' 
      },
      { 
        icon: 'github',
        link: 'https://github.com/w7a8n1y4a/pepeunit.git' 
      }
    ]
  }
})
)
