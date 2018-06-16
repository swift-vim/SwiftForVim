#!/bin/bash

# Find vims and pythons
# Tested under:
# - brew vim8 / python 2.7
# - brew vim8 / python 3.6.5
# - brew macvim / python 3.6.5
# - custom built vims against OSX python

function realpath() {
    echo $(python -c "import os; print os.path.realpath('$1')")
}

function find_py_from_vim() {
    VIM_PATH=""
    WHICH_VIM=$(realpath $(which vim))

    if [[ $(echo $(file $WHICH_VIM) | grep -q shell; echo $?) -eq 0 ]]; then
        # Assumptions about vim inside of MacVim.app which is a script
        if [[ $(cat $WHICH_VIM | grep -q MacVim; echo $?) -eq 0 ]]; then
            VIM_PATH=$(dirname $(dirname $WHICH_VIM))/MacOS/Vim
        fi
    else
        VIM_PATH=$WHICH_VIM
    fi

    if [[ $(test -x "$VIM_PATH") -ne 0 ]]; then
        >&2 echo "error: can't find vim"
        exit 1
    fi

    _PYTHON_LINKED=$(otool -l $VIM_PATH  | grep Python | awk '{ print $2 }')
    PYTHON_F=$(realpath $_PYTHON_LINKED)
}

# If the user specifies, we'll use a python.
# This must point to the actual version:
# /System/Library/Frameworks/Python.framework/Python
# and is mainly for testing only.
if [[ "$USE_PYTHON" ]]; then
    >&2 echo "using specified python $USE_PYTHON"
    PYTHON_F=$(realpath "$USE_PYTHON")
else
    find_py_from_vim
fi

# Test if we've got a dylib on our hands.
if [[ $(echo $(file "$PYTHON_F") | grep -q dynamic; echo $?) -ne 0 ]]; then
    # Fall back to the default python
    DEFAULT_PY=$(realpath "/System/Library/Frameworks/Python.framework/Python")
    >&2 echo "warning: can't find linked python. Falling back to $DEFAULT_PY."
    >&2 echo "this may not work out so well for many reasons"
    PYTHON_F=$DEFAULT_PY
fi

function python_info() {
    echo "Found vim executable $VIM_PATH"
    echo "Found python executable $PYTHON_F"
}

function linked_python() {
    echo $PYTHON_F
}

function python_inc_dir() {
    ROOT=$(dirname $PYTHON_F)
    if [[ -d $ROOT/Headers ]]; then
        echo $ROOT/Headers
        return
    fi

    # Handle builds of python like Apple system pythons
    # i.e.
    # /System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7
    VERSION_INC=$(ls $ROOT/include | head -1)
    if [[ -d $ROOT/include/$VERSION_INC ]]; then
        echo $ROOT/include/$VERSION_INC
        return
    fi
}

