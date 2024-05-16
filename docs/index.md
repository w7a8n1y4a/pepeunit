---
layout: home
hero:
  name: "Pepeunit"
  text: "Federative IoT Platform"
  tagline: From device to network
  actions:
    - theme: brand
      text: What is Pepeunit?
      link: /overview
    - theme: alt
      text: Fediverse state
      link: https://fediverse.observer/
  image:
    src: /main_icon_big.webp
    alt: Pepeunit

features:
  - title: CI/CD
    details: Automatic generation of IoT device firmware based on your github and gitlab repositories
  - title: IoT device management
    details: Manage your devices via MQTT, REST, GQL, Telegram Bot and Frontend
  - title: Accumulate data and monitor
    details: Topic naming system, for collecting statistics and/or fast interaction between IoT
  - title: Access policies
    details: Adjust User-Unit and Unit-Unit access levels with user roles and visibility levels of Repo, Unit and UnitNode
  - title: Federation
    details: Connect instances into a single Federated Network for communication between IoT devices
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