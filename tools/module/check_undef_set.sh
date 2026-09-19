#!/usr/bin/env bash
# The generated config.h must have no template entry without a check.
#
# rules_cc_autoconf writes an entry that no check fills as `/* #undef NAME */`.
# pkgconf reads these names with `#if`, not `#ifdef`, so a name that is absent
# makes pkgconf use its fallback code and gives no warning. The names in
# expected_undef.txt are correct as `#undef`; each other name needs a check.
set -euo pipefail

config_h="${1:?usage: check_undef_set.sh <generated config.h>}"
expected="$(dirname "$0")/expected_undef.txt"

found="$(grep -oE '#undef +[A-Za-z0-9_]+' "$config_h" | awk '{print $2}' | sort -u)"
if diff <(grep -vE '^(#|$)' "$expected" | sort -u) <(echo "$found"); then
  echo "check_undef_set: the #undef entries are as expected: $(echo $found)"
else
  echo "check_undef_set: '<' is expected and absent, '>' is new and needs a check in the overlay" >&2
  exit 1
fi
# test
