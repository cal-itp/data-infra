# Welcome

This website provides technical documentation for the Juniper codebase.

Documentation for the `main` branch is available online at: <https://docs.calitp.org/data-infra>

## Editing documentation

The docs content all lives under `docs/`, with some top-level configuration for how the docs website gets built under `mkdocs.yml`. To add new sections/articles, simply create new directories/files under `docs/` in Markdown format.

To preview the rendered docs website live while you work, run `script/docs-server` from your terminal (requires Python 3.5+).

Changes to docs will be published to the online docs website automatically after they are merged into the `main` branch.

## Documentation features

- [Material for MkDocs: Reference](https://squidfunk.github.io/mkdocs-material/reference/admonitions/)

    See `mkdocs.yml` for enabled plugins/features

- [Mermaid](https://mermaid-js.github.io/mermaid/)

    Use code fences with `mermaid` type to render Mermaid diagrams within docs. For example, this markdown:

    ~~~markdown
    ```mermaid
    graph LR
        Start --> Stop
    ```
    ~~~

    Yields this diagram:

    ~~~mermaid
    graph LR
        Start --> Stop
    ~~~
