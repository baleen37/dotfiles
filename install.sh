#!/bin/bash

echo "Installing general files..."

CURRENT_DIR=$(dirname $0)
TARGET_DIR=$HOME

find ./$CURRENT_DIR -maxdepth 1 -type f ! -name 'install.sh' -exec cp {} $TARGET_DIR \;
