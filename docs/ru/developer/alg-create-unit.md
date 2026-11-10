# Алгоритм создания Unit

Руководство составлено на основе готового [Fan Regulator ds18b20](https://git.pepemoss.com/pepe/pepeunit/units/esp32/fan-regulator-ds18b20.git).

## Проработка идеи Unit

Прежде чем писать код, ответьте себе на вопросы:
1. Какую задачу решает Unit?
1. Из каких физических элементов он состоит?
1. Какие данные публикует?
1. Какие команды принимает?
1. На каком языке написан?

:::info Например
1. Регулирует температуру вентилятором
1. Нужны esp32, вентилятор с 4 pin и датчик температуры ds18b20
1. Публикует скважность PWM сигнала и температуру
1. Принимает команду: включиться на N секунд с заданной скоростью
1. Micropython
:::

## Создание репозитория Git

1. Создайте пустой репозиторий на GitLab или GitHub
1. Склонируйте его на свой компьютер

## Создание базовой файловой структуры

Создайте в корне репозитория пустые файлы и заполните их по образцу из статей. Все файлы описаны в [структуре Git репозитория](/developer/files/struct-git-repo).

- [.gitignore](/developer/files/struct-gitignore#пример): добавьте папку своей IDE, если её нет в списке. env.json и schema.json содержат секреты инстанса, их нельзя публиковать
- [.pepeignore](/developer/files/struct-pepeignore): всё, что не должно попасть на устройство
- [schema_example.json](/developer/files/struct-schema-example-json#структура): стандартные топики и ваши. Fan Regulator добавляет `set_fan_state/pepeunit` в input_topic, `current_fan_speed_percentage/pepeunit` и `current_temp/pepeunit` в output_topic
- [env_example.json](/developer/files/struct-env-example-json#структура): стандартные переменные с префиксом PU_ Pepeunit заполнит сам, остальные придумываете вы
- LICENSE

:::warning
Переменные можно менять в процессе разработки. Обновите env_example.json, pepeunit.toml и readme.md. [Пользователи](/development-pepeunit/mechanics/roles#user) увидят новые переменные, когда перейдут на новую версию.
:::

## Первый коммит

```bash
git add .
git commit -m "feat(init): initial files"
git push
```

## Создание тестового Unit в Pepeunit

Чтобы разрабатывать Unit, нужны живая связь с Pepeunit по MQTT, а также env.json и schema.json. Выберите инстанс, которому доверяете, и в клиенте:
1. `Репозитории` → `Добавить репозиторий`: укажите ссылку на ваш репозиторий. Для приватного понадобятся креды, то есть имя и токен доступа
1. Откройте репозиторий → `Создать аппарат`: Unit создаётся из Repo
1. В `Обновления` выберите ручное обновление, чтобы самим решать, какая [версия](/development-pepeunit/mechanics/update-system#алгоритм-вычисления-текущеи-версии-unit) у Unit
1. Откройте Unit → `Переменные окружения` и заполните их
1. `Управление аппаратом` → `Архивы программ`: скачайте [архив](/developer/files/struct-archive-update) с env.json и schema.json

Положите env.json и schema.json в папку репозитория: в них адрес инстанса, токен и адреса топиков.

Во время разработки в Unit видно, что он присылает в Output UnitIO, в том числе через [DataPipe](/deployment/dependencies/datapipe), и можно отправить команду в Input UnitIO.

## Наполнение Unit программным функционалом

Универсального алгоритма разработки нет, работайте как удобно, но придерживайтесь общих правил чистоты кода. Когда есть связь с Pepeunit, двигайтесь так:
1. Проверьте, что клиентская [библиотека](/developer/libraries/framework) получает [стандартные команды](/developer/mqtt/default-mqtt-command) и отправляет [состояние](/developer/mqtt/state-mqtt-send)
1. Получите данные с датчиков и выведите их в консоль, без сети: так видно, что данные настоящие
1. Отправьте данные в output_topic из schema_example.json
1. Получите команды из input_topic и обработайте их
1. Подключите переменные из env_example.json, чтобы Unit можно было настроить удалённо

Коммитьте как угодно: ветки, рабочие и нерабочие версии, всё допустимо. Когда всё работает, переходите дальше.

## Создание pepeunit.toml и readme.md

1. Создайте в корне репозитория pepeunit.toml, формат описан в [pepeunit.toml](/developer/files/struct-pepeunit-toml). Fan Regulator описывает свои топики и переменные там же, в примере
1. [Сгенерируйте](/developer/files/struct-readme#генерация-readme-md) по нему readme.md и положите в корень репозитория. Вручную его писать не нужно

:::danger
У каждого Unit должна быть документация, иначе [Пользователи](/development-pepeunit/mechanics/roles#user) не поймут, как им пользоваться.
:::

## Присвоение Тега

Когда pepeunit.toml и readme.md готовы, а Unit работает, поставьте Тег на последний коммит:

```bash
git tag 1.0.0
git push --tags
```

Формат Тега не ограничен, сам Pepeunit везде использует major.minor.fix.

:::danger
Тег говорит [Пользователям](/development-pepeunit/mechanics/roles#user), что версия готова и проверена [Разработчиком Unit](/development-pepeunit/mechanics/roles#unit-developer). Выбирая последний Тег, они ждут самую рабочую и актуальную версию.
:::
