"""
Provide more visualizations than what dbt provides.
"""
import json
import os
import webbrowser
from enum import Enum
from pathlib import Path
from typing import Any, List, Optional, Tuple, Type, Union

import gcsfs  # type: ignore
import networkx as nx  # type: ignore
import typer
from dbt.cli.main import dbtRunner
from dbt_artifacts import (
    Catalog,
    DbtNode,
    GenericTestNode,
    Manifest,
    RunResultOutput,
    RunResults,
    SeedNode,
    SourceDefinition,
)
from jinja2 import Environment, FileSystemLoader, select_autoescape

app = typer.Typer()


class ArtifactType(str, Enum):
    manifest = "manifest"
    run_results = "run_results"


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
    node: DbtNode,
    analyses: bool = False,
    models: bool = True,
    seeds: bool = False,
    snapshots: bool = False,
    tests: bool = False,
    sources: bool = False,
    include: Optional[List[str]] = None,
    exclude: Optional[List[str]] = None,
) -> bool:
    if isinstance(node, SeedNode) and not seeds:
        return False
    if isinstance(node, GenericTestNode) and not tests:
        return False
    if isinstance(node, SourceDefinition) and not sources:
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
    node_or_result: Union[DbtNode, RunResultOutput]
    for node_or_result in nodes:
        node: DbtNode = (
            node_or_result.node
            if isinstance(node_or_result, RunResultOutput)
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
        node = (
            node_or_result.node
            if isinstance(node_or_result, RunResultOutput)
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
        if node.depends_on and node.depends_on.nodes:  # type: ignore[union-attr]
            for dep in node.depends_on.resolved_nodes:  # type: ignore[union-attr]
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
    artifact_type: ArtifactType,
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
    dbt_selector: Optional[str] = None,
    latest_dir: str = "./latest",
):
    manifest, catalog, run_results = read_artifacts_folder(
        artifacts_path, verbose=verbose
    )
    artifact: Union[Manifest, RunResults]
    if artifact_type == ArtifactType.manifest:
        artifact = manifest
        if not output:
            output = Path("./target/manifest.pdf")
    elif artifact_type == "run":
        artifact = run_results
        if not output:
            output = Path("./target/run_results.pdf")
    else:
        raise ValueError(f"unknown artifact {artifact_type} provided")

    if dbt_selector:
        dbt = dbtRunner()
        include = dbt.invoke(
            [
                "ls",
                "--resource-type",
                "model",
                "--select",
                dbt_selector,
                latest_dir,
            ]
        ).result

    G = build_graph(
        artifact,
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
        url = f"file://{output.resolve()}"  # noqa: E231
        webbrowser.open(url, new=2)  # open in new tab


@app.command()
def ci_report(
    latest_dir: str = "./latest",
    output: str = "target/report.md",
):
    dbt = dbtRunner()
    new_models = dbt.invoke(
        [
            "ls",
            "--resource-type",
            "model",
            "--select",
            "state:new",
            "--state",
            latest_dir,
        ]
    ).result

    modified_models = dbt.invoke(
        [
            "ls",
            "--resource-type",
            "model",
            "--select",
            "state:modified+",
            "--exclude",
            "state:new",
            "--state",
            latest_dir,
        ]
    ).result

    modified_or_downstream_incremental_models = dbt.invoke(
        [
            "ls",
            "--resource-type",
            "model",
            "--select",
            "state:modified+,config.materialized:incremental",
            "--exclude",
            "state:new",
            "--state",
            latest_dir,
        ]
    ).result


    if len(modified_models > 0):
        typer.secho(f"Visualizing the following models: {modified_models}")
        assert isinstance(modified_models, list)
        viz(
            ArtifactType.manifest,
            include=modified_models,
            output=Path("./target/dag.png"),
        )

    env = Environment(
        loader=FileSystemLoader(os.path.join(os.path.dirname(__file__), "templates")),
        autoescape=select_autoescape(),
    )
    template = env.get_template("ci_report.md")
    report = template.render(
        new_models=new_models,
        modified_or_downstream_incremental_models=modified_or_downstream_incremental_models,
    )
    typer.secho(f"Writing to {output}", fg=typer.colors.GREEN)
    with open(output, "w") as f:
        f.write(report)


if __name__ == "__main__":
    app()
