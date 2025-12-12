---
layout: home
hero:
  name: "Pepeunit"
  text: "Federated IoT Platform"
  actions:
    - theme: brand
      text: What is Pepeunit?
      link: /en/conception/overview
    - theme: alt
      text: Demo Instance
      link: https://unit.pepeunit.com/
  image:
    src: /main_icon_big.webp
    alt: Pepeunit

features:
  - title: CI/CD
    details: Automatic generation of software for IoT devices based on your GitLab and GitHub repositories
  - title: Pipeline Data Processing
    details: Optional data processing with enrichment pipelines with persistence in ClickHouse
  - title: Integration with Grafana
    details: Dashboard generator that allows you to select multiple UnitNodes into one visualization
  - title: Repository Registry
    details: Open registry of repositories for creating Units
  - title: IoT Device Management
    details: Device management via MQTT, REST, GQL, frontend and Telegram
  - title: Topic Managment
    details: Topic naming system for displaying data and/or fast interaction between IoT devices
  - title: Access Policies
    details: Access level configuration for User–Unit and Unit–Unit, taking into account user roles and the visibility levels of Repo, Unit and UnitNode
  - title: Client Library
    details: Client libraries for Micropython, Python and Golang
  - title: Instance Comparision
    details: Will be available starting from one of the versions > 1.0.0
  - title: Federation
    details: Will be available in version 2.0.0
  - title: Monetization
    details: Will be available in version 2.0.0
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