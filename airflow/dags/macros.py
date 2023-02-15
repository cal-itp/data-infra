"""Macros for Operators"""
import os

from calitp_data.config import is_development

# To add a macro, add its definition in the appropriate section
# And then add it to the dictionary at the bottom of this file

# Is Development ======================================================


def is_development_macro():
    """Make calitp-py's is_development function available via macro"""

    return is_development()


# ACTUALLY DEFINE MACROS =============================================================

# template must be added here to be accessed in dags.py
# key is alias that will be used to reference the template in DAG tasks
# value is name of function template as defined above


data_infra_macros = {
    "is_development": is_development_macro,
    "image_tag": lambda: "development" if is_development() else "latest",
    "env_var": os.getenv,
}
