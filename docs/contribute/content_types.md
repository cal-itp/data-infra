(content-types)=

# Common Content

On this page you can find some of the common content types used in the Cal-ITP Data Services Documentation. Although the ecosystem we use, Jupyter Book, allows flexibility, the pages in our docs are typically generated in the formats below.

If you haven't yet, navigate to the [Best Practices](bp-reference) section of the documentation for more context on our docs management, and the [Submitting Changes](submitting-changes) section for how to contribute.

## File Types

- Markdown (`.md`)
- Jupyter Notebooks (`.ipynb`)
- Images less than 500kb (`.png` preferred)

## Content Syntax - Resources

- [MyST](https://jupyterbook.org/reference/cheatsheet.html) - a flavor of Markdown used by Jupyter Book for `md` documents
- [Jupyter Notebook Markdown](https://jupyterbook.org/file-types/notebooks.html) - Markdown for use in `.ipynb` documents

## Common Content - Examples

Below we've provided some examples of commons types of content for quick use. To find more detailed information and extended examples use the links above under `Allowable Syntax - Resources`

1. [Images](adding-images)
2. [Executing Code](executing-code)
   - [Python](executing-code-python)
   - [SQL](executing-code-sql)
3. [Non-executing Code](non-executing-code)
4. [Internal References and Cross References](internal-refs)
5. Need a node graph to illustrate a complex flow or process? Try mermaid ([documentation here](https://mermaid.js.org/intro/)).
    (executing-code)=

### Executing Code

Place the following syntax at the top of a `.md` document to include code that will execute.

```
---
jupytext:
  cell_metadata_filter: -all
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.10.3
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---
```

To create the actual code block:
(executing-code-python)=
**Python**

````
    ```{code-cell}
    Sample Code
    ```
````

(executing-code-sql)=
**SQL**

To run SQL within the Jupyter Book we are using an iPython wrapper called `cell Magics` with `%%sql`.

```python
import calitp_data_analysis.magics
```

````
    ```{code-cell}
    %%sql
    Sample SQL Here
    ```
````

You can visit [this page](https://jupyterbook.org/content/code-outputs.html) for more information on how to format code outputs.

(non-executing-code)=

### Non-Executing Code

Non-executing code is formatted similarly to the executing code above, but replaces `{code-cell}` with the name of the language you would like to represent, as seen below, to provide syntax highlighting.

````
    ```python
    Sample Code
    ```
````

````
    ```sql
    Sample Code
    ```
````

(adding-images)=

### Images

Images are currently being stored in an `assets` folder within each `docs` folder. Preference is for `.png` file extension and no larger than `500kb`. Images can be loaded into Jupyter Book by using the following syntax:

```
![Collection Matrix](assets/your-file-name.png)
```

(internal-refs)=

### Internal References and Cross-References

Referencing within the documentation can be accomplished quickly with `labels` and `markdown link syntax`.

**Note**: be sure to make reference names unique. If a reference has the same name as a file name, for example, the build process will fail.

Labels can be added before major elements of a page, such as titles or figures. To add a label, use the following pattern **before** the element you wish to label:

```md
(my-label)=
# The thing to label
```

You can then insert cross-references to labels in your content with this syntax:

`[Link Text](my-label)`
