# Модульные тесты - Backend

:::info
Проверяет [Backend](/deployment/dependencies/backend) сущности на корректность работы, выполняется очень быстро. Покрытие на данном этапе маленькое, команда стремится его увеличить.
:::

## Запуск

Запустить модульное тестирование можно командой:
```bash
pytest app -v
```

## Проверяемые сущности:

1. `JwtAuthService`
1. `TgBotAuthService`
1. `AuthorizationService`