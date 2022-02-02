(content-types)=
# Types of Content
## What kinds of content can I put in the documentation?
On this page you can find some of the common content types used in the Cal-ITP Data Services Documentation.

If you haven't yet, navigate to the [Best Practices](bp-reference) section of the documentation for more background on documentation structure and how to contribute.

### Images
Images are currently being stored in the assets folder within each docs folder. Preference is for `.png` file extension and no larger than 500kb. Images can be loaded into Jupyter Book by using the following syntax:

```
![Collection Matrix](XXX.png)
```
### Running Code
To include code that will run within a `.md` file, place the following sytax at the top of a `.md` document:

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

#### Then, to create the actual code block:
##### Python
**Syntax**:
```
    ```{code-cell}
    Sample Code
    ```
```

##### SQL
**Syntax:** Cell Magics:
To run sql within the Jupyter Book we are using an iPython wrapper called Cell Magics.
```python
import calitp.magics
```
```
    ```{code-cell}
    %%sql
    Sample SQL
    ```
```
### Non-Executing Code
Non-executing code is formatted similarly to the executing code above, but replaces
`{code-cell}` with the name of the language you would like to represent, as seen below.
```
    ```python
    Sample Code
    ```
```
```
    ```sql
    Sample Code
    ```
```

### Internal References and Cross-References
Referencing within the documentation can be accomplished quickly with `labels` and `markdown link syntax`.

Labels can be added before major elements of a page,
such as titles or figures. To add a label, use the following pattern **before** the element you wish to label:

```md
(my-label)=
# The thing to label
```

You can then insert cross-references to labels in your content with this syntax:

- `[](label-text)`
