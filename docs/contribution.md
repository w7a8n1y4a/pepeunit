# Хотите внести вклад в разработку ?

:::tip
Основаня платформа - Gitlab. В каждом репозитории разработки вы найдёте способы его развёртывания и полезные команды для разработчика. В репозиториях Pepeunit, приняты правила о ведении веток Git Flow и именовании коммитов.
:::

## Git Flow

Актуален на период создания MVP

![](https://git.pepemoss.com/universitat/master/docs/-/raw/main/gitflow/images/appgitflow.png)

Вы создаёте feature ветку от dev, вносите изменения, далее создаёте MR или PR. Старший разработчик примет его или сообщит о правках.

## Соглашение о именовании коммитов

Основные типы коммитов и примеры их записи. Коммиты других форматов приниматься в MR не будут.

1. `feat(unit_service): add new function`
2. `fix(tests, unit_service): hotfix logic create UnitNode`
3. `refactor(permission_service): add new permission, rest, gql and mutatuion for creator UnitNode`
4. `resolve(conflicts): resolve`
5. `ci(Dockerfile): change packages`

- Потренируйтесь в [COMMITLINT](https://commitlint.io/)
