###
# This file is defined in the user Docker image and
# will be overwritten each time the server starts.
###

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/gcloud/google-cloud-sdk/path.bash.inc' ]; then . '/gcloud/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/gcloud/google-cloud-sdk/completion.bash.inc' ]; then . '/gcloud/google-cloud-sdk/completion.bash.inc'; fi

parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "

chmod 600 ~/.ssh/id_ed25519
eval `keychain --eval --agents ssh id_ed25519`
