# GIT repository structure

:::danger
Pepeunit stores a copy of every Repo on the instance, so the size is limited. By default it is 50 MB, the instance owner changes the limit with the pu_instance_repo_max_size setting, see [instance settings](/deployment/instance-settings#repositories). If a Repo is larger, synchronization ends with an error.

Do not store images or binary files in the repository.
:::

## Set of files in a Unit repository

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

File | Required | Purpose
-- | -- | --
[schema_example.json](/developer/files/struct-schema-example-json) | Required, a Unit cannot be created without it | Unit topics
[env_example.json](/developer/files/struct-env-example-json) | Required, a Unit cannot be created without it | Unit environment variables
[pepeunit.toml](/developer/files/struct-pepeunit-toml) | Recommended | Machine-readable description of the Unit
[readme.md](/developer/files/struct-readme) | Recommended | Documentation for Users, generated from pepeunit.toml
[.gitignore](/developer/files/struct-gitignore) | Recommended | Prevents env.json and schema.json from being published
[.pepeignore](/developer/files/struct-pepeignore) | For interpreted Units | What will not end up on the device
LICENSE | Recommended | Project license
