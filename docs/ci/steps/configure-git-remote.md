# configure-git-remote

Ensure the presence of a git remote in the local repo.

## Variables

- `CONFIGURE_GIT_REMOTE_NAME`: The name of the git remote to configure
- `CONFIGURE_GIT_REMOTE_URL`: The url to be pointed to by
 `CONFIGURE_GIT_REMOTE_NAME`. If `CONFIGURE_GIT_REMOTE_NAME` already exists and
 points to a different url, it will be updated to point to
 `CONFIGURE_GIT_REMOTE_URL`.
