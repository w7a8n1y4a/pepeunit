# Git repository structure

::::danger

[Pepeunit](/en/conception/overview) has strict requirements for repository size, because repositories are stored on the [Pepeunit](/en/conception/overview) instances themselves.

The default limit is `50 MB`, but instance [Administrators](/en/development-pepeunit/mechanics/roles#admin) can increase this limit by setting `PU_MAX_EXTERNAL_REPO_SIZE` in the [Backend ENV](/en/deployment/env-variables/backend).

To meet this strict requirement, it is not recommended to store images and binary files in repositories.

For microcontrollers, [Pepeunit](/en/conception/overview) includes a repository‑cleanup mechanism that runs before generating the program archive. This algorithm removes certain files and directories. You can read more about this mechanism in the section [Structure of update archives](/en/developer/files/struct-archive-update).
::::

## File set in a Unit repository

[Pepeunit](/en/conception/overview) expects to see the following files in a [Unit](/en/definitions#unit) repository:

```bash
$> tree -a -L 2
.
├── env_example.json
├── .git
│   └── ...
├── .gitignore
├── LICENSE
├── .pepeignore
├── pepeunit.toml
├── README.md
└── schema_example.json
```

- [schema_example.json](/en/definitions#schema-example-json)
- [env_example.json](/en/definitions#env-example-json)
- [pepeunit.toml](/en/definitions#pepeunit-toml)
- [readme.md](/en/definitions#readme-md)
- [.gitignore](/en/definitions#gitignore)
- [.pepeignore](/en/definitions#pepeignore)
- [LICENSE](/en/definitions#license)


