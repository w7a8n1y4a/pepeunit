# Создание RepositoryRegistry

:::info Где найти?
На главной странице инстанса найдите в верхнем левом углу кнопку поиска. Выберите сущность `Registry`. В нижней левой части модального окна, вы сможете нажать кнопку `Create Registry`
:::

:::info Что нужно?
Для создания [RepositoryRegisty](/definitions#repositoryregistry) на основе публичного репозитория достаточно заполнить два поля, если внешний репозиторий приватный, придётся заполнить четыре поля.
:::

## Cсылка на репозиторий GIT

Требования:
1. `http://` или `https://` в начале ссылки
1. `.git` в конце ссылки

:::danger
Устанавливается один раз в момент создания
:::

## Тип GIT Платформы
1. Выберите [GitLab](/definitions#gitlab) или [GitHub](/definitions#github)

:::danger
Устанавливается один раз в момент создания
:::

## Доступ до закрытого репозитория
Установите флаг `Private ?` в состояние `True` для [Git](/definitions#git) репозитория, требующего авторизацию. Далее вам будет предложено ввести `username` и `pat-token`.

Авторизационные данные будут применены во время выполнения команды `git pull` силами [Backend](/deployment/dependencies/backend). В момент получения данных от внешнего сервиса `link` будет представлять из себя `https://username:pat-token@domain.com/abracadabra/test.git`.

:::warning
Все [Пользователи](/development-pepeunit/mechanics/roles#user) инcтанса смогут увидеть приватный репозиторий, но создать от него [Repo](/definitions#repo) смогут только те, кто обладают кредами доступа с уровнем `Valid`. Проверить свой уровень можно, перейдя в модальное окно [RepositoryRegisty](/definitions#repositoryregistry) через поиск и нажав кнопку `Change GIT Credentials`.
:::

:::info
Креды хранится в [шифрованном](/development-pepeunit/mechanics/cipher) виде.
:::
