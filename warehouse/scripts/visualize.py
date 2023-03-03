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
from dbt_artifacts import Manifest, Model, RunResults
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
    run_results: RunResults = read_artifact(
        run_results_path, RunResults, verbose=verbose
    )

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
    verbose: bool = False,
):
    manifest: Manifest = read_artifact(manifest_path, Manifest, verbose=verbose)
    run_results: RunResults = read_artifact(
        run_results_path, RunResults, verbose=verbose
    )

    G = nx.DiGraph()
    for result in run_results.results:
        node = manifest.nodes[result.unique_id]
        if node.depends_on and node.depends_on.nodes:
            for dep in node.depends_on.resolved_nodes:
                G.add_edge(node.name, dep.name)
        else:
            G.add_node(node.name)

    nx.draw_networkx(
        G,
        pos=nx.planar_layout(G),
        # font_size=36,
        node_size=3000,
        node_color="white",
        # edgecolors="black",
        # linewidths=5,
        # width=5,
    )

    # Set margins for the axes so that nodes aren't clipped
    ax = plt.gca()
    ax.margins(0.20)
    plt.axis("off")
    plt.show()


@app.command()
def guiviz(
    graph_path: Path = Path("./target/graph.gpickle"),
):
    G = nx.read_gpickle(graph_path)
    app = Viewer(G)
    app.mainloop()


if __name__ == "__main__":
    app()
