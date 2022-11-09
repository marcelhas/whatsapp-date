#!/usr/bin/env bash

set -euo pipefail

# Allows running in debug mode by setting the TRACE environment variable.
# e.g. <TRACE=1 ./yt-album.sh>
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

usage() {
  printf \
  'Usage: whatsapp-date.sh <directory>

Examples:
./whatsapp-date.sh ./images/
# Debug mode
TRACE=1 ./whatsapp-date.sh ./images/
'
}

err() {
  echo "$1" >&2
}

if [[ -z "${1-}" || "${1-}" =~ ^-*h(elp)?$ ]]; then
    usage
    exit
fi

[[ ! -d $1 ]] && echo "Directory does not exist!" && usage && exit 1;
dir="$1"

min_date=$(date -d "2000-01-01 00:00:00" --rfc-3339=s)
max_date=$(date -d "2099-12-31 23:59:59" --rfc-3339=s)

success=0
total=0

for name in "$dir/"*; do
  total=$((total + 1))
  filename="$(basename "$name")"

  # Check expected filename format.
  # See <https://regex101.com/r/SWfL4C/1>
  if [[ ! $filename =~ ^IMG-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-WA[0-9][0-9][0-9][0-9]\.(jpg|jpeg|JPG|JPEG)$ ]]; then
    err "$filename is invalid! skipping ..."
    continue
  fi

  # Check if date is valid.
  if ! date="$(date -d "${filename:4:8}" --rfc-3339=s 2> /dev/null)"; then
    err "$filename is an invalid date! skipping ..."
    continue
  fi

  # Sanity check 1.
  if [[ $date < $min_date ]] ; then
    err "$filename is before 2000-01-01! skipping ..."
    continue
  fi

  # Sanity check 2.
  if [[ $date > $max_date ]] ; then
    err "$filename is after 2099-12-31! skipping ..."
    continue
  fi

  # Set access and modified date to parsed date.
  touch -amt "${filename:4:8}0900" "$name"

  success=$((success + 1))
done

echo "Changed $success of $total files."

exit 0
