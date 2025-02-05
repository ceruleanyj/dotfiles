#!/bin/bash

# A collection of bash scripts for installing some libraries/packages in
# user namespaces (e.g. ~/.local/), without having root privileges.

PREFIX="$HOME/.local/"

COLOR_NONE="\033[0m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_WHITE="\033[1;37m"

install_ncurses() {
    # installs ncurses (shared libraries and headers) into local namespaces.
    set -e

    TMP_NCURSES_DIR="/tmp/$USER/ncurses/"; mkdir -p $TMP_NCURSES_DIR
    NCURSES_DOWNLOAD_URL="https://invisible-mirror.net/archives/ncurses/ncurses-5.9.tar.gz";

    wget -nc -O $TMP_NCURSES_DIR/ncurses-5.9.tar.gz $NCURSES_DOWNLOAD_URL
    tar -xvzf $TMP_NCURSES_DIR/ncurses-5.9.tar.gz -C $TMP_NCURSES_DIR --strip-components 1
    cd $TMP_NCURSES_DIR

    # compile as shared library, at ~/.local/lib/libncurses.so (as well as static lib)
    export CPPFLAGS="-P"
    ./configure --prefix="$PREFIX" --with-shared

    make clean && make -j4 && make install
}

install_zsh() {
    set -e

    ZSH_VER="5.4.1"
    TMP_ZSH_DIR="/tmp/$USER/zsh/"; mkdir -p $TMP_ZSH_DIR

    wget -nc -O $TMP_ZSH_DIR/zsh.tar.gz "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VER}/zsh-${ZSH_VER}.tar.gz/download"
    tar -xvzf $TMP_ZSH_DIR/zsh.tar.gz -C $TMP_ZSH_DIR --strip-components 1
    cd $TMP_ZSH_DIR

    if [[ -d "$PREFIX/include/ncurses" ]]; then
        export CFLAGS="-I$PREFIX/include -I$PREFIX/include/ncurses"
        export LDFLAGS="-L$PREFIX/lib/"
    fi

    ./configure --prefix="$PREFIX"
    make clean && make -j8 && make install

    ~/.local/bin/zsh --version
}

install_node() {
    # Install node.js LTS at ~/.local
    set -e
    curl -sL install-node.now.sh | bash -s -- --prefix=$HOME/.local --verbose

    echo -e "\n$(which node) : $(node --version)"
    node --version
}

install_tmux() {
    # install tmux (and its dependencies such as libevent) locally
    set -e
    TMUX_VER="2.4"

    TMP_TMUX_DIR="/tmp/$USER/tmux/"; mkdir -p $TMP_TMUX_DIR

    # libevent
    if [[ -f "/usr/include/libevent.a" ]]; then
        echo "Using system libevent"
    elif [[ ! -f "$PREFIX/lib/libevent.a" ]]; then
        wget -nc -O $TMP_TMUX_DIR/libevent.tar.gz "https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz" || true;
        tar -xvzf $TMP_TMUX_DIR/libevent.tar.gz -C $TMP_TMUX_DIR
        cd ${TMP_TMUX_DIR}/libevent-*
        ./configure --prefix="$PREFIX" --disable-shared
        make clean && make -j4 && make install
    fi

    # TODO: assuming that ncurses is available?

    # tmux
    TMUX_TGZ_FILE="tmux-${TMUX_VER}.tar.gz"
    TMUX_DOWNLOAD_URL="https://github.com/tmux/tmux/releases/download/${TMUX_VER}/${TMUX_TGZ_FILE}"

    wget -nc ${TMUX_DOWNLOAD_URL} -P ${TMP_TMUX_DIR}
    cd ${TMP_TMUX_DIR} && tar -xvzf ${TMUX_TGZ_FILE}
    cd "tmux-${TMUX_VER}"

    ./configure --prefix="$PREFIX" \
        CFLAGS="-I$PREFIX/include/ -I$PREFIX/include/ncurses/" \
        LDFLAGS="-L$PREFIX/lib/" \
        PKG_CONFIG="/bin/false"

    make clean && make -j4 && make install
    ~/.local/bin/tmux -V
}


install_bazel() {
    set -e

    BAZEL_VER="0.20.0"
    BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-installer-linux-x86_64.sh"

    TMP_BAZEL_DIR="/tmp/$USER/bazel/"
    mkdir -p $TMP_BAZEL_DIR
    wget -O $TMP_BAZEL_DIR/bazel-installer.sh $BAZEL_URL

    # zsh completion
    mkdir -p $HOME/.local/share/zsh/site-functions
    wget -O $HOME/.local/share/zsh/site-functions/_bazel https://raw.githubusercontent.com/bazelbuild/bazel/master/scripts/zsh_completion/_bazel

    # install bazel
    bash $TMP_BAZEL_DIR/bazel-installer.sh \
        --bin=$HOME/.local/bin \
        --base=$HOME/.bazel
}


install_anaconda3() {
    # installs Anaconda-python3. (Deprecated: Use miniconda)
    # https://www.anaconda.com/download/#linux
    set -e
    ANACONDA_VERSION="5.2.0"

    if [ "$1" != "--force" ]; then
        echo "Please use miniconda instead. Use --force option to proceed." && exit 1;
    fi

    # https://www.anaconda.com/download/
    TMP_DIR="/tmp/$USER/anaconda/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
    wget -nc "https://repo.continuum.io/archive/Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh"

    # will install at $HOME/.anaconda3 (see zsh config for PATH)
    ANACONDA_PREFIX="$HOME/.anaconda3/"
    bash "Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh" -b -p ${ANACONDA_PREFIX}

    $ANACONDA_PREFIX/bin/python --version
}

install_miniconda() {
    # installs Miniconda3
    # https://conda.io/miniconda.html
    set -e
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

    TMP_DIR="/tmp/$USER/miniconda/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
    wget -nc $MINICONDA_URL

    MINICONDA_PREFIX="$HOME/.miniconda3/"
    bash "Miniconda3-latest-Linux-x86_64.sh" -b -p ${MINICONDA_PREFIX}

    $MINICONDA_PREFIX/bin/python --version

    echo "${COLOR_YELLOW}Will downgrade python from 3.7 to 3.6.${COLOR_NONE}"
    $MINICONDA_PREFIX/bin/conda install -y 'python==3.6.*'

    $MINICONDA_PREFIX/bin/python --version
    echo "${COLOR_GREEN}All set!${COLOR_NONE}"
}


install_vim() {
    # install latest vim
    set -e

    TMP_VIM_DIR="/tmp/$USER/vim/"; mkdir -p $TMP_VIM_DIR
    VIM_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/vim/vim/tags 2>/dev/null | \
        python -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
    )
    test -n $VIM_LATEST_VERSION
    VIM_LATEST_VERSION=${VIM_LATEST_VERSION/v/}    # (e.g) 8.0.1234

    VIM_DOWNLOAD_URL="https://github.com/vim/vim/archive/v${VIM_LATEST_VERSION}.tar.gz"

    wget -nc ${VIM_DOWNLOAD_URL} -P ${TMP_VIM_DIR} || true;
    cd ${TMP_VIM_DIR} && tar -xvzf v${VIM_LATEST_VERSION}.tar.gz
    cd "vim-${VIM_LATEST_VERSION}/src"

    ./configure --prefix="$PREFIX" \
        --with-features=huge \
        --enable-pythoninterp

    make clean && make -j8 && make install
    ~/.local/bin/vim --version | head -n2

    # make sure that all necessary features are shipped
    if ! (vim --version | grep -q '+python'); then
        echo "vim: python is not enabled"
        exit 1;
    fi
}

