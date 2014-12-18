#!/bin/bash

echo "Installing general files..."

CURRENT_DIR=$(dirname $0)
TARGET_DIR=$HOME

find ./ -maxdepth 1 -type f -exec cp {} $TARGET_DIR \;
