#!/bin/bash
VERSION="Command line clock, ver 0.3.0 (2/4/2024)"
set -eu -o pipefail

function usage() {
    local prog=$(basename $0)
    which $prog >/dev/null 2>&1 || prog=$0
    echo "Usage: $prog [options] [countdown]"
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -v, --version   Show version"
    echo "  -f, --figlet    Use figlet to show message"
    echo "  -t, --toilet    Use toilet to show message"
    echo "  -p, --plain     Use plain text to show message"
    echo "  countdown       Countdown seconds"
    echo ""
    echo "Examples:"
    echo "  $prog 60"
    echo "  $prog -f 60"
    echo "  $prog -t 60"
    echo "  $prog -p 60"
    echo ""
}

function parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                echo $VERSION
                exit 0
                ;;
            -f|--figlet)
                OUTTEXT=figlet_text
                DELAY=0.1
                ;;
            -t|--toilet)
                OUTTEXT=toilet_text
                DELAY=0.1
                ;;
            -p|--plain)
                OUTTEXT=plain_text
                DELAY=0.05
                ;;
            -*)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                COUNT_DOWN=$1
                ;;
        esac
        shift
    done
}

function startup() {
    # hide cursor
    echo -e "\e[?25l"
    trap cleanup EXIT
    trap cleanup SIGINT
    trap cleanup SIGTERM
    clear
}

function cleanup() {
    echo ""
    # show cursor
    echo -e "\e[?25h"
    exit 0
}

function config() {
    T1=$(date +%s%N)
    parse_args "$@"
    test -v OUTTEXT && return
    if which figlet >/dev/null 2>&1; then
        OUTTEXT=figlet_text
        DELAY=0.1
    elif which toilet >/dev/null 2>&1; then
        OUTTEXT=toilet_text
        DELAY=0.1
    else
        OUTTEXT=plain_text
        DELAY=0.005
    fi
}

function plain_text() {
    printf "\r"
    tput cup 5 20
    echo -n $*
}

function figlet_text() {
    clear # no clear, no flash
    tput cup 5
    # -r flush right
    figlet -t -W -l $*
}

function toilet_text() {
    #clear
    tput cup 5
    toilet $*
}

function show_duration() {
    local t=$1
    local sec=$(( t/1000000000))
    local cs=$((t/10000000 - sec*100))
    local min=$((sec/60))
    sec=$((sec-min*60))
    local txt
    if test $min -gt 0; then
        txt=$(printf "%d:%02d.%02d" $min $sec $cs)
    else
        txt=$(printf "%d.%02d" $sec $cs)
    fi
    $OUTTEXT $txt
}

function check_keypress() {
    local key
    # -s: no echo; -r: no escape; -n: 1 char; -t: timeout
    read -t $DELAY -n 1 -sr key && return 0
    return 1
}

function time_is_up() {
     show_duration 0
     echo -e "\a"
}

function count_watch() {
    local count=$((COUNT_DOWN * 1000000000))
    echo "Press any key to stop"
    echo ""
    while true; do
        local t2=$(date +%s%N)
        local t=$((t2-T1))
        if test $count -gt 0; then
            t=$((count - t))
            test $t -lt 0 && time_is_up && break
        fi
        show_duration $t
        check_keypress && break
    done
}

function normal_clock() {
    while true; do
        local t=$(date +%T.%2N)
        $OUTTEXT $t
        check_keypress && break
    done
}

function main() {
    config "$@"
    startup
    test -v COUNT_DOWN && count_watch || normal_clock
    cleanup
}

main "$@"
