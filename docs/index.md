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
  - title: IoT device management
    details: Управление устройствами через MQTT, REST, GQL и Frontend
  - title: Topic managment
    details: Система именования тем для отбражения данных и/или быстрого взаимодействия между IoT устройствами
  - title: Access policies
    details: Настройка уровней доступа User-Unit и Unit-Unit с учетом ролей пользователей и уровней видимости Repo, Unit и UnitNode
  - title: Federation
    details: Соединяйте экземпляры Pepeunit в единую федеративную сеть для связи между IoT-устройствами
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