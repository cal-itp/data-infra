c.FileCheckpoints.checkpoint_dir = (  # noqa: F821
    "/home/jovyan/.jupyter/.ipynb_checkpoints/"
)

c.JupyterHub.tornado_settings = {  # noqa: F821
    "headers": {"Content-Security-Policy": "frame-ancestors *;"}
}
c.Spawner.args = [  # noqa: F821
    '--ServerApp.tornado_settings={"headers":{"Content-Security-Policy": "frame-ancestors *;"}}'
]
