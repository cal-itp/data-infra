(bp-reference)=
# Best Practices
This page aggregates best practices and helpful information for use when contributing to our documentation.

Our Cal-ITP Data Services Documentation uses the Jupyter Book ecosystem to generate our docs. You can find their full documentation at this link: [Jupyter Book Documentation](https://jupyterbook.org/intro.html).
1. [Universal Rules](universal-rules)
2. [Guidelines by Contribution Type](guidelines-by-contribution)
    * [Small Changes)](small-changes)
    * [New Sections (Headers)](new-sections)
    * [New Pages and Chapters](new-pages)

(universal-rules)=
## Universal Rules
There are a few things that are true for all files and content types. Here is a short list:
* **Files must have a title.** Generally this means that they must begin with a line that starts with a single #
* **Use only one top-level header.** Because each page must have a clear title, it must also only have one top-level header. You cannot have multiple headers with single # tag in them.
* **Headers should increase linearly.** If you’re inside of a section with one #, then the next nested section should start with ##. Avoid jumping straight from # to ###.

(guidelines-by-contribution)=
## Guidelines by Contribution Type
When you are ready to make changes, visit the [Submitting Changes](submitting-changes) section for how to contribute.

If you haven't yet, navigate to the [Common Content](content-types) section of the documentation for further information on adding specific types of content.
(small-changes)=
### Small Changes
For small changes such as typos, clarification, or changes within existing content you can reference the [Common Content](content-types) section as needed.
(new-sections)=
### New Sections (Headers)
If you feel a new section is warranted, make sure you follow Jupyter Book's guidelines on headers:

> **Headers should increase linearly.** If you’re inside of a section with one #, then the next nested section should start with ##. Avoid jumping straight from # to ###.

(new-pages)=
### New Pages and Chapters
Add new pages and chapters only as truly needed. If you're unsure of whether a new page or chapter is necessary, reach out to `@Charlie Costanzo` on `Cal-ITP Slack`.

If you are adding new pages or chapters, you will need to also update the `_toc.yml` file. You can find more information at Jupyter Book's resource [Structure and organize content](https://jupyterbook.org/basics/organize.html).

You will also need to follow Jupyter Book's guidelines for when adding files:
>**Files must have a title.** Generally this means that they must begin with a line that starts with a single #

>**Use only one top-level header.** Because each page must have a clear title, it must also only have one top-level header. You cannot have multiple headers with single # tag in them.
