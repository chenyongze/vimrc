#!/usr/bin/env bash

#   Copyright 2014 Steve Francia
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

############################  SETUP PARAMETERS
app_name='breaker-vim'
[ -z "$APP_PATH" ] && APP_PATH="$HOME/.breaker-vim"
[ -z "$REPO_URI" ] && REPO_URI='https://coding.net/u/breaker/p/vimrc/git/archive/NIPS-vim'
debug_mode='1'
fork_maintainer='0'
[ -z "$VUNDLE_URI" ] && VUNDLE_URI="https://codeload.github.com/VundleVim/Vundle.vim/zip/master"
[ -z "$TMP_PATH" ] && VIM_TMP_PATH="/tmp/breaker-vim-tmp"

[ -z "$VUNDLE_URI" ] && BUNDLE_URI="https://coding.net/u/breaker/p/vimrc/git/raw/NIPS-vim/bundle.gz"
[ -z "$VUNDLE_URI" ] && SHARE_URI="https://coding.net/u/breaker/p/vimrc/git/raw/NIPS-vim/vim.gz"

############################  BASIC SETUP TOOLS
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    if [ "$ret" -eq '0' ]; then
        msg "\33[32m[✔]\33[0m ${1}${2}"
    fi
}

error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    exit 1
}

debug() {
    if [ "$debug_mode" -eq '1' ] && [ "$ret" -gt '1' ]; then
        msg "An error occurred in function \"${FUNCNAME[$i+1]}\" on line ${BASH_LINENO[$i+1]}, we're sorry for that."
    fi
}

program_exists() {
    local ret='0'
    command -v $1 >/dev/null 2>&1 || { local ret='1'; }

    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
        return 1
    fi

    return 0
}

program_must_exist() {
    program_exists $1

    # throw error on non-zero return value
    if [ "$?" -ne 0 ]; then
        error "You must have '$1' installed to continue."
    fi
}

variable_set() {
    if [ -z "$1" ]; then
        error "You must have your HOME environmental variable set to continue."
    fi
}

lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
    fi
    ret="$?"
    debug
}

############################ SETUP FUNCTIONS
do_backup() {
    for arg in $@
    do
        if
            [ -e "$1"/.breaker-vim-installed ]; then
            continue
        fi

        if [ -e $arg ]; then
            msg "Attempting to back up your original vim configuration."
            today=`date +%Y%m%d_%s`
            for i in $arg; do
                [ -e "$i" ] && [ ! -L "$i" ] && mv -v "$i" "$i.$today";
            done
            ret="$?"
            success "Your original vim configuration has been backed up."
            debug
        fi
    done
}

sync_repo() {
    local repo_path="$1"
    local repo_uri="$2"

    msg "Trying to download $2"
        rm -rf  $VIM_TMP_PATH
        rm -rf  $repo_path
        mkdir -p  $repo_path
        rm -rf  $repo_path
        curl  -k "$repo_uri" "-o"  "tmp.zip"
	unzip  "-o" "tmp.zip" "-d" "$VIM_TMP_PATH" > /dev/null
	for vim_file in `ls $VIM_TMP_PATH`
	do
		tmp_file_basename=`basename $VIM_TMP_PATH/$vim_file`
		vim_file_basename=`basename $repo_path`
		mv  $VIM_TMP_PATH/$vim_file `dirname ${repo_path}`
		mv  `dirname ${repo_path}`/$tmp_file_basename  `dirname ${repo_path}`/$vim_file_basename
		rm -rf $VIM_TMP_PATH/$vim_file 
	done
	rm -rf tmp.zip
        ret="$?"
        success "Successfully download $2."
    debug
}

create_symlinks() {
    local source_path="$1"
    local target_path="$2"

    lnif "$source_path/.vimrc"         "$target_path/.vimrc"
    lnif "$source_path/.vimrc.bundles" "$target_path/.vimrc.bundles"
    lnif "$source_path/.vimrc.before"  "$target_path/.vimrc.before"
    lnif "$source_path/.vim"           "$target_path/.vim"


    if program_exists "nvim"; then
        lnif "$source_path/.vim"       "$target_path/.config/nvim"
        lnif "$source_path/.vimrc"     "$target_path/.config/nvim/init.vim"
    fi

    touch  "$target_path/.vimrc.local"
    touch  "$source_path/.breaker-vim-installed"

    ret="$?"
    success "Setting up vim symlinks."
    debug
}

setup_fork_mode() {
    local source_path="$2"
    local target_path="$3"

    if [ "$1" -eq '1' ]; then
        touch "$target_path/.vimrc.fork"
        touch "$target_path/.vimrc.bundles.fork"
        touch "$target_path/.vimrc.before.fork"

        lnif "$source_path/.vimrc.fork"         "$target_path/.vimrc.fork"
        lnif "$source_path/.vimrc.bundles.fork" "$target_path/.vimrc.bundles.fork"
        lnif "$source_path/.vimrc.before.fork"  "$target_path/.vimrc.before.fork"

        ret="$?"
        success "Created fork maintainer files."
        debug
    fi
}

setup_vundle() {
    local system_shell="$SHELL"
    export SHELL='/bin/sh'

    vim \
        -u "$1" \
        "+set nomore" \
        "+BundleInstall!" \
        "+BundleClean" \
        "+qall"

    export SHELL="$system_shell"

    success "Now updating/installing plugins using Vundle"
    debug
}

############################ MAIN()
variable_set "$HOME"
program_must_exist "vim"
program_must_exist "git"

do_backup       "$HOME/.vim" \
                "$HOME/.vimrc" \
                "$HOME/.gvimrc"

sync_repo       "$APP_PATH" \
                "$REPO_URI" \

create_symlinks "$APP_PATH" \
                "$HOME"

setup_fork_mode "$fork_maintainer" \
                "$APP_PATH" \
                "$HOME"

sync_repo       "$HOME/.vim/" \
                "$VUNDLE_URI" \

ssync_repo       "/usr/share/vim" \
                "$BUNDLE_URI" \

ync_repo       "$HOME/.vim/bundle/vundle" \
                "$SHARE_URI" \



#setup_vundle    "$APP_PATH/.vimrc.bundles.default"

msg             "\nThanks for installing $app_name."
msg             "© `date +%Y` http://vim.0x0c700.cn/"
