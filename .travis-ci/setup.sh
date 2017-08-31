# Travis-CI custom script

if [ -d $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install ]
then
    echo ""
    echo "==========================================================="
    echo "*** Reusing cache directory $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION..."
    echo "==========================================================="
    echo ""
else
    mkdir -p $HOME/.travis-ci-lua
    mkdir -p $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION
    CURRENT_DIRECTORY=`pwd`
    cd $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION

    case $LUA_BIN in
        "lua")
            echo ""
            echo "==========================================================="
            echo "*** Building lua..."
            curl -R -O http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz
            tar zxf lua-$LUA_VERSION.tar.gz
            cd lua-$LUA_VERSION
            make linux test
            # make install INSTALL_TOP=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install # make local
            make install INSTALL_TOP=`pwd`/install
            cd ..
            echo "*** Lua is built!"
            echo "==========================================================="
            echo "";;

        "luajit")
            echo "============================================================"
            echo "*** Building LuaJIT..."
            wget http://luajit.org/download/LuaJIT-$LUA_VERSION.tar.gz
            mv LuaJIT-$LUA_VERSION.tar.gz luajit-$LUA_VERSION.tar.gz
            tar zxf luajit-$LUA_VERSION.tar.gz
            cd luajit-$LUA_VERSION
            mkdir -p install
            make
            make install PREFIX=`pwd`/install
            cd ..
            echo "*** LuaJIT is built!"
            echo "============================================================"
            echo "";;

        "*")
            echo "================================================[ ERROR ]==="
            echo "*** Invalid lua interpreter called $LUA_BIN!"
            echo "============================================================"
            exit -1;;
    esac

    ###########################################################################

    echo ""
    echo "====================================================================="
    echo "*** Building luarocks..."
    wget https://www.luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz
    tar zxpf luarocks-$LUAROCKS_VERSION.tar.gz
    cd luarocks-$LUAROCKS_VERSION
    ./configure --with-lua=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install \
        --prefix=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install
    make build
    make install
    cd ..
    echo "*** Luarocks is built!"
    echo "====================================================================="
    echo ""

    ###########################################################################

    echo ""
    echo "==========================================================="
    echo "*** Linking directories..."
    ln -s $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install/bin     $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/bin
    ln -s $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install/lib     $HOME/.travis-ci-lia/$LUA_BIN-$LUA_VERSION/lib
    ln -s $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install/include $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/include
    ln -s $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install/share   $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/share
    ln -s $HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install/man     $HOME/.travis-ci-lua/$LUA_BIN-$LuA_VERSION/man
    cd $CURRENT_DIRECTORY
    echo "*** Linked directories!"
    echo "==========================================================="
    echo ""
fi

echo ""
echo "==============================================================="
echo "*** Setting up environment..."
PATH=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/bin:$PATH
export PATH
LD_LIBRARY_PATH=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
MANPATH=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/man:$MANPATH
export MANPATH
echo "*** Configuration is done!"
echo "==============================================================="
echo ""

# END
