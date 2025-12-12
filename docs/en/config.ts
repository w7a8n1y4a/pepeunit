import type { DefaultTheme } from 'vitepress'

export const pepeDescription =
  'Documentation for the Pepeunit federated IoT platform.'

export function nav(): DefaultTheme.NavItem[] {
  return [
    {
      text: 'Demo',
      link: 'https://unit.pepeunit.com'
    },
    {
      text: 'Docs',
      link: '/en/conception/overview',
      activeMatch: '/'
    }
  ]
}

export function sidebarGuide(): DefaultTheme.SidebarItem[] {
  return [
    {
      text: 'Concept',
      collapsed: false,
      items: [
        { text: 'Overview', link: '/en/conception/overview' },
        { text: 'Definitions', link: '/en/definitions' }
      ]
    },
    {
      text: 'Deployment',
      collapsed: false,
      items: [
        { text: 'Service interaction diagram', link: '/en/deployment/schema' },
        {
          text: 'Dependencies',
          collapsed: true,
          items: [
            { text: 'PostgreSQL', link: '/en/deployment/dependencies/postgresql' },
            { text: 'ClickHouse', link: '/en/deployment/dependencies/clickhouse' },
            { text: 'Redis', link: '/en/deployment/dependencies/redis' },
            { text: 'EMQX', link: '/en/deployment/dependencies/emqx' },
            { text: 'Backend', link: '/en/deployment/dependencies/backend' },
            { text: 'DataPipe', link: '/en/deployment/dependencies/datapipe' },
            { text: 'Frontend', link: '/en/deployment/dependencies/frontend' },
            { text: 'Grafana', link: '/en/deployment/dependencies/grafana' },
            { text: 'Nginx', link: '/en/deployment/dependencies/nginx' },
            { text: 'Prometheus', link: '/en/deployment/dependencies/prometheus' },
            { text: 'Logporter', link: '/en/deployment/dependencies/logporter' },
            { text: 'Loki', link: '/en/deployment/dependencies/loki' },
            { text: 'Promtail', link: '/en/deployment/dependencies/promtail' }
          ]
        },
        {
          text: 'Docker',
          collapsed: true,
          items: [
            { text: 'Installation Docker and Compose', link: '/en/deployment/docker/install-docker' },
            { text: 'Deployment', link: '/en/deployment/docker/deploy' },
            { text: 'Backups and Updates', link: '/en/deployment/docker/backup-update' },
            { text: 'Commands', link: '/en/deployment/docker/commands' }
          ]
        },
        { text: 'Nginx configurations', link: '/en/deployment/nginx' },
        {
          text: 'Environment variables',
          collapsed: true,
          items: [
            { text: 'Backend', link: '/en/deployment/env-variables/backend' },
            { text: 'DataPipe', link: '/en/deployment/env-variables/data-pipe' },
            { text: 'Frontend', link: '/en/deployment/env-variables/frontend' },
            { text: 'PostgreSQL', link: '/en/deployment/env-variables/postgresql' },
            { text: 'ClickHouse', link: '/en/deployment/env-variables/clickhouse' },
            { text: 'EMQX', link: '/en/deployment/env-variables/emqx' },
            { text: 'Grafana', link: '/en/deployment/env-variables/grafana' }
          ]
        },
        { text: 'Monitoring', link: '/en/deployment/monitoring' }
      ]
    },
    {
      text: 'User manual',
      collapsed: false,
      items: [
        {
          text: 'Git Repository Management',
          collapsed: true,
          items: [
            { text: 'Create RepositoryRegistry', link: '/en/user/git-repository/create-repository-registry' },
            { text: 'Create Repo', link: '/en/user/git-repository/create-repo' },
            { text: 'Settings Repo', link: '/en/user/git-repository/settings-repo' }
          ]
        },
        {
          text: 'Unit',
          collapsed: true,
          items: [
            { text: 'Create Unit in Pepeunit', link: '/en/user/unit/create-unit-pepeunit' },
            { text: 'Create Physical Unit', link: '/en/user/unit/create-physic-unit' },
            { text: 'Update Unit', link: '/en/user/unit/update-unit' },
            { text: 'Settings UnitNode', link: '/en/user/unit/settings-unit-node' },
            { text: 'Output->Input connections between UnitNode', link: '/en/user/unit/edge-unit-node' }
          ]
        },
        {
          text: 'DataPipe',
          collapsed: true,
          items: [
            { text: 'Settings DataPipe', link: '/en/user/datapipe/datapipe' },
            { text: 'Examples DataPipe', link: '/en/user/datapipe/example' },
            { text: 'Import data to DataPipe', link: '/en/user/datapipe/import' }
          ]
        },
        {
          text: 'Grafana',
          collapsed: true,
          items: [
            { text: 'Create Dashboard', link: '/en/user/grafana/create' },
            { text: 'Synchronization with Grafana', link: '/en/user/grafana/sync' }
          ]
        }
      ]
    },
    {
      text: 'Unit Developer Manual',
      collapsed: false,
      items: [
        { text: 'Algorithm for creating a Unit', link: '/en/developer/alg-create-unit' },
        {
          text: 'Файлы',
          collapsed: true,
          items: [
            { text: 'GIT repository structure', link: '/en/developer/files/struct-git-repo' },
            { text: 'schema_example.json', link: '/en/developer/files/struct-schema-example-json' },
            { text: 'schema.json', link: '/en/developer/files/struct-schema-json' },
            { text: 'env_example.json', link: '/en/developer/files/struct-env-example-json' },
            { text: 'env.json', link: '/en/developer/files/struct-env-json' },
            { text: 'pepeunit.toml', link: '/en/developer/files/struct-pepeunit-toml' },
            { text: 'readme.md', link: '/en/developer/files/struct-readme' },
            { text: '.gitignore', link: '/en/developer/files/struct-gitignore' },
            { text: '.pepeignore', link: '/en/developer/files/struct-pepeignore' },
            { text: 'Update archive', link: '/en/developer/files/struct-archive-update' }
          ]
        },
        {
          text: 'Unit Libraries',
          collapsed: true,
          items: [
            { text: 'Pepeunit Framework', link: '/en/developer/libraries/framework' },
            { text: 'Micropython', link: '/en/developer/libraries/micropython' },
            { text: 'Golang', link: '/en/developer/libraries/golang' },
            { text: 'Python', link: '/en/developer/libraries/python' }
          ]
        },
        {
          text: 'MQTT Interaction',
          collapsed: true,
          items: [
            { text: 'Standard MQTT commands Pepeunit', link: '/en/developer/mqtt/default-mqtt-command' },
            { text: 'Standard MQTT status topics', link: '/en/developer/mqtt/state-mqtt-send' },
            { text: 'Structure of messages in MQTT topics', link: '/en/developer/mqtt/struct-topic-messages' }
          ]
        },
        { text: 'Unit state storage', link: '/en/developer/state-storage-unit' },
        { text: 'Compilation for different platforms', link: '/en/developer/release-assets' }
      ]
    },
    {
      text: 'Unit Developer Instructions',
      collapsed: true,
      items: [
        { text: 'Map of repositories', link: '/en/development-pepeunit/maps' },
        {
          text: 'Mechanics',
          collapsed: true,
          items: [
            { text: 'Role System', link: '/en/development-pepeunit/mechanics/roles' },
            { text: 'Visibility System', link: '/en/development-pepeunit/mechanics/visibility' },
            { text: 'Access System', link: '/en/development-pepeunit/mechanics/permission' },
            { text: 'Update System', link: '/en/development-pepeunit/mechanics/update-system' },
            { text: 'Encryption', link: '/en/development-pepeunit/mechanics/cipher' },
            { text: 'Generating env.json at Unit', link: '/en/development-pepeunit/mechanics/alg-env' }
          ]
        },
        {
          text: 'Backend Tests',
          collapsed: true,
          items: [
            { text: 'Module tests', link: '/en/development-pepeunit/tests/module-test' },
            { text: 'Integration tests', link: '/en/development-pepeunit/tests/integration-test' },
            { text: 'Load tests', link: '/en/development-pepeunit/tests/load-test' }
          ]
        },
        { text: 'Contribution', link: '/en/development-pepeunit/contribution' }
      ]
    },
    {
      text: 'Roadmap',
      collapsed: true,
      items: [
        { text: '> 1.0.0 Units', link: '/en/roadmap/units' },
        { text: '> 1.0.0 Telegram Alerts', link: '/en/roadmap/alerts' },
        { text: '> 1.0.0 Instance Comparison', link: '/en/roadmap/comparison' },
        { text: '> 1.0.0 Frontend Refactor', link: '/en/roadmap/frontend-refactor' },
        { text: '> 2.0.0 Monetization', link: '/en/roadmap/monetisation' },
        { text: '> 2.0.0 Federation', link: '/en/roadmap/federation' }
      ]
    }
  ]
}


