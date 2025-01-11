# Хотите внести вклад в разработку ?

:::tip
Основаня платформа - [Gitlab](/definitions#gitlab). В каждом репозитории разработки вы найдёте способы его развёртывания и полезные команды для разработчика. В репозиториях [Pepeunit](/conception/overview), приняты правила о ведении [веток](/definitions#git-branch) `Git Flow` и именовании [коммитов](/definitions#git-commit).
:::

## Git Flow

Актуален на период создания `MVP`

![](https://git.pepemoss.com/universitat/master/docs/-/raw/main/gitflow/images/appgitflow.png)

Вы создаёте `feature` [ветку](/definitions#git-branch) от `dev`, вносите изменения, далее создаёте `MR` в `dev` [ветку](/definitions#git-branch). Старший разработчик примет его или сообщит о правках.

## Соглашение о именовании коммитов

Основные типы [коммитов](/definitions#git-commit) и примеры их записи. [Коммиты](/definitions#git-commit) других форматов приниматься в `MR` не будут.

1. `feat(unit_service): add new function`
2. `fix(tests, unit_service): hotfix logic create UnitNode`
3. `refactor(permission_service): add new permission, rest, gql and mutatuion for creator UnitNode`
4. `resolve(conflicts): resolve`
5. `ci(Dockerfile): change packages`

- Потренируйтесь в [COMMITLINT](https://commitlint.io/)
