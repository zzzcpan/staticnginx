#!/bin/sh

# Copyright (c) 2015 Alexandr Gomoliako. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials provided
#     with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# chkupd.sh - checks URL for update

usage()
{
    cat 1>&2 <<"END"
Usage:
    sh chkupd.sh LEFT RIGHT EXPECTED URL

    LEFT         left part of the string to search for
    RIGHT        right part of the string to search for
    EXPECTED     expected part in the middle
    URL          URL of the page to search in

END
}

err()
{
    echo 1>&2 "$0: ERROR: $*"
}

dwnl()
{
    if [ -e /usr/bin/fetch ]; then
	/usr/bin/fetch -o - "$1"
    elif [ -e /usr/bin/wget ]; then
	/usr/bin/wget -O - "$1"
    else
	err "Cannot find fetch/wget tool to use for download"
	return 42
    fi
}

L="$1"
if [ "x$L" = "x" ]; then
    err "Unspecified left part of the string to search"
    usage && exit 1
fi
R="$2"
if [ "a$R" = "a" ]; then
    err "Unspecified right part of the string to search"
    usage && exit 1
fi
EX="$3"
if [ "a$EX" = "a" ]; then
    err "Unspecified expected result in the middle"
    usage && exit 1
fi
URL="$4"
if [ "a$URL" = "a" ]; then
    err "Unspecified URL of the tarball"
    usage && exit 1
fi

VAL=` dwnl "$URL" 2>/dev/null | while IFS="" read -r line; do
    case "$line" in
    *$L*$R*)
	line=${line#*$L}
	line=${line%%$R*}
	echo $line
	;;
    esac
done | sort -r -u `

# taking first element of the list
for a in $VAL; do 
    VAL="$a"
    break
done

if [ "x$VAL" != "x$EX" ]; then
    err "Found update '$VAL', '$L$VAL$R'"
    exit 10
fi

echo 1>&2 "$0: No updates found"

