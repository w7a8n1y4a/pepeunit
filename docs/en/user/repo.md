# Repositories

A `Repo` is a copy of a Git repository with a program for a `Unit`. It lives on the instance and is hosted on `GitLab` or `GitHub`. How to prepare such a repository: [Unit creation algorithm](/developer/alg-create-unit). Public `Repo` of other instances appear on their own, see [Federation](/development-pepeunit/mechanics/federation).

## Add

`Repositories` → `Add repository`:

Cell | What to enter
-- | --
`Link` | An `http(s)` link ending in `.git`
`Platform` | `GitHub` or `GitLab`
`Public` / `Private` | A tap switches the access kind
`Credentials` | For a private `Repo`: a user name and an access token

Then `Add`. The token is stored on the instance [encrypted](/development-pepeunit/mechanics/cipher).

## Private Repo

A private `Repo` is visible in the list to everyone signed in, but it can be synchronized and `Unit` can be created from it only with your own credentials. Open the `Repo` → `Credentials` and enter your own name and token. See [Visibility](/development-pepeunit/mechanics/visibility).

## Repo card

`Repositories` → `Search`: a search field by address and a filter by access kind. The card shows the access kind, the size, and the number of `Unit`.

Cell | What it does
-- | --
`Summary` | Branches, commits, and other details. The icon copies the link
`Create unit` | Opens [Unit creation](/user/unit/create-unit) from this `Repo`
`Synchronize repo` | Updates the local copy from Git
`Credentials` | Your own name and token, only for a private `Repo`
`Branches` | The list of branches
`Delete` | Only the creator, and only if the `Repo` has no `Unit`

If a new branch or commit is not in the list, tap `Synchronize repo`: the sync status is visible on the cell. The `Repo` itself is updated every hour at `:30`, see the [Update system](/development-pepeunit/mechanics/update-system#repo-update).
