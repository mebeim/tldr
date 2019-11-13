#!/bin/bash
#
# Bootstrap the translation process by incrementally building a .po file for
# each page of the chosen language.
#
# Given a language 'XX', this script:
#
#   1. Recursively scans the language specific folder 'pages.XX'.
#   2. Runs po4a-gettextize to generate a .po file for each page in the folder.
#   3. If any error occurs during generation, pauses execution and asks for user
#      intervention.
#   4. Saves each generated .po file under 'l10n/tldr.XX.bootstrap'.
#   5. TODO: merges all the generated .po files into a single 'l10n/XX.po' file.
#
# If any .po file already exists in 'l10n/tldr.XX.bootstrap', it is skipped to
# save time, assuming the operation was previously stopped and it's now resumed.
#

function prettyprint {
  local f=$1
  local l=`wc -c <<< "$f"`
  local pad=`printf '%*c' $(($FNAME_PAD-$l+3)) . | tr ' ' .`

  printf "[%*d/%d] %s${pad} " $N_PAD $I $N_PAGES "$f"
}

if [ $0 != './l10n/scripts/bootstrap-translation.sh' ]; then
  echo 'Run this script from the reopsitory base directory!' >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <LANGUAGE>" >&2
  exit 1
fi

if [ ! -d "pages.$1" ]; then
  echo "Directory 'pages.$1' does not exist, specify a valid language." >&2
  exit 1
fi

TMP_DIR="l10n/tldr.$LLANGUAGE.bootstrap"

if mkdir -p "$TMP_DIR"; then
  echo "Temporary .po files will be written in '$TMP_DIR'."
else
  echo "Unable to create directory '$TMP_DIR', aborting."
  exit 1
fi

LLANGUAGE=$1
TMP_STDERR="$TMP_DIR/.stderr"
GETTEXTIZE='po4a-gettextize -f text -o markdown -o neverwrap -LUTF-8 -MUTF-8'
PAGES=`find pages.$LLANGUAGE -type f -name '*.md' | sort`
N_PAGES=`wc -l <<< "$PAGES"`
N_PAD=`wc -c <<< "$N_PAGES"`
((N_PAD--))
FNAME_PAD=`wc -L <<< "$PAGES" | cut -d' ' -f1`
I=1
LINE='=================================================='

echo "$LINE"

for fname in $PAGES; do
  eng_fname="${fname/.$LLANGUAGE/}"
  po_fname="$TMP_DIR/${fname//'/'/_}.po"

  if [ -f "$po_fname" ]; then
    prettyprint "$fname"
    echo 'OK (already exists).'
    ((I++))
    continue
  fi

  while true; do
    prettyprint "$fname"

    $GETTEXTIZE -m "$eng_fname" -l "$fname" -p "$po_fname" 2>"$TMP_STDERR"

    if [[ $? -eq 0 ]]; then
      echo 'OK.'
      break
    else
      echo 'ERROR!'
      echo "$LINE"
      cat "$TMP_STDERR"
      echo "$LINE"
      echo 'You should check these two files, fix any problem and retry:'
      echo ''
      echo "    $eng_fname"
      echo "    $fname"
      echo ''

      while true; do
        read -p 'What to do ([R]etry / [e]xamine / [s]top)? ' choice

        case $choice in
          '') ;&
          [rR])
            break
            ;;

          [eE])
            vim -O "$eng_fname" "$fname"
            break
            ;;

          [sS])
            echo "$LINE"
            echo 'Stopping. You can resume the work later by running this command again.'
            echo "Generated .po files were saved in '$TMP_DIR'."
            exit 0
            ;;
        esac
      done

      echo "$LINE"
    fi
  done

  ((I++))
done

# TODO: merge po files together here...
