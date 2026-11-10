# .gitignore

:::info
Lists the files and folders that Git must not version. Usually these are:
1. Library environments, for example .venv in Python
1. Secrets that must not be published. For Pepeunit these are env.json and schema.json, in other projects .env files often play this role
:::

## Example

```gitignore
.idea
.nvim
env.json
schema.json
tmp
```
