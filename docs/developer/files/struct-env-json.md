# env.json

:::warning Какое функциональное назначание у [env.json](/definitions#env-json)?
Данный файл - это четырёхсторонний контракт между [Unit](/definitions#unit), [Pepeunit](/conception/overview), [Пользователем](/development-pepeunit/mechanics/roles.html#user) и [Администратором](/development-pepeunit/mechanics/roles#admin) [инстанса](/definitions#instance) [Pepeunit](/conception/overview):
1. [Unit](/definitions#unit) гарантирует всем сторонам, что будет использовать для соответствующих значений из [env_example.json](/definitions#env-example-json) значения из [env.json](/definitions#env-json)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что при первой установке переменных окружения в [env.json](/definitions#env-json), сгенерирует стандартные переменные
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что [Unit](/definitions#unit) сможет пройти авторизацию для топиков и соединений в [EMQX MQTT Broker](/definitions#mqtt-broker), авторизацию [Backend](/definitions#backend) с использованием `PU_AUTH_TOKEN`
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, возможность изменения [env.json](/definitions#env-json)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что [env.json](/definitions#env-json) будет храниться в [шифрованном виде](/development-pepeunit/mechanics/cipher#шифрование)
1. [Pepeunit](/conception/overview) гарантирует всем сторонам, что доступ до [env.json](/definitions#env-json) будет предоставлен только создателю [Unit](/definitions#unit)
1. [Aдминистратор](/development-pepeunit/mechanics/roles#admin) гарантирует всем сторонам, что [env.json](/definitions#env-json) ни в каком виде не будет передан тем кто не явялется стороной данного контракта.
:::

Файлы окружения, такие как [env.json](/definitions#env-json) или [Backend ENV](/deployment/env-variables#backend), представляют собой механизм индивидуализации общего кода под конкретное устройство или экземпляр приложения.

::: danger
Используйте только доверенные [инстансы](/definitions#instance) [Pepeunit](/conception/overview). Следите, чтобы [Администратор](/development-pepeunit/mechanics/roles#admin) [инстанса](/definitions#instance) [Pepeunit](/conception/overview) выполнял свои контрактные обязательства, связанные с [env.json](/definitions#env-json).
:::

:::info Какие основные свойства можно выделить у [env.json](/definitions#env-json)?
1. [env.json](/definitions#env-json) файл секретен, его нельзя передавать кому-либо
1. [env.json](/definitions#env-json) файл позволяет удобно конфигурировать и обновлять состояние [Unit](/definitions#unit) без полного обновления файлов программы
1. [env.json](/definitions#env-json) файл позволяет [Unit](/definitions#unit) знать какому [инстансу](/definitions#instance) [Pepeunit](/conception/overview) он принадлежит
1. [env.json](/definitions#env-json) файл при помощи переменной `PU_AUTH_TOKEN` позволяет [Pepeunit](/conception/overview) производить авторизацию для конкретных [Unit](/definitions#unit)
:::