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
        items: [
          { text: 'Обзор', link: '/conception/overview' },
          { text: 'Определения', link: '/definitions' }
        ]
      },
      {
        text: 'Развёртывание',
        items: [
          { text: 'Зависимости', link: '/deployment/dependencies' },
          { text: 'Docker Compose', link: '/deployment/docker' },
        ]
      },
      {
        text: 'Руководство Пользователя',
        items: [
          { text: 'Создание Repo', link: '/user/create-repo' },
          { text: 'Настройка Repo', link: '/user/settings-repo' },
          { text: 'Создание Unit', link: '/user/create-unit' },
          { text: 'Обновление Unit', link: '/user/update-unit' },
          { text: 'Настройки UnitNode', link: '/user/settings-unit-node' },
          { text: 'Cвязи Output->Input между UnitNode', link: '/user/edge-unit-node' },
          { text: 'Доступы', link: '/user/permission' },
        ]
      },
      {
        text: 'Руководство Разработчика Unit',
        items: [
          { text: 'Алгоритм создания Unit', link: '/developer/alg-create-unit' },
          { text: 'Структура GIT репозитория', link: '/developer/struct-git-repo' },
          { text: 'Readme', link: '/developer/struct-readme' },
          { text: 'Структура env.json и env_example.json', link: '/developer/struct-env-json' },
          { text: 'Структура schema.json и schema_example.json', link: '/developer/struct-schema-json' },
          { text: 'Структура архивов c обновлениями', link: '/developer/struct-archive-update' },
          { text: 'Стандартные MQTT команды Pepeunit', link: '/developer/default-mqtt-command' },
          { text: 'Отправка состояния Unit через MQTT', link: '/developer/state-mqtt-send' },
          { text: 'Структура сообщений в MQTT топиках', link: '/developer/struct-topic-messages' },
          { text: 'Хранилище состояний Unit', link: '/developer/state-storage-unit' },
          { text: 'Аспекты системы обновлений', link: '/developer/tip-update-system' },
        ]
      },
      {
        text: 'Механики',
        items: [
          { text: 'Repo', link: '/mechanics/repo' },
          { text: 'Unit', link: '/mechanics/unit' },
          { text: 'UnitNode', link: '/mechanics/unit-node' },
          { text: 'Система Ролей', link: '/mechanics/roles' },
          { text: 'Система Видимости', link: '/mechanics/visibility' },
          { text: 'Шифрование', link: '/mechanics/cipher' },
        ]
      },
      {
        text: 'Тесты',
        items: [
          { text: 'Интеграционные', link: '/tests/integration-test' },
          { text: 'Нагрузочные', link: '/tests/load-test' },
        ]
      },
      {
        text: 'Дорожная карта',
        items: [
          { text: 'Функционал', link: '/roadmap/functions' },
          { text: 'Unit', link: '/roadmap/units' },
        ]
      },
      {
        text: 'Вклад',
        items: [
          { text: 'Соглашения', link: '/contribution/contribution' },
        ]
      },
      {
        text: 'VitePress Example',
        items: [
          { text: 'Markdown Examples', link: '/example/markdown-examples' },
          { text: 'Runtime API Examples', link: '/example/api-examples' },
        ]
      }
    ],

    search: {
      provider: 'local'
    },
    
    socialLinks: [
      { 
        icon: {
          svg: '<svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>GitLab</title><path d="m23.6004 9.5927-.0337-.0862L20.3.9814a.851.851 0 0 0-.3362-.405.8748.8748 0 0 0-.9997.0539.8748.8748 0 0 0-.29.4399l-2.2055 6.748H7.5375l-2.2057-6.748a.8573.8573 0 0 0-.29-.4412.8748.8748 0 0 0-.9997-.0537.8585.8585 0 0 0-.3362.4049L.4332 9.5015l-.0325.0862a6.0657 6.0657 0 0 0 2.0119 7.0105l.0113.0087.03.0213 4.976 3.7264 2.462 1.8633 1.4995 1.1321a1.0085 1.0085 0 0 0 1.2197 0l1.4995-1.1321 2.4619-1.8633 5.006-3.7489.0125-.01a6.0682 6.0682 0 0 0 2.0094-7.003z"/></svg>',
        },
        link: 'https://git.pepemoss.com/pepe/pepeunit/pepeunit.git' 
      },
      { 
        icon: 'github',
        link: 'https://github.com/w7a8n1y4a/pepeunit.git' 
      },
    ]
  }
})
)
