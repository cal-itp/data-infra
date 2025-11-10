c.FileCheckpoints.checkpoint_dir = (  # noqa: F821
    "/home/jovyan/.jupyter/.ipynb_checkpoints/"
)
c.Spawner.args = [  # noqa: F821
    '--NotebookApp.tornado_settings={"headers":{"Content-Security-Policy": "frame-ancestors self https://notebooks.calitp.org"}}',
]
