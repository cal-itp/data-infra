(github_setup)=
# GitHub Setup

## Table of Contents
1. [Onboarding Setup](#onboarding-setup)
    * [Adding a GitHub SSH Key to Jupyter](authenticating-github-jupyter)
    * [Persisting your SSH Key and Enabling Extensions](persisting-ssh-and-extensions)
    * [Cloning a Repository](cloning-a-repository)

## Onboarding Setup

We'll work through getting set up with SSH and GitHub on JupyterHub and cloning one GitHub repo. This is the first task you'll need to complete before contributing code. Repeat the steps in [Cloning a Repository](cloning-a-repository) for other repos.

(authenticating-github-jupyter)=
### Authenticating to GitHub via the gh CLI

> This section describes using the GitHub CLI to set up SSH access, but the generic instructions can be found [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

1. Create a GitHub username if necessary and ensure you're added to the appropriate Cal-ITP teams on GitHub. You'll be committing directly into the Cal-ITP repos!
2. Open a terminal in JupyterHub. All of our commands will be typed in this terminal.
3. `gh auth login` and select the following options
```
(base) jovyan@f4b18b106c18:~$ gh auth login
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations? SSH
? Generate a new SSH key to add to your GitHub account? Yes
? Enter a passphrase for your new SSH key (Optional)
? Title for your SSH key: GitHub CLI
? How would you like to authenticate GitHub CLI? Login with a web browser
```
You can press `Enter` to leave the passphrase empty, or you may provide a password; in the future, you will need to enter this password when your server starts. If you've already created an SSH key, you will be prompted to select the existing key rather than creating a new one.

4. You will then be given a one-time code and instructed to press `Enter` to open a web browser, which will fail if you are using JupyterHub. However, you can manually open the link in a browser and enter the code. You will end up with output similar to the following.
```
! First copy your one-time code: ABCD-1234
Press Enter to open github.com in your browser...
...
! Failed opening a web browser at https://github.com/login/device
  exit status 3
  Please try entering the URL in your browser manually
✓ Authentication complete.
- gh config set -h github.com git_protocol ssh
✓ Configured git protocol
✓ Uploaded the SSH key to your GitHub account: /home/jovyan/.ssh/id_ed25519.pub
✓ Logged in as atvaccaro
```

After completing the steps above be sure to complete the section below to persist your SSH key between sessions and enable extensions.

(persisting-ssh-and-extensions)=
### Persisting your SSH Key and Enabling Extensions
To ensure that your SSH key settings persist between your sessions, run the following command in the Jupyter terminal.
* `echo "source .profile" >> .bashrc`


Now, restart your Jupyter server by selecting:
* `File` -> `Hub Control Panel` -> `Stop Server`, then `Start Server`


From here, after opening a new Jupyter terminal you should see the notification:
* `ssh-add: Identities added: /home/jovyan/.ssh/id_ed25519`


If the above doesn't work, try:
* Closing your terminal and opening a new one
* Following the instructions to restart your Jupyter server above
* Substituting the following for the `echo` command above and re-attempting:
    * `echo "source .profile" >> .bash_profile`
* Following the steps below to change your .bash_profile:
    * In terminal use `cd` to navigate to the home directory (not a repository)
    * Type `nano .bash_profile` to open the .bash_profile in a text editor
    * Change `source .profile` to  `source ~/.profile`
    * Exit with Ctrl+X, hit yes, then hit enter at the filename prompt
    * Restart your server; you can check your changes with `cat .bash_profile`

After completing this section, you will also enjoy various extensions in Jupyter, such as `black` hotkey auto-formatting with `ctrl+shft+k`, and the ability to see your current git branch in the Jupyter terminal.

(cloning-a-repository)=
### Cloning a Repository
1. Navigate to the GitHub repository to clone. We'll work our way through the `data-analyses` [repo here](https://github.com/cal-itp/data-analyses). Click on the green `Code` button, select "SSH" and copy the URL.
   1. You may be prompted to accept GitHub key's fingerprint if you are cloning a repository for the first time.
2. Clone the Git repo: `git clone git@github.com:cal-itp/data-analyses.git`
3. Double check  with `ls` to list and see that the remote repo was successfully cloned into your "local" (cloud-based) filesystem.
4. Change into the `data-analyses` directory: `cd data-analyses`
5. Pull from the `main` branch and sync your remote and local repos: `git pull origin main`
