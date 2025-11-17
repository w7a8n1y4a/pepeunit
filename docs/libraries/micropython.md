# Micropython

:::info
Интерпритируемый и при этом имеет полную функциональность [Pepeunit Framework](/libraries/framework)
:::

## Ссылки

Все подробности в `readme.md` репозитория

- [Релизы с Micropython образми](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/releases)
- [Github (зеркало) для issues](https://github.com/w7a8n1y4a/pepeunit_micropython_client.git)
- [Gitlab для разработки](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client.git)

## Версии

### esp8266 и esp32

0. [ESP8266_GENERIC-v1.26.1-PEPEUNIT-v0.10.0.bin](https://git.pepemoss.com/pepe/pepeunit/libs/pepeunit_micropython_client/-/package_files/43/download)

## Важные нюансы

1. Библиотека протестирована для `esp32` и `esp8266`
1. На `esp8266` из `38кБ` остаются свободными `19-21кБ` опретивной памяти, после полной инициализации библиотеки, как в примере
1. Ввиду отсутствия поддержки `https` на `esp8266` поддерживается только `http` при работе через [REST](/definitions#rest)
1. Сама по себе библиотека уже встроена в образ `Micropython` при помощи `freeze`, благодаря этому удалось сильно освободить оперативную память. Такое решение было принято ввиду очень малого объёма оперативной памяти при установке даже через `.mpy` файлы.
1. В кастомный `Micropython` помимо текущей библиотеки также встроены:
    - [mrequests](https://github.com/SpotlightKid/mrequests.git)
    - [shutil](https://github.com/micropython/micropython-lib/blob/master/python-stdlib/shutil/shutil.py)
    - [tarfile](https://github.com/micropython/micropython-lib/blob/master/python-stdlib/tarfile/tarfile/__init__.py)
    - [umqtt.simpe](https://github.com/micropython/micropython-lib/blob/master/micropython/umqtt.simple/umqtt/simple.py)
