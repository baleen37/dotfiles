#!/bin/bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
    rsync  --exclude "README.md" --exclude "bootstrap.sh" --exclude ".git/" -arv . ~;
    source ~/.bash_profile;
}

doIt;
