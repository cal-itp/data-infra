"""
Provide more visualizations than what dbt provides.
"""
import json
import webbrowser
from pathlib import Path
from typing import Any, List, Optional, Type, Union

import gcsfs  # type: ignore
import networkx as nx  # type: ignore
import typer
from catalog import Catalog
from dbt_artifacts import BaseNode, Manifest, RunResult, RunResults, Seed, Source, Test
from networkx_viewer import Viewer  # type: ignore

app = typer.Typer(pretty_exceptions_enable=False)


def read_artifact(path: Path, artifact_type: Type, verbose: bool = False) -> Any:
    if verbose:
        typer.secho(f"reading {artifact_type} from {path}", fg=typer.colors.MAGENTA)
    opener = gcsfs.GCSFileSystem().open if str(path).startswith("gs://") else open
    with opener(path) as f:
        return artifact_type(**json.load(f))


def build_graph(
    artifact: Union[Manifest, RunResults],
    analyses: bool = False,
    models: bool = True,
    seeds: bool = False,
    snapshots: bool = False,
    tests: bool = False,
    sources: bool = False,
    include: Optional[List[str]] = None,
    exclude: Optional[List[str]] = None,
) -> nx.DiGraph:
    G = nx.DiGraph()
    nodes = (
        artifact.nodes.values() if isinstance(artifact, Manifest) else artifact.results
    )

    # Add all nodes first in case we're visualizing RunResults
    # We want to be able to add immediate parents of RunResult
    # nodes as dashed
    node_or_result: Union[BaseNode, RunResult]
    for node_or_result in nodes:
        node: BaseNode = (
            node_or_result.node
            if isinstance(node_or_result, RunResult)
            else node_or_result
        )
        if include and node.name not in include:
            continue
        if isinstance(node, Seed) and not seeds:
            continue
        if isinstance(node, Test) and not tests:
            continue
        if isinstance(node, Source) and not sources:
            continue

        G.add_node(node_or_result.gvrepr, **node.gvattrs, style="filled")

    for node_or_result in nodes:
        node: BaseNode = node_or_result.node if isinstance(node_or_result, RunResult) else node_or_result  # type: ignore[no-redef]
        if include and node.name not in include:
            continue
        if isinstance(node, Seed) and not seeds:
            continue
        if isinstance(node, Test) and not tests:
            continue
        if isinstance(node, Source) and not sources:
            continue
        if node.depends_on and node.depends_on.nodes:
            for dep in node.depends_on.resolved_nodes:
                if isinstance(dep, Seed) and not seeds:
                    continue
                if isinstance(dep, Test) and not tests:
                    continue
                if isinstance(dep, Source) and not sources:
                    continue
                if dep.gvrepr not in G and (not exclude or dep.name not in exclude):
                    G.add_node(dep.gvrepr, **dep.gvattrs, style="dashed")
                if not exclude or node.name not in exclude:
                    G.add_edge(node.gvrepr, dep.gvrepr)

    return G


@app.command()
def viz(
    artifact: str,
    manifest_path: Path = Path("./target/manifest.json"),
    run_results_path: Path = Path("./target/run_results.json"),
    catalog_path: Path = Path("./target/catalog.json"),
    graph_path: Path = Path("./target/graph.gpickle"),
    analyses: bool = False,
    models: bool = True,
    seeds: bool = False,
    snapshots: bool = False,
    tests: bool = False,
    sources: bool = False,
    include: Optional[List[str]] = None,
    exclude: Optional[List[str]] = None,
    verbose: bool = False,
    output: Path = Path("./target/dag.pdf"),
    display: bool = False,
):
    manifest: Manifest = read_artifact(manifest_path, Manifest, verbose=verbose)
    catalog: Catalog = read_artifact(catalog_path, Catalog, verbose=verbose)
    run_results: RunResults = read_artifact(
        run_results_path, RunResults, verbose=verbose
    )
    manifest.set_catalog(c=catalog)
    run_results.set_manifest(manifest)

    actual_artifact: Union[Manifest, RunResults]
    if artifact == "man":
        actual_artifact = manifest
    elif artifact == "run":
        actual_artifact = run_results
    else:
        raise ValueError(f"unknown artifact {artifact} provided")

    G = build_graph(
        actual_artifact,
        analyses,
        models,
        seeds,
        snapshots,
        tests,
        sources,
        include,
        exclude,
    )

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
