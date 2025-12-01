---
layout: home
hero:
  name: "Pepeunit"
  text: "Федеративная IoT Платформа"
  actions:
    - theme: brand
      text: Что такое Pepeunit?
      link: /conception/overview
    - theme: alt
      text: Demo Instance
      link: https://unit.pepeunit.com/
  image:
    src: /main_icon_big.webp
    alt: Pepeunit

features:
  - title: CI/CD
    details: Автоматическая генерация ПО для IoT-устройств на основе ваших репозиториев gitlab и github
  - title: Pipeline Data Processing
    details: Опциональная обработка данных конвейерами-обогатителями с сохранением в ClickHouse
  - title: Integration with Grafana
    details: Генератор Dashboard с возможностью выбирать несколько UnitNode в визуализацию
  - title: Repository Registry
    details: Открытый реестр репозиториев для создания Unit
  - title: IoT Device Management
    details: Управление устройствами через MQTT, REST, GQL, Frontend и Telegram
  - title: Topic Managment
    details: Система именования тем для отбражения данных и/или быстрого взаимодействия между IoT устройствами
  - title: Access Policies
    details: Настройка уровней доступа User-Unit и Unit-Unit с учетом ролей Пользователей и уровней видимости Repo, Unit и UnitNode
  - title: Client Library
    details: Клиентские библиотеки для Micropython, Python и Golang
  - title: Instance Comparision
    details: Будет доступно в начиная с одной из версий > 1.0.0
  - title: Federation
    details: Будет доступно в версии 2.0.0
  - title: Monetization
    details: Будет доступно в версии 2.0.0
---

<style>
:root {
  --vp-home-hero-name-color: transparent;
  --vp-home-hero-name-background: -webkit-linear-gradient(135deg, #73fc03, #fcf403 70%);

  --vp-home-hero-image-background-image: linear-gradient(-45deg, #73fc03 50%, #fcf403 50%);
  --vp-home-hero-image-filter: blur(44px);
}

@media (min-width: 640px) {
  :root {
    --vp-home-hero-image-filter: blur(56px);
  }
}

@media (min-width: 960px) {
  :root {
    --vp-home-hero-image-filter: blur(68px);
  }
}
</style>