#!/bin/bash
# Script to automatically setup git hooks for the project.

set -e

ln -sf ../../support/pre-commit ./.git/hooks/pre-commit

