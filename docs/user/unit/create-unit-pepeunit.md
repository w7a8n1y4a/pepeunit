# Создание Unit в Pepunit

:::info Где найти?
Перейдите в нужный вам [Repo](/definitions#repo) и найдите подсвеченную зелёным кнопку `Create Unit`.
:::

## Имя вашего Unit

Требования:
1. Уникальность на текущем инстансе
1. Длинна от `4` до `20` символов
1. Разрешённые символы: `a-z, A-Z, 0-9 и _.-`

:::info
Можно изменить в будущем
:::

## Уровень видимости
Выберите [Уровень видимости](/development-pepeunit/mechanics/visibility)

:::info
Можно изменить в будущем
:::

## Блок автообновлений

Доступны два режима:
1. `Auto-update = True` - в данном режиме [Unit](/definitions#unit) подчиняется [Repo](/definitions#repo) в соответствии с [флагами массовых обновлений](/user/git-repository/settings-repo.md#флаги-массовых-обновлении)
1. `Auto-update = False` - ручной режим обновлений [Unit](/definitions#unit), требует ввести [ветку](/definitions#git-branch) и [коммит](/definitions#git-commit).

## Выбор платформы для компилируемых Repo

Данная опция есть только у [Unit](/definitions#unit), создающихся на основе [Компилируемых](/definitions#compilable) [Repo](/definitions#repo). Каждый элемент выбора здесь является выбором готовой бинарной версии приложения, соответстующий целевому [Тегу](/definitions#git-tag).

[Подробнее о системе предварительной компиляции](/developer/release-assets)

:::info
Данные параметры забираются на основе `assets` из релизов [Git](/definitions#git) репозиториев. [Разработчики Unit](/development-pepeunit/mechanics/roles#unit-developer), обычно, хранят там скомпилированные версии своих приложений. Это могут быть скомпилированные программы микроконтроллеров, `.exe` файлы, `.bin` файлы и т.д. Сервисы [GitLab](/definitions#gitlab) или [GitHub](/definitions#github) включают сюда также архивы с файлами релиза: `zip`, `tar` и т.д.
:::