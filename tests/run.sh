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
    _SPACE="70"
    printf "%-${_SPACE}s" "$1"
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
	printf "_assert_eq <cmd to test> [timeout in seconds]\n"
	return 1
    fi

    if ! [ -z $2 ]; then
	OUT="$($1 2>&1)" &
	PID=$!
	sleep $2
	if ps | grep -F "$1"; then
	    _print_result "$1" 1 "timeout"
	    kill -TERM $PID
	    return -1
	fi
    else
	OUT="$($1 2>&1)"
    fi
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

_assert_files_exist()
{
    if [ -z "$1" ]; then
	printf "_assert_files_exist <file paths>\n"
	return 1
    fi
    for FILE in $1; do
	_assert_file_exists "$FILE"
    done
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

test_record()
{
    EXE="../record"
    DEV="/dev/video0"
    DIR="tmp"
    NBPICS=3
    WAITTIME=$(echo $NBPICS+2 | bc)
    MAXID=$(echo $NBPICS-1 | bc)
    mkdir "$DIR"

    _assert_success "[ -r $DEV ]"
    _assert_success "[ -c $DEV ]"
    _assert_cmd_exists "ffmpeg"
    _assert_exe_exists "$EXE"
    _assert_success "$EXE $DEV 1 $DIR $NBPICS" $WAITTIME
    _assert_file_exists i
    RECDIR=$(find "$DIR" -type d -name 'rec_*')
    _assert_success "[ $(echo $RECDIR | wc -l) = 1 ]"
    FILES=$(for I in $(seq 0 $MAXID); do printf "$RECDIR/$I.jpg\n"; done;)
    _assert_success "[ $(echo $FILES | wc -w) = $NBPICS ]"
    if _assert_files_exist "$FILES"; then
	rm -f $FILES
    fi

    rm -f i
    rmdir "$DIR"/*
    rmdir "$DIR"
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

_FAKE_DIR="tmp"
_FAKE_RECDIR1_NAME="rec_1"
_FAKE_RECDIR1="$_FAKE_DIR/$_FAKE_RECDIR1_NAME"
_FAKE_RECDIR2_NAME="rec_2"
_FAKE_RECDIR2="$_FAKE_DIR/$_FAKE_RECDIR2_NAME"
_FAKE_RECDIR3_NAME="rec_3"
_FAKE_RECDIR3="$_FAKE_RECDIR1/$_FAKE_RECDIR3_NAME"
_FAKE_FILE_NAME="fake.jpg"
_FAKE_FILE="$_FAKE_RECDIR2/$_FAKE_FILE_NAME"

_setup_fake_recdir()
{
    mkdir "$_FAKE_DIR"
    mkdir "$_FAKE_RECDIR1"
    mkdir "$_FAKE_RECDIR3"
    mkdir "$_FAKE_RECDIR2"
    touch "$_FAKE_FILE"
}

_clean_fake_recdir()
{
    rm -f "$_FAKE_FILE"
    rmdir -p "$_FAKE_RECDIR3" 2> /dev/null
    rmdir "$_FAKE_RECDIR2" 2> /dev/null
    rmdir "$_FAKE_DIR"
}

test_lastrecdir()
{
    _setup_fake_recdir

    EXE="../lastrecdir"
    _assert_exe_exists "$EXE"
    _assert_result_eq "$EXE $_FAKE_DIR" "$_FAKE_RECDIR2"

    _clean_fake_recdir
}

test_pinlast()
{
    _setup_fake_recdir

    EXE="../pinlast"
    _assert_exe_exists "$EXE"
    _assert_success "$EXE $_FAKE_DIR"
    LINK="$_FAKE_DIR/last_dir"
    _assert_success "[ -L $LINK ]"
    unlink "$LINK"

    _clean_fake_recdir
}

test_tarall()
{
    _setup_fake_recdir

    EXE="../tarall"
    _assert_cmd_exists "tar"
    _assert_exe_exists "$EXE"
    ARCHNAME="test.tar.gz"
    _assert_success "$EXE $_FAKE_DIR $ARCHNAME"
    _assert_file_exists "$ARCHNAME"

    _clean_fake_recdir

    _assert_success "tar zxf $ARCHNAME"

    _assert_result_eq "find tmp/ -mindepth 1 -maxdepth 1 -printf %f" "$_FAKE_RECDIR1_NAME$_FAKE_RECDIR2_NAME"
    _assert_result_eq "find tmp/ -mindepth 2 -maxdepth 2 -printf %f" "$_FAKE_RECDIR3_NAME$_FAKE_FILE_NAME"

    _clean_fake_recdir
    rm "$ARCHNAME"
}

TESTS="
test_record
test_lastrecdir
test_pinlast
test_all24
test_alldirsbydate
test_tarall
"

run_tests()
{
    for TEST in $TESTS; do
	_underline ; printf "$(echo $TEST | sed 's/test_//'):\n" ; _normal
	$TEST
	printf "\n"
    done
}

if ! [ -z $1 ]; then
    TESTS="test_$1"
fi

run_tests
