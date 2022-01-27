from setuptools import setup, find_packages

setup(
    name="gtfs-rt-archive",
    version="rolling",
    packages=find_packages(),
    install_requires=["google-auth==1.33.0", "PyYAML==5.4.1"],
)
