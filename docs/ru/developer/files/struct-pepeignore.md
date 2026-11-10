# .pepeignore

Память микроконтроллеров ограничена: например, лицензия AGPL v3 весит 33.71 кБ и может занять почти всю flash память. Поэтому при [сборке архива](/developer/files/struct-archive-update) всё лишнее убирают.

.pepeignore работает как .gitignore: в нём шаблоны файлов и папок. Pepeunit находит всё, что им соответствует, и удаляет. Пример:

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

У компилируемых Unit репозиторий в архив не попадает совсем, поэтому .pepeignore им не нужен.
