# .pepeignore

::::info Why do we need deletion?
Microcontroller memory is limited. For example, a `LICENSE AGPL v3` file of size `33.71 kB` can occupy almost all available flash memory, which is unacceptable. Therefore, before creating the archive, you must clean up unnecessary files.
::::

[.pepeignore](/en/definitions#pepeignore) defines file and directory patterns similarly to [.gitignore](/en/definitions#gitignore). [Pepeunit](/en/conception/overview) collects the paths of all files that match these patterns and deletes them.

Cleanup happens when generating an update archive for a [Unit](/en/definitions#unit). Example:

```gitignore
.git
.gitignore
.pepeignore
env_example.json
schema_example.json
pepeunit.toml
README.md
LICENSE
```


