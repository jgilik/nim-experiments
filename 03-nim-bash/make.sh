#!/bin/bash
set -Eeo pipefail
DIR(){(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)}
source "$(DIR)/../buildrules.sh"

nbash_binary()
{
  name="$1"
  echo -e "import nbash\nexecScriptFromFile(\"${name}.sh\")\n" \
    > "${name}.nim"
  nim_binary "$name"
  rm "${name}.nim"
}

nbash_test()
{
  name="$1"
  nbash_binary "$name"
  diff <(bash "${name}.sh") <("bin/debug/${name}") || \
  {
    echo "FAIL: ${name}.sh does not match!" >&2
    return 1
  }
  echo "PASS: ${name}.sh matches in bash and nbash" >&2
}

nim_test "bashlexer_test"
nbash_test "01-echo"
#nbash_test "02-semicolons"
#nbash_test "03-non-builtins"
#nbash_test "04-if-statement"
