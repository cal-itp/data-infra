"""
Provide more visualizations than what dbt provides.
"""
import json
import webbrowser
from pathlib import Path
from typing import Any, List, Optional, Tuple, Type, Union

import gcsfs  # type: ignore
import networkx as nx  # type: ignore
import typer
from dbt_artifacts.catalog import Model as Catalog
from dbt_artifacts import BaseNode, Manifest, RunResult, RunResults, Seed, Source, Test

app = typer.Typer(pretty_exceptions_enable=False)


def read_artifact(path: Path, artifact_type: Type, verbose: bool = False) -> Any:
    if verbose:
        typer.secho(f"reading {artifact_type} from {path}", fg=typer.colors.MAGENTA)
    opener = gcsfs.GCSFileSystem().open if str(path).startswith("gs://") else open
    with opener(path) as f:
        return artifact_type(**json.load(f))


def read_artifacts_folder(
    artifacts_path: Path, verbose: bool = False
) -> Tuple[Manifest, Catalog, RunResults]:
    manifest: Manifest = read_artifact(
        artifacts_path / Path("manifest.json"), Manifest, verbose=verbose
    )
    catalog: Catalog = read_artifact(
        artifacts_path / Path("catalog.json"), Catalog, verbose=verbose
    )
    run_results: RunResults = read_artifact(
        artifacts_path / Path("run_results.json"), RunResults, verbose=verbose
    )
    manifest.set_catalog(c=catalog)
    run_results.set_manifest(manifest)
    return manifest, catalog, run_results


def should_display(
    node: BaseNode,
    analyses: bool = False,
    models: bool = True,
    seeds: bool = False,
    snapshots: bool = False,
    tests: bool = False,
    sources: bool = False,
    include: Optional[List[str]] = None,
    exclude: Optional[List[str]] = None,
) -> bool:
    if isinstance(node, Seed) and not seeds:
        return False
    if isinstance(node, Test) and not tests:
        return False
    if isinstance(node, Source) and not sources:
        return False
    if include:
        return any(
            identifier in include
            for identifier in (node.name, node.unique_id, node.strfqn)
        )
    return True


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
    verbose: bool = False,
) -> nx.DiGraph:
    G = nx.DiGraph()
    nodes = (
        artifact.nodes.values() if isinstance(artifact, Manifest) else artifact.results
    )

    if include and verbose:
        typer.secho(f"Only including: {include}")

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

        if not should_display(
            node,
            analyses,
            models,
            seeds,
            snapshots,
            tests,
            sources,
            include,
            exclude,
        ):
            if verbose:
                typer.secho(f"skipping {node.name}")
            continue

        G.add_node(node_or_result.gvrepr, **node_or_result.gvattrs, style="filled")

    for node_or_result in nodes:
        node: BaseNode = node_or_result.node if isinstance(node_or_result, RunResult) else node_or_result  # type: ignore[no-redef]
        if not should_display(
            node,
            analyses,
            models,
            seeds,
            snapshots,
            tests,
            sources,
            include,
            exclude,
        ):
            if verbose:
                typer.secho(f"skipping {node.name}")
            continue
        if node.depends_on and node.depends_on.nodes:
            for dep in node.depends_on.resolved_nodes:
                if not should_display(
                    dep,
                    analyses,
                    models,
                    seeds,
                    snapshots,
                    tests,
                    sources,
                    include,
                    exclude,
                ):
                    if verbose:
                        typer.secho(f"skipping {dep.name}")
                    continue
                if dep.gvrepr not in G and (not exclude or dep.name not in exclude):
                    G.add_node(dep.gvrepr, **dep.gvattrs, style="dashed")
                if not exclude or node.name not in exclude:
                    G.add_edge(node.gvrepr, dep.gvrepr)

    return G


@app.command()
def viz(
    artifact: str,
    artifacts_path: Path = Path("./target"),
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
    output: Optional[Path] = None,
    display: bool = False,
    ratio: float = 0.3,
):
    manifest, catalog, run_results = read_artifacts_folder(
        artifacts_path, verbose=verbose
    )
    actual_artifact: Union[Manifest, RunResults]
    if artifact == "man":
        actual_artifact = manifest
        if not output:
            output = Path("./target/manifest.pdf")
    elif artifact == "run":
        actual_artifact = run_results
        if not output:
            output = Path("./target/run_results.pdf")
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
        verbose=verbose,
    )

    A = nx.nx_agraph.to_agraph(G)
    if verbose:
        print(f"Writing DAG to {output}")
    A.draw(output, args=f"-Gratio={ratio}", prog="dot")
    if display:
        url = f"file://{output.resolve()}"
        webbrowser.open(url, new=2)  # open in new tab


if __name__ == "__main__":
    app()
