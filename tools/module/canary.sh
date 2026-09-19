#!/usr/bin/env bash
# The canary of pkgconf: check_undef_set.sh must fail for a header that has an
# entry without a check, and must pass for a correct header.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
status=0
expect() {  # name, wanted exit code (0 or "fail"), command...
  local name="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if { [[ "$want" == 0 && $got == 0 ]] || [[ "$want" == fail && $got != 0 ]]; }; then echo "ok   $name"; else echo "FAIL $name  <- exit $got"; status=1; fi
}
printf '#define HAVE_STRLCPY 1\n/* #undef _LARGE_FILES */\n' > "$tmp/good.h"
printf '#define HAVE_STRLCPY 1\n/* #undef _LARGE_FILES */\n/* #undef HAVE_NEW_THING */\n' > "$tmp/extra.h"
printf '#define HAVE_STRLCPY 1\n' > "$tmp/absent.h"
expect "undef set: a correct header passes" 0 "$here/check_undef_set.sh" "$tmp/good.h"
expect "undef set: an entry without a check fails" fail "$here/check_undef_set.sh" "$tmp/extra.h"
expect "undef set: an expected entry that is absent fails" fail "$here/check_undef_set.sh" "$tmp/absent.h"
exit $status
