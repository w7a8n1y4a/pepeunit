# .pepeignore

Microcontroller memory is limited: for example, the AGPL v3 license weighs 33.71 kB and can take up almost all of the flash memory. So everything unnecessary is removed when [building the archive](/developer/files/struct-archive-update).

.pepeignore works like .gitignore: it contains patterns of files and folders. Pepeunit finds everything that matches them and deletes it. Example:

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
Include .git in the list: without it the repository history will end up on the device. If there is no .pepeignore file, nothing is deleted.
:::

For compiled Units the repository does not get into the archive at all, so they do not need .pepeignore.
