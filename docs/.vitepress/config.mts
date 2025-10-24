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
        collapsed: true,
        items: [
          { text: 'Обзор', link: '/conception/overview' },
          { text: 'Определения', link: '/definitions' }
        ]
      },
      {
        text: 'Развёртывание',
        collapsed: true,
        items: [
          { text: 'Зависимости', link: '/deployment/dependencies' },
          { text: 'Docker Compose', link: '/deployment/docker' },
          { text: 'Nginx', link: '/deployment/nginx' },
          { text: 'Переменные окружения', link: '/deployment/env-variables' },
          { text: 'Grafana Мониторинг', link: '/deployment/monitoring' },
        ]
      },
      {
        text: 'Руководство Пользователя',
        collapsed: true,
        items: [
          { text: 'Создание RepositoryRegistry', link: '/user/create-repository-registry' },
          { text: 'Создание Repo', link: '/user/create-repo' },
          { text: 'Настройка Repo', link: '/user/settings-repo' },
          { text: 'Создание Unit', link: '/user/create-unit' },
          { text: 'Обновление Unit', link: '/user/update-unit' },
          { text: 'Настройки UnitNode', link: '/user/settings-unit-node' },
          { text: 'Cвязи Output->Input между UnitNode', link: '/user/edge-unit-node' },
          { text: 'Настройки DataPipe', link: '/user/data-pipe' },
          { text: 'Управление Dashboard', link: '/user/dashboard' },
        ]
      },
      {
        text: 'Руководство Разработчика Unit',
        collapsed: true,
        items: [
          { text: 'Алгоритм создания Unit', link: '/developer/alg-create-unit' },
          { text: 'Структура GIT репозитория', link: '/developer/struct-git-repo' },
          { text: 'Документация Readme', link: '/developer/struct-readme' },
          { text: 'Структура schema.json и schema_example.json', link: '/developer/struct-schema-json' },
          { text: 'Структура env.json и env_example.json', link: '/developer/struct-env-json' },
          { text: 'Структура архивов c обновлениями', link: '/developer/struct-archive-update' },
          { text: 'Стандартные MQTT команды Pepeunit', link: '/developer/default-mqtt-command' },
          { text: 'Отправка состояния Unit через MQTT', link: '/developer/state-mqtt-send' },
          { text: 'Структура сообщений в MQTT топиках', link: '/developer/struct-topic-messages' },
          { text: 'Хранилище состояний Unit', link: '/developer/state-storage-unit' },
          { text: 'Компиляция для разных платформ', link: '/developer/release-assets' },
        ]
      },
      {
        text: 'Механики',
        collapsed: true,
        items: [
          { text: 'Система Ролей', link: '/mechanics/roles' },
          { text: 'Система Видимости', link: '/mechanics/visibility' },
          { text: 'Система Доступов', link: '/mechanics/permission' },
          { text: 'Система Обновлений', link: '/mechanics/update-system' },
          { text: 'Шифрование', link: '/mechanics/cipher' },
        ]
      },
      {
        text: 'Тесты',
        collapsed: true,
        items: [
          { text: 'Модульные', link: '/tests/module-test' },
          { text: 'Интеграционные', link: '/tests/integration-test' },
          { text: 'Нагрузочные', link: '/tests/load-test' },
        ]
      },
      {
        text: 'Дорожная карта',
        collapsed: true,
        items: [
          { text: 'Библиотеки', link: '/roadmap/libs' },
          { text: 'Алерты', link: '/roadmap/alerts' },
          { text: '> 1.0.0 Units', link: '/roadmap/units' },
          { text: '> 1.0.0 Сравнение инстансов', link: '/roadmap/comparison' },
          { text: '> 1.0.0 Рефактор фронтенда', link: '/roadmap/frontend-refactor' },
          { text: '> 2.0.0 Монетизация', link: '/roadmap/monetisation' },
          { text: '> 2.0.0 Федерация', link: '/roadmap/federation' },
        ]
      },
      {
        text: 'Для общественности',
        collapsed: true,
        items: [
          { text: 'Видео YouTube', link: '/society/video' },
        ]
      },
      {
        text: 'Вклад',
        collapsed: true,
        items: [
          { text: 'Соглашения', link: '/contribution/contribution' },
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
