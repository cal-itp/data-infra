"""
Provide more visualizations than what dbt provides.
"""
import json
from pathlib import Path
from typing import Any, Type

import gcsfs
import matplotlib.pyplot as plt
import networkx as nx
import typer
from dbt_artifacts import Manifest, Model, RunResults, Seed, Source
from networkx_viewer import Viewer

app = typer.Typer()


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
    graph_path: Path = Path("./target/graph.gpickle"),
    verbose: bool = False,
):
    manifest: Manifest = read_artifact(manifest_path, Manifest, verbose=verbose)

    G = nx.Graph()
    for node in manifest.nodes.values():
        if isinstance(node, Model):
            # G.add_node(node.name)

            if node.depends_on and node.depends_on.nodes:
                for dep in node.depends_on.resolved_nodes:
                    G.add_edge(node.name, dep.name)

    nx.draw_networkx(G, font_size=4, pos=nx.spring_layout(G))

    # Set margins for the axes so that nodes aren't clipped
    ax = plt.gca()
    ax.margins(0.20)
    plt.axis("off")
    plt.show()


@app.command()
def runviz(
    manifest_path: Path = Path("./target/manifest.json"),
    run_results_path: Path = Path("./target/run_results.json"),
    graph_path: Path = Path("./target/graph.gpickle"),
    output: Path = Path("./target/dag.png"),
    verbose: bool = False,
    sources: bool = True,
    seeds: bool = True,
):
    manifest: Manifest = read_artifact(manifest_path, Manifest, verbose=verbose)
    run_results: RunResults = read_artifact(
        run_results_path, RunResults, verbose=verbose
    )
    run_results.set_manifest(manifest)

    G = nx.DiGraph()
    # We add all results as nodes
    for result in run_results.results:
        G.add_node(
            result.node.graphviz_repr, **{**result.node.gv_attrs, **result.gv_attrs}
        )
    # Then, add edges plus other nodes if not already added as a result node
    for result in run_results.results:
        node = result.node
        if node.depends_on and node.depends_on.nodes:
            for dep in node.depends_on.resolved_nodes:
                if isinstance(dep, Source) and not sources:
                    continue
                if isinstance(dep, Seed) and not seeds:
                    continue
                if dep.graphviz_repr not in G:
                    G.add_node(dep.graphviz_repr, **dep.gv_attrs, style="dashed")
                G.add_edge(node.graphviz_repr, dep.graphviz_repr)

    A = nx.nx_agraph.to_agraph(G)
    A.layout(prog="dot")
    if verbose:
        print(f"Writing DAG to {output}")
    A.draw(output)


@app.command()
def guiviz(
    graph_path: Path = Path("./target/graph.gpickle"),
):
    G = nx.read_gpickle(graph_path)
    app = Viewer(G)
    app.mainloop()


if __name__ == "__main__":
    app()
