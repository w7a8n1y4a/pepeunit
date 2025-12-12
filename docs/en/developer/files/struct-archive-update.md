# Structure of update archives

::::info
[Pepeunit](/en/conception/overview) can generate ready‑to‑use update archives for a [Unit](/en/definitions#unit). The generation algorithm is different for [Compilable](/en/definitions#compilable) and [Interpretable](/en/definitions#interpretable) [Repos](/en/definitions#repo).
::::

## Compilable

1. The [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) is calculated.
1. [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json) are added based on the [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version).
1. The [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) is written into [env.json](/en/definitions#env-json) as `PU_COMMIT_VERSION`.
1. The archive file (`tgz`, `tar`, or `zip`) is created.

## Interpretable

1. The [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) is calculated.
1. A temporary view of the files in the corresponding [commit](/en/definitions#git-commit) is created.
1. Files that are not involved in the [Unit](/en/definitions#unit) operation are removed based on [.pepeignore](/en/definitions#pepeignore).
1. [env.json](/en/definitions#env-json) and [schema.json](/en/definitions#schema-json) are added based on the [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version).
1. The [target version](/en/development-pepeunit/mechanics/update-system#algorithm-for-calculating-the-current-unit-version) is written into [env.json](/en/definitions#env-json) as `PU_COMMIT_VERSION`.
1. The archive file (`tgz`, `tar`, or `zip`) is created.


