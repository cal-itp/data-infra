c.FileCheckpoints.checkpoint_dir = (  # noqa: F821
    "/home/jovyan/.jupyter/.ipynb_checkpoints/"
)
c.JupyterHub.subdomain_host = "https://notebooks.calitp.org"  # noqa: F821
c.Spawner.args = [  # noqa: F821
    "--VoilaConfiguration.enable_nbextensions=True",
    "--VoilaConfiguration.file_whitelist=['.*']",
    '--NotebookApp.tornado_settings={"headers":{"Content-Security-Policy": "frame-ancestors \'self\'"}}',
]
