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

Файлы окружения, такие как env.json или [переменные Backend](/deployment/env-variables/backend), подгоняют общий код под конкретное устройство или экземпляр приложения. Через env.json можно настраивать Unit и менять его состояние без полного обновления программы, а ещё он сообщает Unit, какому инстансу тот принадлежит.

:::danger
env.json секретен, его нельзя никому передавать. Используйте только доверенные инстансы Pepeunit: владелец инстанса технически может расшифровать env.json.
:::

Где править env.json в клиенте: `Аппараты` → Unit → `Переменные окружения`.
