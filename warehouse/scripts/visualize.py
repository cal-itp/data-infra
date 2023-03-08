"""
Provide more visualizations than what dbt provides.
"""
import json
import webbrowser
from pathlib import Path
from typing import Any, List, Type

import gcsfs  # type: ignore
import networkx as nx  # type: ignore
import typer
from catalog import Catalog
from dbt_artifacts import Manifest, RunResults, Seed, Source, Test
from networkx_viewer import Viewer  # type: ignore

app = typer.Typer(pretty_exceptions_enable=False)


def read_artifact(path: Path, artifact_type: Type, verbose: bool = False) -> Any:
    if verbose:
        typer.secho(f"reading {artifact_type} from {path}", fg=typer.colors.MAGENTA)
    opener = gcsfs.GCSFileSystem().open if str(path).startswith("gs://") else open
    with opener(path) as f:
        return artifact_type(**json.load(f))


@app.command()
def manviz(
    manifest_path: Path = Path("./target/manifest.json"),
    run_results_path: Path = Path("./target/run_results.json"),
    catalog_path: Path = Path("./target/catalog.json"),
    graph_path: Path = Path("./target/graph.gpickle"),
    output: Path = Path("./target/dag.png"),
    verbose: bool = False,
    analyses: bool = False,
    models: bool = True,
    seeds: bool = False,
    snapshots: bool = False,
    tests: bool = False,
    sources: bool = False,
    include: List[str] = [],
    exclude: List[str] = [],
    display: bool = False,
):
    manifest: Manifest = read_artifact(manifest_path, Manifest, verbose=verbose)
    catalog: Catalog = read_artifact(catalog_path, Catalog, verbose=verbose)
    manifest.set_catalog(c=catalog)

    G = nx.DiGraph()
    for node in manifest.nodes.values():
        if include and node.name not in include:
            continue
        if isinstance(node, Seed) and not seeds:
            continue
        if isinstance(node, Test) and not tests:
            continue
        if isinstance(node, Source) and not sources:
            continue

        G.add_node(node.gvrepr, **node.gvattrs, style="filled")
        if node.depends_on and node.depends_on.nodes:
            for dep in node.depends_on.resolved_nodes:
                if isinstance(dep, Seed) and not seeds:
                    continue
                if isinstance(dep, Test) and not tests:
                    continue
                if isinstance(dep, Source) and not sources:
                    continue

                if dep.gvrepr not in G:
                    G.add_node(dep.gvrepr, **dep.gvattrs, style="dashed")
                G.add_edge(node.gvrepr, dep.gvrepr)

    A = nx.nx_agraph.to_agraph(G)
    A.layout(prog="dot")
    if verbose:
        print(f"Writing DAG to {output}")
    A.draw(output)
    if display:
        url = f"file://{output.resolve()}"
        webbrowser.open(url, new=2)  # open in new tab


@app.command()
def runviz(
    manifest_path: Path = Path("./target/manifest.json"),
    run_results_path: Path = Path("./target/run_results.json"),
    graph_path: Path = Path("./target/graph.gpickle"),
    output: Path = Path("./target/dag.png"),
    verbose: bool = False,
    sources: bool = True,
    seeds: bool = True,
    include: List[str] = [],
    exclude: List[str] = [],
    display: bool = False,
):
    manifest: Manifest = read_artifact(manifest_path, Manifest, verbose=verbose)
    run_results: RunResults = read_artifact(
        run_results_path, RunResults, verbose=verbose
    )
    run_results.set_manifest(manifest)

    G = nx.DiGraph()
    # We add all results as nodes
    for result in run_results.results:
        if result.node.name not in exclude:
            G.add_node(result.node.gvrepr, **{**result.node.gvattrs, **result.gvattrs})
    # Then, add edges plus other nodes if not already added as a result node
    for result in run_results.results:
        node = result.node
        if node.depends_on and node.depends_on.nodes:
            for dep in node.depends_on.resolved_nodes:
                if isinstance(dep, Source) and not sources:
                    continue
                if isinstance(dep, Seed) and not seeds:
                    continue
                if dep.gvrepr not in G and dep.name not in exclude:
                    G.add_node(dep.gvrepr, **dep.gvattrs, style="dashed")
                if node.name not in exclude:
                    G.add_edge(node.gvrepr, dep.gvrepr)

    A = nx.nx_agraph.to_agraph(G)
    A.layout(prog="dot")
    if verbose:
        print(f"Writing DAG to {output}")
    A.draw(output)
    if display:
        url = f"file://{output.resolve()}"
        webbrowser.open(url, new=2)  # open in new tab


@app.command()
def guiviz(
    graph_path: Path = Path("./target/graph.gpickle"),
):
    G = nx.read_gpickle(graph_path)
    app = Viewer(G)
    app.mainloop()


if __name__ == "__main__":
    app()
