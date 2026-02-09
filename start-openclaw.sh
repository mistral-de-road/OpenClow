#!/bin/bash
set -ex
echo "DEBUG START"
date
echo "Starting dummy gateway on 18789..."
# Just listen on the port to satisfy waitForPort
nc -lk -p 18789 -e echo "dummy" &
echo "Dummy gateway started."
while true; do
  echo "Still alive: $(date)"
  sleep 60
done
