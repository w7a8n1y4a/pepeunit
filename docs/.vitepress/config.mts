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
      { text: 'Home', link: '/' },
      { text: 'Docs', link: '/overview' }
    ],

    sidebar: [
      {
        text: 'Conceptions',
        items: [
          { text: 'Обзор', link: '/overview' },
          { text: 'Функционал', link: '/functions' },
          { text: 'Принципы', link: '/principles' },
          { text: 'Определения', link: '/definitions' }
        ]
      },
      {
        text: 'Вклад',
        items: [
          { text: 'Соглашения', link: '/contribution' },
        ]
      },
      {
        text: 'Тесты',
        items: [
          { text: 'Интеграционные', link: '/integration-test' },
        ]
      },
      {
        text: 'Docs Example',
        items: [
          { text: 'Markdown Examples', link: '/markdown-examples' },
          { text: 'Runtime API Examples', link: '/api-examples' },
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
