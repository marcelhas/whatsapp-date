#!/usr/bin/env bash

set -euo pipefail

# Allows running in debug mode by setting the TRACE environment variable.
# e.g. <TRACE=1 ./yt-album.sh>
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

log_succ() {
    printf "${GREEN}%s${RESET}\n" "${*}"
}

log_warn() {
    printf "${YELLOW}%s${RESET}\n" "${*}"
}

log_err() {
    printf "${RED}%s${RESET}\n" "${*}"
}

usage() {
    cat <<USAGE
Usage: ./test.sh URL
Run tests for whatsapp-date.

Options:
  -h, --help
    Show this help message and exit.
  --no-color
    Disable colored output.
  --verbose
    Enable verbose output.

Examples:
  ./test.sh
# Debug mode
TRACE=1 ./test.sh
USAGE
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
    -h | --help | help)
        usage
        exit
        ;;
    --verbose)
        VERBOSE=1
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

main() {
    log_header
    local test_number=1
    local exit_code=0

    for folder in tests/*; do
        [[ -f "$folder" ]] && continue

        set +e
        test "$test_number" "$folder"

        local ret="$?"
        if [[ $ret != "0" && $exit_code == "0" ]]; then
            exit_code="$ret"
        fi
        set -e

        ((test_number++))
    done
    exit $exit_code
}

test() {
    local test_number="$1"
    local folder="$2"

    local expected
    expected="$(cat "$folder/expected.txt")"
    local actual
    actual="$(./whatsapp-date.sh --no-color "$folder/input" 2>&1)"

    local expected_stat
    local actual_stat
    if [[ -f "$folder/stat.txt" ]]; then
        expected_stat="$(cat "$folder/stat.txt")"
        actual_stat="$(get_stats "$folder/input")"
    fi

    if ! is_ok "$expected" "$actual"; then
        log_not_ok "$test_number" "$folder" "$expected" "$actual"
        (exit 1)
    elif ! is_ok "${expected_stat-}" "${actual_stat-}"; then
        log_not_ok "$test_number" "$folder" "${expected_stat-}" \
            "${actual_stat-}"
        (exit 2)
    else
        log_ok "$test_number" "$folder"
        (exit 0)
    fi
}

get_stats() {
    local image_folder="$1"
    local res=""

    for file in "$image_folder"/*; do
        res+="$(basename "$file"):$(stat --format="%y" "$file")"
        res+=$'\n'
    done

    printf "%s" "$res"
}

is_ok() {
    local expected="$1"
    local actual="$2"
    [[ "$actual" == "$expected" ]]
}

log_ok() {
    local test_number="$1"
    local test_name="$2"
    printf "${GREEN}ok %s${RESET} - %s\n" "$test_number" "$test_name"
}

log_not_ok() {
    local test_number="$1"
    local test_name="$2"
    local expected="$3"
    local actual="$4"

    printf "${RED}not ok %s${RESET} - %s\n" "$test_number" "$test_name"
    if [[ -n "${VERBOSE-}" ]]; then
        log_err "---"
        log_warn "Expected:"
        log_succ "$expected"
        log_warn "Actual:"
        log_err "$actual"
    fi
}

log_header() {
    count="$(find tests/* -maxdepth 0 -type d | wc -l)"
    # See <https://testanything.org/>.
    printf "%s\n" "TAP version 14"
    printf "%s\n" "1..$count"
}

main
