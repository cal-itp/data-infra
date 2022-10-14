(github_setup)=
# GitHub Setup

## Table of Contents
1. [Onboarding Setup](#onboarding-setup)
    * [Adding a GitHub SSH Key to Jupyter](adding-ssh-to-jupyter)
    * [Persisting your SSH Key and Enabling Extensions](persisting-ssh-and-extensions)
    * [Cloning a Repository](cloning-a-repository)

## Onboarding Setup

We'll work through getting set up with SSH and GitHub on JupyterHub and cloning one GitHub repo. This is the first task you'll need to complete before contributing code. Repeat the steps in [Cloning a Repository](cloning-a-repository) for other repos.

(adding-ssh-to-jupyter)=
### Adding a GitHub SSH Key to Jupyter

Generating and adding an SSH key authenticates your local environment with our GitHub organization. For more information on what's below, you can navigate to the [GitHub directions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) and follow the Linux instructions for each step.
1. Create a GitHub username if necessary and ensure you're added to the appropriate Cal-ITP teams on GitHub. You'll be committing directly into the Cal-ITP repos!
1. Open a terminal in JupyterHub. All of our commands will be typed in this terminal.
1. Set up SSH by following these directions:
    * Run the following command in the terminal, replacing what's inside the quotes with the email address your GitHub account is associated with:
        * `ssh-keygen -t ed25519 -C "your_email@example.com"`
    * After that, select `enter` to store it in the default location, and select `enter` twice more to bypass creating a passphrase
    * Run the following command to "start" ssh key in the background, which should return a response similar to `Agent pid 258`
        * `eval "$(ssh-agent -s)"`
    * Add the ssh key to the ssh agent with this command
        * `ssh-add ~/.ssh/id_ed25519`
    * From here we will copy the contents of your public ssh file, which we will first do by viewing it's contents.
        * To view:
            * `cat ~/.ssh/id_ed25519.pub`
        * Then, select and copy the entire contents of the file that display
            * The text should begin with `ssh-ed25519` and end with your GitHub email address
            * Beware of copying white spaces, which may cause errors in the following steps


    * Once copied, navigate to GitHub
    * In the top right corner, select `Settings` and then select `SSH and GPC Keys` in the left sidebar
    * Select `New SSH Key`
        * For the title add something like ‘JupyterHub’
        * Paste the key that you copied into key field
    * Click `Add SSH Key`, and, if necessary, enter password


    * After you've added your SSH key to your GitHub account, open a new Jupyter terminal window and you'll be able to test your connection with:
        * `ssh -T git@github.com`

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
1. Clone the Git repo: `git clone git@github.com:cal-itp/data-analyses.git`
1. Double check  with `ls` to list and see that the remote repo was successfully cloned into your "local" (cloud-based) filesystem.
1. Change into the `data-analyses` directory: `cd data-analyses`
1. Pull from the `main` branch and sync your remote and local repos: `git pull origin main`
