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

# dnwlx.sh - downloads and extracts a tarball into a directory. 
#
# The goal is to produce a cleanly named directory with the sources
# to avoid version-dependent naming.

usage()
{
    cat 1>&2 <<"END"
Usage:
    sh dwnlx.sh EXTRACTDIR NAME URL [FILENAME]

    EXTRACTDIR   directory to extract tarball to
    NAME         name to rename tarball's subdirectory to
    URL          URL to fetch tarball from into a current directory
    FILENAME     optional name of the file, in case URL doesn't 
                 have a proper name

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

EXTRACTDIR="$1"
if [ "x$EXTRACTDIR" = "x" ]; then
    err "Unspecified directory to extract tarball to"
    usage && exit 1
fi
NAME="$2"
if [ "a$NAME" = "a" ]; then
    err "Unspecified NAME of the tarball's subdirectory"
    usage && exit 1
fi
URL="$3"
if [ "a$URL" = "a" ]; then
    err "Unspecified URL of the tarball"
    usage && exit 1
fi
FILENAME="$4"
if [ "x$FILENAME" = "x" ]; then
    FILENAME=${URL##*/}
    if [ "x$FILENAME" = "x" ]; then
	err "Cannot guess filename from the URL '$URL'"
	exit 1
    fi
fi

if [ ! -e "$FILENAME" ]; then
    printf "%s" "Downloading $FILENAME ... "
    dwnl "$URL" >$FILENAME 2>/dev/null
    if [ $? -eq 0 ]; then
	printf "%s\n" "ok"
    else
	printf "%s\n" "failed"
	err "Failed to download '$URL'" && exit 2
    fi
fi

mkdir -p $EXTRACTDIR
if [ $? -ne 0 ]; then
    err "Failed to create dir '$EXTRACTDIR'" && exit 3
fi

if [ ! -e "$EXTRACTDIR/$NAME" ]; then
    printf "%s" "Extracting $FILENAME ... "
    tar -C $EXTRACTDIR -xf $FILENAME >/dev/null 2>&1
    if [ $? -eq 0 ]; then
	printf "%s\n" "ok"
    else
	printf "%s\n" "failed"
	err "Failed to extract $FILENAME" && exit 4
    fi

    dirname=""
    case "$FILENAME" in
	*.tar.gz)  dirname=${FILENAME%%.tar.gz} ;;
	*.tar.bz2) dirname=${FILENAME%%.tar.bz2} ;;
	*.txz)     dirname=${FILENAME%%.txz} ;;
	*.tar*)    dirname=${FILENAME%%.tar*} ;;
	*) err "Unsupported archive extension in '$FILENAME'" && exit 5
    esac

    mv $EXTRACTDIR/$dirname $EXTRACTDIR/$NAME
    if [ $? -ne 0 ]; then
	err "Cannot rename $dirname into $NAME" && exit 5
    fi
fi

