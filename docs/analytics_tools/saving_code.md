(saving-code)=
# Saving Code

Most Cal-ITP analysts should opt for working and committing code directly from JupyterHub. Leveraging this cloud-based, standardized environment should alleviate many of the pain points associated with creating reproducible, collaborative work.

Doing work locally and pushing directly from the command line is a similar workflow, but replace the JupyterHub terminal with your local terminal.

## Table of Contents
1. [Committing from JupyterHub](#pushing-from-jupyterhub)
    * [Onboarding Setup](#onboarding-setup)
        * [Adding a GitHub SSH Key to Jupyter](adding-ssh-to-jupyter)
        * [Persisting your SSH Key and Enabling Extensions](persisting-ssh-and-extensions)
        * [Cloning a Repository](cloning-a-repository)
    * What's a typical [project workflow](#project-workflow)?
    * Someone is collaborating on my branch, how do we [stay in sync](#pulling-and-pushing-changes)?
    * The `main` branch is ahead, and I want to [sync my branch with `main`](rebase-and-merge)
    * Options to [Resolve Merge Conflicts](resolve-merge-conflicts)
    * [Helpful Hints](#helpful-hints)
    * [External Git Resources](external-git-resources)
2. [Committing in the Github User Interface](#pushing-drag-drop)

(committing-from-jupyterhub)=
## Committing from JupyterHub

### Onboarding Setup

We'll work through getting set up with SSH and GitHub on JupyterHub and cloning one GitHub repo. Repeat the steps in [Cloning a Repository](cloning-a-repository) for other repos

(adding-ssh-to-jupyter)=
#### Adding a GitHub SSH Key to Jupyter
(github-setup)=
For more information on what's below, you can navigate to the [GitHub directions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) and follow the Linux instructions for each step.
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
#### Persisting your SSH Key and Enabling Extensions
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

After completing this section, you will also enjoy various extensions in Jupyter, such as `black` hotkey auto-formatting with `ctrl+shft+k`, and the ability to see your current git branch in the Jupyter terminal.

(cloning-a-repository)=
#### Cloning a Repository
1. Navigate to the GitHub repository to clone. We'll work our way through the `data-analyses` [repo here](https://github.com/cal-itp/data-analyses). Click on the green `Code` button, select "SSH" and copy the URL.
1. Clone the Git repo: `git clone git@github.com:cal-itp/data-analyses.git`
1. Double check  with `ls` to list and see that the remote repo was successfully cloned into your "local" (cloud-based) filesystem.
1. Change into the `data-analyses` directory: `cd data-analyses`
1. Pull from the `main` branch and sync your remote and local repos: `git pull origin main`

### Project Workflow

It is best practice to do have a dedicated branch for your task. A commit in GitHub is similar to saving your work. It allows the system to capture the changes you have made and offers checkpoints through IDs that both show the progress of your work and can be referenced for particular tasks.

In the `data-analyses` repo, separate analysis tasks live in their own directories, such as `data-analyses/gtfs_report_emails`.

1. Start from the `main` branch: `git pull origin main`
1. Check out a new branch to do your work: `git checkout -b my-new-branch`
1. Do some work...add, delete, rename files, etc
1. See all the status changes to your files: `git status`
1. When you're ready to save some of that work, stage the files you want to commit with `git add foldername/notebook1.ipynb foldername/script1.py`. To stage all the files, use `git add .`.
1. Once you are ready to commit, add a commit message to associate with all the changes: `git commit -m "exploratory work" `
1. Push those changes from local to remote branch (note: branch is `my-new-branch` and not `main`): `git push origin my-new-branch`.
1. To review a log of past commits: `git log`
1. When you are ready to merge all the commits into `main`, open a pull request (PR) on the remote repository, and merge it in!
1. Go back to `main` and update your local to match the remote: `git checkout main`, `git pull origin main`


### Pulling and Pushing Changes

Especially when you have a collaborator working on the same branch, you want to regularly sync your work with what's been committed by your collaborator. Doing this frequently allows you to stay in sync, and avoid unnecessary merge conflicts.

1. Stash your changes temporarily: `git stash`
1. Pull from the remote to bring the local branch up-to-date (and pull any changes your collaborator made): `git pull origin my-new-branch`
1. Pop your changes: `git stash pop`
1. Stage and push your commit with `git add` and `git commit` and `git push origin my-new-branch`

(rebase-and-merge)=
### Syncing my Branch with Main
If you find that the `main` branch is ahead, and you want to sync your branch with `main` you'll need to use one of the below commands:

* [Rebase](#rebase)
* [Merge](#merge)

Read more about the differences between `rebase` and `merge`:
* [Atlassian tutorial](https://www.atlassian.com/git/tutorials/merging-vs-rebasing)
* [GitKraken](https://www.gitkraken.com/learn/git/problems/git-rebase-vs-merge)
* [Hackernoon](https://hackernoon.com/git-merge-vs-rebase-whats-the-diff-76413c117333)
* [Stack Overflow](https://stackoverflow.com/questions/59622140/git-merge-vs-git-rebase-for-merge-conflict-scenarios)
<br>

#### Rebase
Rebasing is an important tool to be familiar with and introduce into your workflow. The video and instructions below help to provide information on how to begin using it in your collaborations with the team.

[Youtube - A Better Git Workflow with Rebase](https://www.youtube.com/watch?v=f1wnYdLEpgI)

A rebase might be preferred, especially if all your work is contained on your branch, within your task's folder, and lots of activity is happening on `main`. You'd like to plop all your commits onto the most recent `main` branch, and have it appear as if all your work took place *after* those PRs were merged in.

1. At this point, you've either stashed or added commits on `my-new-branch`.
1. Check out the `main` branch: `git checkout main`
1. Pull from origin: `git pull origin main`
1. Check out your current branch: `git checkout my-new-branch`
1. Rebase and rewrite history so that your commits come *after* everything on main: `git rebase main`
1. At this point, the rebase may be successful, or you will have to address any conflicts! If you want to abort, use `git rebase --abort`. Changes in scripts will be easy to resolve, but notebook conflicts are difficult. If conflicts are easily resolved, open the file, make the changes, then `git add` the file(s), and `git rebase --continue`.
1. Make any commits you want (from step 1) with `git add`, `git commit -m "commit message"`
1. Force-push those changes to complete the rebase and rewrite the commit history: `git push origin my-new-branch -f`

#### Merge

1. At this point, you've either stashed or added commits on `my-new-branch`.
1. Pull from origin: `git checkout main` and `git pull origin main`
1. Go back to your branch: `git checkout my-new-branch`
1. Complete the merge of `my-new-branch` with `main` and create a new commit: `git merge my-new-branch main`
1. A merge commit window opens up. Type `:wq` to exit and complete the merge.
1. Type `git log` to see that the merge commit was created.

(resolve-merge-conflicts)=
### Options for Resolving Merge Conflicts
If you discover merge conflicts and they are within a single notebook that only you are working on it can be relatively easy to resolve them using the Git command line instructions:
* From the command line, run `git merge main`. This should show you the conflict.
* From here, there are two options depending on what version of the notebook you'd like to keep.
  * To keep the version on your branch, run:<br/>
`git checkout --ours path/to/notebook.ipynb`
  * To keep the remote version, run:<br/>
`git checkout --theirs path/to/notebook.ipynb`
* From here, just add the file and commit with a message as you normally would and the conflict should be fixed in your Pull Request.

### Helpful Hints

These are helpful Git commands an analyst might need, listed in no particular order.

* During collaboration, if another analyst already created a remote branch, and you want to work off of the same branch: `git fetch origin`, `git checkout -b our-project-branch origin/our-project-branch`
* To discard the changes you made to a file, `git checkout my-notebook.ipynb`, and you can revert back to the version that was last committed.
* Temporarily stash changes, move to a different branch, and come back and retain those changes: `git stash`, `git checkout some-other-branch`, do stuff on the other branch, `git checkout original-branch`, `git stash pop`
* Rename files and retain the version history associated (`mv` is move, and renaming is moving the file path): `git mv old-notebook.ipynb new-notebook.ipynb`
* Once you've merged your branch into `main`, you can delete your branch locally: `git branch -d my-new-branch`
* Set your local `main` branch to be the same as the remote branch: `git fetch origin
git reset --hard origin/main`
* To delete a file that's been added in a previous commit: `git rm notebooks/my-notebook.ipynb`
* Cherry pick a commit and apply it to your branch: `git cherry-pick COMMIT_HASH`. Read more from [Stack Overflow](https://stackoverflow.com/questions/9339429/what-does-cherry-picking-a-commit-with-git-mean) and [Atlassian](https://www.atlassian.com/git/tutorials/cherry-pick).

(external-git-resources)=
### External Resources
* [Git Terminal Cheat Sheet](https://gist.github.com/cferdinandi/ef665330286fd5d7127d)
* [Git Decision Tree - 'So you have a mess on your hands'](http://justinhileman.info/article/git-pretty/full/)

(pushing-drag-drop)=
## Committing in the Github User Interface

If you would like to commit directly from the Github User Interface:

1. Navigate the Github repository and folder that you would like to add your work, and locate the file on your computer that you would like to commit

    (Note: if you would like to commit your file to a directory that does not yet exist, <a href="https://cal-itp.slack.com/team/U027GAVHFST" target="_blank">message Charlie on Cal-ITP Slack</a> to add it for you)



    ![Collection Matrix](assets/step-1-gh-drag-drop.png)


1. 'Click and Drag' your file from your computer into the Github screen



    ![Collection Matrix](assets/step-2-gh-drag-drop.png)