install_neovim() {
    # install neovim nightly
    set -e

    TMP_NVIM_DIR="/tmp/$USER/neovim"; mkdir -p $TMP_NVIM_DIR
    NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz"

    cd $TMP_NVIM_DIR
    wget --backups=1 $NVIM_DOWNLOAD_URL      # always overwrite, having only one backup
    tar -xvzf "nvim-linux64.tar.gz"

    # copy and merge into ~/.local/bin
    echo "[*] Copying to $PREFIX ..."
    cp -RT "nvim-linux64/" "$PREFIX" >/dev/null \
        || (echo "Copy failed, please kill all nvim instances"; exit 1)

    $PREFIX/bin/nvim --version
}


install_exa() {
    # https://github.com/ogham/exa/releases
    EXA_VERSION="0.9.0"
    EXA_BINARY_SHA1SUM="744e3fdff6581bf84b95cecb00258df8c993dc74"  # exa-linux-x86_64 v0.9.0
    EXA_DOWNLOAD_URL="https://github.com/ogham/exa/releases/download/v$EXA_VERSION/exa-linux-x86_64-$EXA_VERSION.zip"
    TMP_EXA_DIR="/tmp/$USER/exa/"

    wget -nc ${EXA_DOWNLOAD_URL} -P ${TMP_EXA_DIR} || exit 1;
    cd ${TMP_EXA_DIR} && unzip -o "exa-linux-x86_64-$EXA_VERSION.zip" || exit 1;
    if [[ "$EXA_BINARY_SHA1SUM" != "$(sha1sum exa-linux-x86_64 | cut -d' ' -f1)" ]]; then
        echo -e "${COLOR_RED}SHA1 checksum mismatch, aborting!${COLOR_NONE}"
        exit 1;
    fi
    cp "exa-linux-x86_64" "$PREFIX/bin/exa" || exit 1;
    echo "$(which exa) : $(exa --version)"
}


