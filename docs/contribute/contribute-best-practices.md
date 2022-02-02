(bp-reference)=
# Best Practices
This page aggregates best practices and helpful information for use when contributing to our documentation.

Our Cal-ITP Data Services Documentation uses the Jupyter Book ecosystem to generate our docs. You can find their full documentation at this link: [Jupyter Book Documentation](https://jupyterbook.org/intro.html).

## Cal-ITP Typical Contributions
Although Jupyter Book allows flexibility, the pages in our docs are typically generated in the formats below. You can find more information in our [Content Types](content-types) section.

### File Types
* Markdown (`.md`)
* Jupyter Notebooks (`.ipynb`)
* Images less than 500kb (`.png` preferred)

### Content Types
* [MyST](https://jupyterbook.org/reference/cheatsheet.html) (a flavor of Markdown used by Jupyter Book)
* [Jupyter Notebook Markdown](https://jupyterbook.org/file-types/notebooks.html)

### Universal Rules
There are a few things that are true for all files and content types. Here is a short list:
* **Files must have a title.** Generally this means that they must begin with a line that starts with a single #
* **Use only one top-level header.** Because each page must have a clear title, it must also only have one top-level header. You cannot have multiple headers with single # tag in them.
* **Headers should increase linearly.** If you’re inside of a section with one #, then the next nested section should start with ##. Avoid jumping straight from # to ###.


## Guidelines by Contribution Type
### Small Changes
Such as typos, clarification, changes within existing content, or other small additions.

Reference the above Markdown resources as needed.

### New Sections (Headers)
If you feel a new section is warranted, make sure you follow Jupyter Book's guidelines on headers:

> **Headers should increase linearly.** If you’re inside of a section with one #, then the next nested section should start with ##. Avoid jumping straight from # to ###.

### New Pages and Chapters
Add new pages and chapters only as truly needed. If you're unsure of whether a new page or chapter is necessary, reach out to `@Charlie Costanzo` on `Cal-ITP Slack`.

If you are adding new pages or chapters, you will need to also update the `_toc.yml` file. You can find more information at [Structure and organize content](https://jupyterbook.org/basics/organize.html).

You will also need to follow Jupyter Book's guidelines for when adding files:
>**Files must have a title.** Generally this means that they must begin with a line that starts with a single #

>**Use only one top-level header.** Because each page must have a clear title, it must also only have one top-level header. You cannot have multiple headers with single # tag in them.
