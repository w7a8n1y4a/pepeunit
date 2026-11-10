# readme.md

readme.md is the Unit documentation and the most important file of the repository: how easy it is for other people to use the Unit depends on how complete it is. So that the documentation of all Units looks the same, the client has a generator: it turns [pepeunit.toml](/developer/files/struct-pepeunit-toml) into readme.md.

## Generating readme.md

In the client open `Library` → `Tools` → `README generator` and choose pepeunit.toml, or drag the file onto the cell. After that README.md is saved automatically. The generator is available after signing in to an account.

If pepeunit.toml has an error (a [limit](/developer/files/struct-pepeunit-toml#filling-in-general) is exceeded or the syntax is wrong), the generator will show it.
