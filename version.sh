#!/bin/bash
set -euo pipefail

dpkg -s matrix-synapse-py3 | grep 'Version:' | tr '+' ' ' | awk '{print $2}'
