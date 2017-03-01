# /bin/bash
# Contains build rules for nim binaries.
set -Eeo pipefail
DIR(){(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)}
ORIGIN(){(cd "$(dirname "$0")" && pwd)}

_tocleanup=()
_cleanup()
{
  for f in "${_tocleanup[@]}"
  do
    if [[ -z "$f" ]]
    then
      continue
    fi
    rm -f "$f"
  done
}
trap _cleanup EXIT ERR
_defercleanup()
{
  _tocleanup+=("$@")
}

bin_dir="$(ORIGIN)/bin"
debug_bin_dir="$bin_dir/debug"
release_bin_dir="$bin_dir/release"
tmp_dir="$(ORIGIN)/tmp"
log_dir="$tmp_dir/logs"
for dir in "$bin_dir" "$debug_bin_dir" "$release_bin_dir" \
  "$tmp_dir" "$log_dir"
do
  if [[ ! -e "$dir" ]]
  then
    mkdir -v "$dir"
  fi
done

if ! type nim
then
  echo "$(basename "$0"): command 'nim' not found" >&2
  exit 1
fi

check_warnings()
{
  if grep -E '^[^(]+\([0-9]+,\s*[0-9]+\) Warning: ' "$@" 2>/dev/null \
    | grep -v -E '^lib/nim/' >/dev/null 2>&1
  then
    echo "Found warnings - aborting build." >&2
    return 1
  fi
}

nim_binary()
{
  name="$1"
  src_file="${name}.nim"
  bin_file="${name}"
  name_mangled="$(echo "${name}" | sed -r -e 's@^[0-9]+@@g' -e 's@[-]@@g')"
  src_file_tmp=""
  if [[ "$name_mangled" != "$name" ]]
  then
    src_file_tmp="$(mktemp --tmpdir="$PWD" -t "${name_mangled}tmpXXXXXXXX.nim")"
    _defercleanup "$src_file_tmp"
    cp "$src_file" "$src_file_tmp"
    src_file="$src_file_tmp"
  fi
  compile_flags=()
  compile_flags+=("--hints:on")
  compile_flags+=("--warnings:on")
  compile_flags+=("--verbosity:2")

  # Debug build mode
  echo "Building $name (debug build)"
  log_name="${log_dir}/${name}.debug.log"
  nim compile \
    "--out:$debug_bin_dir/$bin_file" \
    "${compile_flags[@]}" "$src_file" \
    2>&1 | tee "$log_name"
  #check_warnings "$log_name"

  # Release build mode
  echo "Building $name (release build)"
  log_name="${log_dir}/${name}.release.log"
  # Add release-specific flags here:
  compile_flags+=("--define:release")
  compile_flags+=("--opt:speed")
  nim compile \
    "--out:$release_bin_dir/$bin_file" \
    "${compile_flags[@]}" "$src_file" \
    2>&1 | tee "$log_name"
  #check_warnings "$log_name"
}

nim_test()
{
  name="$1"
  nim_binary "$1"
  if ! "${debug_bin_dir}/$name"
  then
    echo "FAIL: nim_test '$name' failed" >&2
    return 1
  fi
  echo "PASS: nim_test '$name' passed" >&2
}
