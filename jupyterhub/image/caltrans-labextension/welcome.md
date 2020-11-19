# Welcome to the Caltrans Data Platform

This is a cloud-based deployment of JupyterLab,
an interactive computing environment.
With this platform you can conduct data analysis and make visualizations from anywhere.

There is a menu bar at the top, and a file browser on the left.
The central area (where this page is) is your main work area.
Here you can arrange Jupyter notebooks, code consoles, text files, and terminals.
Each of these activities can be launched using the Launcher,
or using the `File > New` menu.

You can log out of the platform by going to `File > Logout`.
You can stop or restart this application by going to `File > Hub Control Panel`.

A number of the features of this application can be configured using the `Settings` menu,
including font sizes, themes, and autosave behavior.

### Running notebooks

Jupyter notebooks are attached to live instances of a code execution engine (called kernels),
which you can use to execute code, and then inspect the results of that execution.

You can run a cell by pressing <kbd>Shift</kbd>+<kbd>Enter</kbd>.
Often you will want to restart the kernel to get a fresh slate.
You can do that, as well as other kernel-related operations using the Kernel menu.

### Running terminals

You may want to perform operations using a Unix terminal,
such as batch moving of files or git commands.
You can create a `bash` terminal from the Launcher,
or by going to `File > New > Terminal`.

### Running consoles

Consoles are a more ephemeral version of notebooks.
They are connected to kernels, and you can send code to them and receive the outputs
in the same way that you do with a notebook.
However, they are not saved to disk as a file.
You can create a new console from the Launcher,
or by going to `File > New > Console`.
You can also create a console attached to a notebook by right-clicking on
a notebook, and selecting "New Console For Notebook".

### Editing markdown

Markdown is a lightweight markup language for writing formatted prose,
and is intended to be an easier-to-author version of HTML.
Notebooks use markdown for writing prose, and a lot of code documentation
(including this very document) is written using markdown.

For a guide to markdown, go to `Help > Markdown Reference`.
When editing a markdown file, you can right-click on it and select "Show Markdown Preview"
to see a rendered version of the file.

### Uploading and downloading files

This platform exists in the cloud, and as such does not
have access to files on your personal computer.
In order to get access to the files important for your analysis, you have a few options:

* If they are code in a git repository, you can clone the repository with a terminal.
* If they are on your local computer, you can upload them using the upload button (the up arrow) in the file browser.
* If they are hosted in cloud storage, you can download them using the cloud storage command-line tools.

Files that are shown in the file browser can be downloaded by right-clicking on them
and selecting "Download".


### Cloning a repository

Your code should be stored in version control and hosted on some code repository (often GitHub).
You can clone this code to the platform by getting the link to the repository,
opening a terminal, and entering
```bash
git clone <your-repository-url>
```

Alternatively, you can clone a repository using the "Clone" button at the top of the file browser,
and pasting the URL to the repository.

The first time you log in to this platform, you will need to configure git to let it know who you are.
This will allow it to attach your information to code commits you make.
You can configure git by running the following in a terminal:
```bash
git config --global user.name "FIRST_NAME LAST_NAME"
git config --global user.email "MY_NAME@example.com"
```

More information on how to use git can be found in this
[Software Carpentry tutorial](https://swcarpentry.github.io/git-novice/).

You'll want to setup Git using [ssh](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/connecting-to-github-with-ssh) rather than https to avoid having to retype your password constantly.

### Setting up a new project

It is often useful to start a new data analysis project with a reasonable directory structure already set up.
Following the instructions for these project templates can be a good way to get your project going:

**Python**: https://github.com/CityOfLosAngeles/cookiecutter-data-science

**R**: https://github.com/CityOfLosAngeles/cookiecutter-r-data-analysis

To use the templates and start a new project, open a new terminal and type: 

* Python: `cookiecutter gh:CityOfLosAngeles/cookiecutter-data-science` 
* R: `cookiecutter gh:CityOfLosAngeles/cookiecutter-r-data-analysis` 

and complete the config info. 

### Where to go for help

If you run into troubles, please reach out for help!
For recommendations about how to structure projects for reproducibility and robustness,
see the [City of Los Angeles Best Practices](https://CityOfLosAngeles.github.io/best-practices).
To report bugs or feature requests,
[file an issue on GitHub](https://github.com/cal-itp/data-infra).
