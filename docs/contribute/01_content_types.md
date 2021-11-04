# Types of Content (WIP)
## What kinds of content can I put in the documentation?

### Images
Images are currently being stored in the assetts folder within each docs folder. Preference is for .Png file extension and no larger than 500kb. Images can be loaded into jupyterbook by using the following syntax:
```
![Collection Matrix](XXX.png)
```
### Running Code
To include code that will run within the jupyterbook documentation, use the following sytax:

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

#### for the actual code block:
**For Python**
#### Syntax:
```
    ```{code-cell}
    Sample Code
    ```
```

**For SQL**
#### Cell Magics
To run sql within the jupyterbook we are using an Ipython wrapper called cell magics.

#### Syntax:
```
    ```{code-cell}
    %%sql
    Sample SQL
    ```
```
