# Хотите внести вклад в разработку ?


## Репозитории
:::tip
Найти все `core` репозитории можно на [Карте репозиториев](/development-pepeunit/maps)
:::

:::tip
Основаня платформа для разработки - [Gitlab](/definitions#gitlab), чтобы зарегистрироваться свяжитесь с [@w7a8n1y4a](https://t.me/w7a8n1y4a), при этом все `core` репозитории имеют зеркало на [Github](/definitions#github), чтобы пользователям было проще оставлять `issues`.

В каждом репозитории разработки вы найдёте `Makefile` и [readme.md](/definitions#readme-md) с важными нюансами по работe кода
:::


## TBD

В репозиториях [Pepeunit](/conception/overview) принята методология разработки - `TBD`

:::info
`Trunk Based Development (TBD)` — методология разработки, при которой вся команда работает в одной основной [ветке](/definitions#git-branch) `master`, а любые вспомогательные [ветки](/definitions#git-branch) `feature/best_feature_name` живут заведомо малое время `часы или дни`. Все изменения интегрируются часто, поддерживается постоянная готовность [ветки](/definitions#git-branch) к релизу.

`TBD` также подразумевает использование `feature flags (FF)` для включения и отключения функционала в разврачиваемых инстансах.

Такой подход значительно ускоряет разработку по сравнению с `Git Flow`, снижает конфликты слияния и повышает стабильность кода.
:::

## Соглашение о именовании коммитов

:::info
Система именования коммитов [COMMITLINT example](https://www.commitvalidator.dev/) - помогает быстро понять суть каждого изменения, и улучшает прозрачность истории разработки.
  
Основные преимущества:
- Повышает читаемость и структурность истории [Git](/definitions#git).
- Упрощает поиск нужных изменений и анализ причин ошибок.

Единый стиль именования облегчает совместную работу в рамках методологии `TBD` и ускоряет код-ревью.
:::

Примеры [коммитов](/definitions#git-commit):
1. `feat(unit_service): add new function`
2. `fix(tests, unit_service): hotfix logic create UnitNode`
3. `refactor(permission_service): add new permission, rest, gql and mutatuion for creator UnitNode`
4. `resolve(conflicts): resolve`
5. `ci(Dockerfile): change packages`

:::danger
[Коммиты](/definitions#git-commit) других форматов приниматься в `MR` не будут.
:::
