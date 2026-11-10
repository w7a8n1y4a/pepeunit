# .pepeignore

:::info Зачем нужно удаление?
Память микроконтроллеров ограничена. Например, лицензия AGPL v3 весит 33.71 кБ и может занять почти всю flash память. Поэтому перед сборкой архива всё лишнее убирают.
:::

.pepeignore работает как .gitignore: в нём шаблоны файлов и папок. Pepeunit находит всё, что им соответствует, и удаляет.

Очистка идёт при сборке архива для Unit, [подробнее](/developer/files/struct-archive-update). Пример:

```text
.git
.gitignore
.pepeignore
env_example.json
schema_example.json
pepeunit.toml
README.md
LICENSE
```

:::warning
Включите в список .git: без этого история репозитория попадёт на устройство. Если файла .pepeignore нет, не удаляется ничего.
:::

:::info
У компилируемых Unit репозиторий в архив не попадает совсем, поэтому .pepeignore им не нужен.
:::
