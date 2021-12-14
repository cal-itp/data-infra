(saving-code)=
# Saving Code (WIP)

Most Cal-ITP analysts should opt for working directly from JupyterHub. Leveraging this cloud-based, standardized environment should alleviate many of the pain points associated with creating reproducible, collaborative work.

Doing work locally and pushing directly from the command line is a similar workflow, but replace the JupyterHub terminal with your local terminal.

## Table of Contents
1. [Pushing from JupyterHub](#pushing-from-jupyterhub)
* [Onboarding Setup](#onboarding-setup)
* What's a typical [project workflow](#project-workflow)?
* Someone is collaborating on my branch, how do we [stay in sync](#pulling-and-pushing-changes)?
* The `main` branch is ahead, and I want to [sync my branch with `main`](rebase-and-merge)
* [Helpful Hints](#helpful-hints)
2. [Pushing in the Github User Interface](#pushing-drag-drop)

## Pushing from JupyterHub

### Onboarding Setup

We'll work through getting set up with GitHub on JupyterHub and cloning one GitHub repo. Repeat steps 6-10 for other repos.
(github-setup)=
1. Create a GitHub username, get added to the various Cal-ITP teams. You'll be committing directly into the Cal-ITP repos!
1. Set up SSH by following these [directions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).
1. After you've added your SSH key to your GitHub account, you can test your connection: `ssh -T git@github.com`
1. Navigate to the GitHub repository to clone. We'll work our way through the `data-analyses` [repo here](https://github.com/cal-itp/data-analyses). Click on the green `Code` button, select "SSH" and copy the URL.
1. Open a terminal in JupyterHub. All our commands will be typed in this terminal.
1. Clone the Git repo: `git clone git@github.com:cal-itp/data-analyses.git`
1. Double check  with `ls` to list and see that the remote repo was successfully cloned into your "local" (cloud-based) filesystem.
1. Change into the `data-analyses` directory: `cd data-analyses`
1. Point to the remote repo: `git remote add origin git@github.com:cal-itp/data-analyses.git`. Double check it's set with: `git remote -v`
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
### Syncing My Branch With Main
If you find that the `main` branch is ahead, and you want to sync your branch with `main` you'll need to use one of the below commands:

* [Rebase](#rebase)
* [Merge](#merge)

Read more about the differences between `merge` and `rebase`:
* [Atlassian tutorial](https://www.atlassian.com/git/tutorials/merging-vs-rebasing)
* [GitKraken](https://www.gitkraken.com/learn/git/problems/git-rebase-vs-merge)
* [Hackernoon](https://hackernoon.com/git-merge-vs-rebase-whats-the-diff-76413c117333)
* [StackOverflow](https://stackoverflow.com/questions/59622140/git-merge-vs-git-rebase-for-merge-conflict-scenarios).
<br>

#### Rebase

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
SOMEONE WHO PREFERS MERGE PROCESS TO FILL THIS IN...is there a commit after?

### Helpful Hints

* To discard the changes you made to a file, `git checkout my-notebook.ipynb`, and you can revert back to the version that was last committed.
* Temporarily stash changes, move to a different branch, and come back and retain those changes: `git stash`, `git checkout some-other-branch`, do stuff on the other branch, `git checkout original-branch`, `git stash pop`
* Rename files and retain the version history associated: `git mv old-notebook.ipynb new-notebook.ipynb`
* Once you've merged your branch into `main`, you can delete your branch locally: `git branch -d my-new-branch`

(pushing-drag-drop)=
## Pushing in the Github User Interface

If you would like to push directly from the Github User Interface:

  1. Navigate the Github repository and folder that you would like to add your work, and locate the file on your computer that you would like to add

(Note: if you would like to add your file to a folder that does not yet exist, <a href="https://cal-itp.slack.com/team/U027GAVHFST" target="_blank">message Charlie on Cal-ITP Slack</a> to add it for you)

![Collection Matrix](assets/step-1-gh-drag-drop.png)

  2. 'Click and Drag' your file from your computer into the Github screen

![Collection Matrix](assets/step-2-gh-drag-drop.png)
