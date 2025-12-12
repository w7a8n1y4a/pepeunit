# Configuring a Repo

## Mass update flags

This block controls mass updates of [Unit](/en/definitions#unit) objects from the side of a [Repo](/en/definitions#repo). The configuration uses two flags and the ability to select a [commit](/en/definitions#git-commit). Available combinations:

1. `Auto-update = True` and `Tags-only = False` — the [Repo](/en/definitions#repo) will poll the external [Git](/en/definitions#git) repository every hour for new [commits](/en/definitions#git-commit). As soon as they appear, the [commits](/en/definitions#git-commit) in the local [Pepeunit](/en/conception/overview) storage will be synchronized with the external repository. All child [Unit](/en/definitions#unit) objects that have allowed automatic updates via this [Repo](/en/definitions#repo) will receive an update request.
1. `Auto-update = True` and `Tags-only = True` — same as the previous option, but an update request for [Unit](/en/definitions#unit) will be sent only when a new [Tag](/en/definitions#git-tag) appears.
1. `Auto-update = False` and `Commit = <best-commit-pick>` — if you set a specific [commit](/en/definitions#git-commit) and click `Update`, all [Unit](/en/definitions#unit) objects that are configured to auto-update from this [Repo](/en/definitions#repo) will receive an update request corresponding to the current [branch](/en/definitions#git-branch) and [commit](/en/definitions#git-commit).

::::warning
These update methods work only for [Unit](/en/definitions#unit) objects that have automatic updates enabled.
::::


