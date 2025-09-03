#!/bin/bash

IGNORE=run.sh
TARGET=$HOME

which stow 2> /dev/null > /dev/null
[[ $? -ne 0 ]] && echo "gnu/stow not found!" && exit 1

stow . --target=$TARGET --ignore=$IGNORE -R --adopt
git restore .
stow . --target=$TARGET --ignore=$IGNORE -R
