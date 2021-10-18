# Juniper Documentation

> \"Welcome.\" -- Natalya Diaz


## Welcome

This website provides technical documentation for the Juniper codebase. Documentation for the `main` branch is available online at [Calitp](https://docs.calitp.org/data-infra)

### Editing Documentation

The docs content all lives under `docs/`, with some top-level configuration for how the docs website gets built under `mkdocs.yml`. To add new sections/articles, simply create new directories/files under `docs/` in Markdown format.

To preview the rendered docs website while you work, run `script/docs-server` from your terminal (requries Python 3.5+)

Changes to docs will be published to the online docs website automatically after they are merged into the `main` branch.

### Documentation features
[Material for mkDocs: Reference](https://squidfunk.github.io/mkdocs-material/reference/admonitions/)
- see `mkdocs.yml` for enabled plugins/features

[Mermaid](https://mermaid-js.github.io/mermaid/#/)
- use code fences with mermade type to render Mermaid diagrams within docs. for example this markdown:
