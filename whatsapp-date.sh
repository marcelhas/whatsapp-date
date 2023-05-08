#!/usr/bin/env bash

set -euo pipefail

# Allows running in debug mode by setting the TRACE environment variable.
# e.g. <TRACE=1 ./yt-album.sh>
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

DRY_RUN=

log_succ() {
  printf "${GREEN}%s${RESET}\n" "${*}"
}

log_warn() {
  printf "${YELLOW}%s${RESET}\n" "${*}" 1>&2
}

log_err() {
  printf "${RED}%s${RESET}\n" "${*}" 1>&2
}

usage() {
  printf \
    'Usage: whatsapp-date.sh <directory>

Options:
  -h, --help
    Show this help message and exit.
  --dry-run
    Run without modifying images.
  --no-color
    Disable colored output.

Examples:
./whatsapp-date.sh ./images/
# Debug mode
TRACE=1 ./whatsapp-date.sh ./images/
'
}

die() {
  log_err "${*}"
  usage
  exit 1
}

while :; do
  case ${1-} in
  # Two hyphens ends the options parsing
  --)
    shift
    break
    ;;
  -h | --help | help | "")
    usage
    exit
    ;;
  --dry-run)
    DRY_RUN=1
    ;;
  --no-color)
    GREEN=""
    YELLOW=""
    RED=""
    RESET=""
    ;;
  # Anything remaining that starts with a dash triggers a fatal error
  -?*)
    die "The command line option is unknown: $1"
    ;;
  # Anything remaining is treated as content not a parseable option
  *)
    break
    ;;
  esac
  shift
done

[[ ! -d $1 ]] && echo "Directory does not exist!" && usage && exit 1
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
    log_warn "$filename is invalid! skipping ..."
    continue
  fi

  # Check if date is valid.
  if ! date="$(date -d "${filename:4:8}" --rfc-3339=s 2>/dev/null)"; then
    log_warn "$filename is an invalid date! skipping ..."
    continue
  fi

  # Sanity check 1.
  if [[ $date < $min_date ]]; then
    log_warn "$filename is before 2000-01-01! skipping ..."
    continue
  fi

  # Sanity check 2.
  if [[ $date > $max_date ]]; then
    log_warn "$filename is after 2099-12-31! skipping ..."
    continue
  fi

  new_date=${filename:4:8}

  if [[ -z $DRY_RUN ]]; then
    # Set access and modified date to parsed date.
    touch -amt "${new_date}0900" "$name"
  else
    log_succ "$filename would be set to $new_date"
  fi

  success=$((success + 1))
done

msg="Changed $success of $total files."
if [[ $success -eq $total ]]; then
  log_succ "$msg"
elif [[ $success -le 0 ]]; then
  log_err "$msg"
  exit 1
else
  log_warn "$msg"
fi

exit 0
