# Makefile for baleen's dotfiles - mitchellh style

# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= root

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# OS detection (mitchellh exact pattern)
UNAME := $(shell uname)

.DEFAULT_GOAL := help