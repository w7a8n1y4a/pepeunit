# .gitignore

:::info
Перечисляет файлы и папки, которые Git не должен версионировать. Обычно это:
1. Окружения библиотек, например .venv в Python
1. Секреты, которые нельзя публиковать. Для Pepeunit это env.json и schema.json, в других проектах такую роль часто играют файлы .env
:::

## Пример

```gitignore
.idea
.nvim
env.json
schema.json
tmp
```
