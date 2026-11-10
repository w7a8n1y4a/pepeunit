# env.json

:::warning Для чего нужен env.json?
Это контракт четырёх сторон: Unit, Pepeunit, [Пользователя](/development-pepeunit/mechanics/roles#user) и владельца инстанса:
1. Unit берёт для значений из env_example.json данные из env.json
1. Pepeunit заполняет стандартные переменные, когда env.json создаётся впервые
1. Pepeunit обеспечивает Unit авторизацию в [EMQX](/deployment/dependencies/emqx) и [Backend](/deployment/dependencies/backend) по токену PU_AUTH_TOKEN
1. Pepeunit позволяет менять env.json
1. Pepeunit хранит env.json в [шифрованном виде](/development-pepeunit/mechanics/cipher)
1. Pepeunit отдаёт env.json только создателю Unit и самому Unit
1. Владелец инстанса не передаёт env.json никому, кроме сторон этого контракта
:::

Файлы окружения, такие как env.json или [переменные Backend](/deployment/env-variables/backend), подгоняют общий код под конкретное устройство или экземпляр приложения.

:::danger
Используйте только доверенные инстансы Pepeunit: владелец инстанса технически может расшифровать env.json.
:::

:::info Основные свойства env.json
1. Он секретен, его нельзя никому передавать
1. С ним можно настраивать Unit и менять его состояние без полного обновления программы
1. Он сообщает Unit, какому инстансу тот принадлежит
1. Токен PU_AUTH_TOKEN из него позволяет Pepeunit узнавать конкретный Unit
:::

Где править env.json в клиенте: `Аппараты` → Unit → `Переменные окружения`.
