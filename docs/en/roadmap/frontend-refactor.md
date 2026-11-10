# Frontend refactor into the client

The client is a Flutter app in this repository. The UI constraints live in the code and in `.cursor/rules/` (`client.mdc`, `hive-ui.mdc`, `hex-layout.mdc`, `hex-scale.mdc`). Here is only what is still to be done. What is implemented is described in the code and the rules.

## Pre-release checklist

- check the use of the dev stand in the code, and how the variable with the /current instance works
- Full coverage of the user-facing OpenAPI endpoints; exceptions: Grafana datasource, Telegram glue, Prometheus and other service layer
- Check the use of parameters from /pepeunit/api/v1/instances/current in forms, etc.
- Review all interfaces and offload them from unnecessary data
- translation of the documentation
- translation of tooltips
- translation of errors - `en` in `errorTexts` (`lib/locale/error_texts.dart`) and the common strings in `lib/locale/failure.dart`
- go through the readme of all repositories and fix them, especially the links to the docs in deploy

### Presentation

- we will add it after the release, just swap the container version

- A set of literally 10 screens, in presentation format
- Explains what pepeunit is
- Explains what features there are
- Makes it possible to replace the presentation potential of the old documentation landing page
- Will run on a separate engine, better suited for presentations