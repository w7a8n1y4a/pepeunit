# Компиляция для различных платформ

Из-за особенностей [Компилируемых](/definitions#compilable) программ их способ доставки [Пользователям](/development-pepeunit/mechanics/roles.html#user) отличается от [Интерпритируемых](/definitions#interpreterable). Чтобы конечному [Пользователю](/development-pepeunit/mechanics/roles.html#user) не приходилось постоянно компилировать исходный код, для получения бинарного файла, в хостингах [Git](/definitions#git) репозиториев [Gitlab](/definitions#gitlab) и [Github](/definitions#github) предусмотренна система релизов.

В каждый релиз можно добавить бинарные файлы, с определённым названием - такие пары обычно называют `assets`. [Gitlab](/definitions#gitlab) и [Github](/definitions#github) позволяют через свои [API](/definitions#api) получать соответствие названия `assets` и ссылки на бинарный файл.

:::info
На основе данной механики [Pepeunit](/conception/overview) имеет возможность обновлять [Компилируемые](/definitions#compilable) репозитории в автоматическом режимие. Единственное условие, названия `assets` должны быть сквозными между различными релизами.
:::

:::warning
Соответственно если [Разработчик](/development-pepeunit/mechanics/roles#unit-developer) [Компилируемого](/definitions#compilable) [Unit](/definitions#unit) хочет добавить поддержку автоматического обновления в [Pepeunit](/conception/overview), ему придётся скомпилировать и загрузить в [Gitlab](/definitions#gitlab) или [Github](/definitions#github) версии своей программы для каждой платформы. При этом название для одной и той же платформы в разных релизах должно быть одинаковым.
:::

## Пример хорошего наименования assets между релизами
- `Release 1.0.0` - `linux-amd64` `macos`
- `Release 1.0.1` - `linux-amd64` `win64` `macos`
- `Release 1.1.0` - `linux-amd64` `win64` `macos`
- `Release 1.2.0` - `linux-amd64` `win64`

Рассмотрим логику [Pepeunit](/conception/overview) в этом сценарии для каждой из платформ `linux-amd64`, `win64` и `macos`:
- для `linux-amd64` - [Unit](/definitions#unit) будет штатно обновлять все версии
- для `win64` - [Unit](/definitions#unit) можно будет создать начиная с версии `1.0.1`, далее обновления будут идти штатно
- для `macos` - [Unit](/definitions#unit) будет шататно обновляться до версии `1.1.0`, далее автоматическое обновление будет прервано

## Пример плохого наименования assets между релизами
- `Release 1.0.0` - `linux-amd64-1.0.0` `macos-one`
- `Release 1.0.1` - `linux-amd64-1.0.1` `win64-and-x86` `macos-two`
- `Release 1.1.0` - `linux-amd64-1.1.0` `win64` `macos-three`
- `Release 1.2.0` - `linux-amd64-1.2.0` `win64-and-x68`

В данном случае [Pepeunit](/conception/overview) не сможет автоматически обновлять [Unit](/definitions#unit). Корректно будет работать только ручное обновление, платформу для каждой версии придётся скачивать вручную.