install_fd() {
    # install fd
    set -e

    TMP_FD_DIR="/tmp/$USER/fd"; mkdir -p $TMP_FD_DIR
    FD_DOWNLOAD_URL="https://github.com/sharkdp/fd/releases/download/v6.0.0/fd-v6.0.0-x86_64-unknown-linux-musl.tar.gz"
    echo $FD_DOWNLOAD_URL

    cd $TMP_FD_DIR
    curl -L $FD_DOWNLOAD_URL | tar -xvzf - --strip-components 1
    cp "./fd" $PREFIX/bin
    cp "./autocomplete/_fd" $PREFIX/share/zsh/site-functions

    $PREFIX/bin/fd --version
    echo "$(which fd) : $(fd --version)"
}

install_ripgrep() {
    # install ripgrep
    set -e
    RIPGREP_VERSION="0.10.0"

    TMP_RIPGREP_DIR="/tmp/$USER/ripgrep"; mkdir -p $TMP_RIPGREP_DIR
    RIPGREP_DOWNLOAD_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    echo $RIPGREP_DOWNLOAD_URL

    cd $TMP_RIPGREP_DIR
    curl -L $RIPGREP_DOWNLOAD_URL | tar -xvzf - --strip-components 1
    cp "./rg" $PREFIX/bin

    mkdir -p $HOME/.local/share/zsh/site-functions
    cp "./complete/_rg" $PREFIX/share/zsh/site-functions

    $PREFIX/bin/rg --version
    echo "$(which rg) : $(rg --version)"
}

install_xsv() {
    XSV_VERSION="0.13.0"

    set -e; set -x
    mkdir -p $PREFIX/bin && cd $PREFIX/bin
    curl -L "https://github.com/BurntSushi/xsv/releases/download/${XSV_VERSION}/xsv-${XSV_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar zxf -
    $PREFIX/bin/xsv
}

install_bat() {
    BAT_VERSION="0.8.0"

    set -e; set -x
    mkdir -p $PREFIX/bin && cd $PREFIX/bin
    curl -L "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
        | tar zxf - --strip-components 1 --wildcards --no-anchored 'bat*'     # bat, bat.1

    $PREFIX/bin/bat --version
}

install_go() {
    # install go lang into ~/.go
    # https://golang.org/dl/
    set -e
    if [[ -d $HOME/.go ]]; then
        echo -e "${COLOR_RED}Error: $HOME/.go already exists.${COLOR_NONE}"
        exit 1;
    fi

    GO_DOWNLOAD_URL="https://dl.google.com/go/go1.9.3.linux-amd64.tar.gz"
    TMP_GO_DIR="/tmp/$USER/go/"

    wget -nc ${GO_DOWNLOAD_URL} -P ${TMP_GO_DIR} || exit 1;
    cd ${TMP_GO_DIR} && tar -xvzf "go1.9.3.linux-amd64.tar.gz" || exit 1;
    mv go $HOME/.go

    echo ""
    echo -e "${COLOR_GREEN}Installed at $HOME/.go${COLOR_NONE}"
    $HOME/.go/bin/go version
}


# entrypoint script
if [ `uname` != "Linux" ]; then
    echo "Run on Linux (not on Mac OS X)"; exit 1
fi
if [[ -n "$1" && "$1" != "--help" ]] && declare -f "$1"; then
    $@
else
    echo "Usage: $0 [command], where command is one of the following:"
    declare -F | cut -d" " -f3 | grep -v '^_'
    exit 1;
fi
