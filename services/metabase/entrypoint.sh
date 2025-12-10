#! /bin/bash

# Forward TCP:5432 to Cloud SQL Unix socket
nohup socat -d -d TCP4-LISTEN:5432,fork UNIX-CONNECT:pg.sock &

# Runs Metabase
/app/run_metabase.sh
