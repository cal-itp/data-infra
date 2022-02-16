import django
import os
import sys

sys.path.append(".")

os.environ["DJANGO_SETTINGS_MODULE"] = "main.settings"
django.setup()
