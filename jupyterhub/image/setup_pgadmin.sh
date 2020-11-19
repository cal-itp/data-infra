#!/bin/bash

# Patch the app so that we can run in desktop mode under a base URL
cd ${CONDA_DIR}/lib/python3.7/site-packages/pgadmin4
cat << EOF > pgadmin.patch
--- pgadmin/__init__.py	2019-09-05 09:44:56.236006700 -0700
+++ patch.py	2019-09-05 09:44:35.661418600 -0700
@@ -105,7 +105,7 @@
         #############################################################
         import config
         is_wsgi_root_present = False
-        if config.SERVER_MODE:
+        if config.SERVER_MODE or True:
             pgadmin_root_path = url_for('browser.index')
             if pgadmin_root_path != '/browser/':
                 is_wsgi_root_present = True
EOF
patch -p0 < pgadmin.patch
rm pgadmin.patch
cd $HOME

# Importing the app initializes the necessary config and user database
python -c "import builtins; builtins.SERVER_MODE = False; from pgadmin4.pgAdmin4 import app"
