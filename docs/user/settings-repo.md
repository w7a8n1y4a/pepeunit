# Настройка Repo

:::warning
Когда вы только создали [Repo](/definitions#repo) он ещё не может быть использован для создания [Unit](/definitions#unit), чтобы это стало возможным, требуется выбрать [ветку](/definitions#git-branch) по умолчанию
:::

## Ветка

Для работы обновлений и возможности создавать [Unit](/definitions#unit) нужно выбрать [ветку](/definitions#git-branch) по умолчанию, обычно в репозиториях присутствуют указания о том какую [ветку](/definitions#git-branch) требуется выбрать для корректного обновления и создания [Unit](/definitions#unit). Обычно - это `Release`

## Флаги массовых обновлений

Данный блок отвечает за управление обновлениями [Unit](/definitions#unit) со стороны [Repo](/definitions#repo), данный функционал позволяет массово обновлять дочерние [Unit](/definitions#unit). В настройке участвуют два флага и возможность выбора [коммита](/definitions#git-commit). Доступные комбинации:

1. `Auto-update = True` и `Tags-only = False` - [Repo](/definitions#repo) будет каждый час опрашивать внешний репозиторий `Git` на предмет новых [коммитов](/definitions#git-commit), как только они появились - комиты локального хранилища Pepunit будут синхронизированы с внешним репозиторием. При этом все дочерние [Unit](/definitions#unit), которые разрешили автоматическое обновление через [Repo](/definitions#repo) - получат запрос на обновление.
2. `Auto-update = True` и `Tags-only = True` - аналогично первому пункту, за исключением того, что запрос для [Unit](/definitions#unit) будет отправлен только в случае если появится новый [Тег](/definitions#git-tag).
3. `Auto-update = False` и `Commit = <best-commit-pick>` - если установить [коммит](/definitions#git-commit) и нажать `Update` все [Unit](/definitions#unit) у которых настроено автообновление от [Repo](/definitions#repo) получат запрос на обновление, соответствующий текущей [ветке](/definitions#git-branch) и [коммиту](/definitions#git-commit).

:::warning
Данные способы обновления [Unit](/definitions#unit) будут работать только для [Unit](/definitions#unit) с установленным автоматическим обновлением. Это сделано чтобы владельцы [Repo](/definitions#repo) не могли по своему желанию обновить вашу версию [Unit](/definitions#unit), если вы желаете оставаться на старых версиях.
:::
