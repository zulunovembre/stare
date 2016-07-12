#!/bin/sh

_bold()
{
    printf "\033[1;03m"
}

_underline()
{
    printf "\033[1;04m"
}

_green()
{
    printf "\033[32m"
}

_red()
{
    printf "\033[31m"
}

_normal()
{
    printf "\033[00m"
}

_failure()
{
    _bold ; printf "[" ; _red ; printf "%14s" "FAILURE" ; _normal ; _bold ; printf "]"
    if ! [ -z "$1" ]; then
	printf " ($1)"
    fi
    _normal
}

_success()
{
    _bold ; printf "[" ; _green ; printf "%-14s" "SUCCESS" ; _normal ; _bold ; printf "]" ; _normal
}

_print_result()
{
    if [ -z "$1" ] || [ -z "$2" ]; then
	printf "_print_result <tested cmd> <0 for success, 1 for failure> [output to print if failure]\n"
	return 1
    fi
    printf "    "
    printf "%-40s" "$1"
    if [ "$2" = 0 ]; then
	_success
    else
	_failure "$3"
    fi
    printf "\n"
}

_assert_result_eq()
{
    if [ -z "$1" ] || [ -z "$2" ]; then
	printf "_assert_eq <expr> <expected>\n"
	return 1
    fi
    OUT=$($1 2>&1)
    test "$OUT" = "$2"
    _print_result '[ $('"$1"')'" = $2 ]" $? "$OUT"
}

_assert_success()
{
    if [ -z "$1" ]; then
	printf "_assert_eq <cmd to test>\n"
	return 1
    fi

    OUT="$($1 2>&1)"
    _print_result "$1" $? "$OUT"
}

#_assert_return_is()

_assert_file_exists()
{
    if [ -z "$1" ]; then
	printf "_assert_file_exists <file path>\n"
	return 1
    fi
    _assert_success "[ -f $1 ]"
}

_assert_file_not_exists()
{
    if [ -z "$1" ]; then
	printf "_assert_file_not_exists <file path>\n"
	return 1
    fi
    _assert_success "[ ! -f $1 ]"
}

_assert_exe_exists()
{
    if [ -z "$1" ]; then
	printf "_assert_exe_exists <exe path>\n"
	return 1
    fi

    _assert_file_exists "$1"
    _assert_success "[ -x $1 ]"
}

_assert_cmd_exists()
{
    if [ -z "$1" ]; then
	printf "_assert_cmd_exists <command name>\n"
	return 1
    fi

    _assert_success "command -v $1"
}

test_all24()
{
    _assert_cmd_exists "ffmpeg"
    OUTFILE="./out24.mp4"
    rm -f "$OUTFILE"
    rm -f list
    EXE="../skeleton/all24"
    _assert_exe_exists "$EXE"
    _assert_success "$EXE"
    _assert_file_exists "$OUTFILE"
    _assert_file_not_exists "list"
    rm -f "$OUTFILE"
    rm -f list
}

test_alldirsbydate()
{
    EXE="../alldirsbydate"
    _assert_exe_exists "$EXE"
    RECDIR="rec_tmp"
    mkdir -p "$RECDIR/$RECDIR"
    mkdir "tmp"
    _assert_result_eq "$EXE" "./$RECDIR"
    rmdir -p "$RECDIR/$RECDIR"
    rmdir "tmp"
}

TESTS="
test_all24
test_alldirsbydate
"

all_test()
{
    for TEST in $TESTS; do
	_underline ; printf "$(echo $TEST | sed 's/test_//'):\n" ; _normal
	$TEST
	printf "\n"
    done
}

all_test
