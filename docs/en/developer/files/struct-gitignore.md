# .gitignore

::::info
Contains files and directories that [Git](/en/definitions#git) should ignore when tracking changes. Typically these fall into the following categories:

1. Runtime or virtual environments created by libraries, e.g. `.venv` for Python.
1. Secrets that must not be committed. In the context of [Pepeunit](/en/conception/overview), these are [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json); in other repositories, `.env` files often serve a similar purpose.
::::

## Example

```gitignore
.idea
.nvim
env.json
schema.json
tmp
```


