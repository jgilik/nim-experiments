#!/bin/bash
set -Eeo pipefail
DIR(){(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)}
source "$(DIR)/../buildrules.sh"
nim_binary hello
nim_binary question
