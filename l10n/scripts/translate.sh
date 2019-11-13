#!/bin/bash
#
# Translate pages using po4a according to the configuration file.
#

if [ $0 != './l10n/scripts/gen-po.sh' ]; then
  echo 'Run this script from the reopsitory base directory!' >&2
  exit 1
fi

CONFIG_FILE='l10n/po4a.conf'
REPORT_ADDRESS='https://github.com/tldr-pages/tldr/issues'

# FIXME: k0 only for testing, edit to k100 after generating the po file(s)
po4a -k0 --msgid-bugs-address "$REPORT_ADDRESS" "$CONFIG_FILE"

# TODO: anything more?
