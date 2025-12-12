# Creating a RepositoryRegistry

::::info Where to find it?
On the instance main page, find the search button in the top left corner. Select the `Registry` entity. In the bottom left part of the modal window you can click the `Create Registry` button.
::::

::::info What do you need?
To create a [RepositoryRegisty](/en/definitions#repositoryregistry) based on a public repository, it is enough to fill in two fields. If the external repository is private, you will have to fill in four fields.
::::

## Link to the GIT repository

Requirements:
1. `http://` or `https://` at the beginning of the URL
1. `.git` at the end of the URL

::::danger
This is set only once at creation time
::::

## Type of GIT platform

1. Choose [GitLab](/en/definitions#gitlab) or [GitHub](/en/definitions#github)

::::danger
This is set only once at creation time
::::

## Access to a private repository

Set the `Private ?` flag to `True` for a [Git](/en/definitions#git) repository that requires authorization. You will then be prompted to enter a `username` and `pat-token`.

These credentials will be used when executing `git pull` by the [Backend](/en/deployment/dependencies/backend). At the time of requesting data from the external service the `link` will look like: `https://username:pat-token@domain.com/abracadabra/test.git`.

::::warning
All [Users](/en/development-pepeunit/mechanics/roles.html#user) of the instance will be able to see the private repository, but only those who have credentials with a `Valid` level will be able to create a [Repo](/en/definitions#repo) from it. You can check your level by opening the [RepositoryRegisty](/en/definitions#repositoryregistry) modal via search and clicking the `Change GIT Credentials` button.
::::

::::info
Credentials are stored in an [encrypted](/en/development-pepeunit/mechanics/cipher) form.
::::


