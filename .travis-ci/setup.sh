# Travis-CI custom script

if [[ ( -d $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION/bin ) && ( $REBUILD != "1" ) ]]
then
    echo ""
    echo "==========================================================="
    echo "*** Reusing cache directory $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION..."
    echo "==========================================================="
    echo ""
else
    mkdir -p $HOME/.travis-ci-lua
    mkdir -p $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION
    CURRENT_DIRECTORY=`pwd`
    cd $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION

    case $LUA_SUFFIX in
        "")
            echo ""
            echo "==========================================================="
            echo "*** Building lua..."
            curl -R -O http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz
            tar zxf lua-$LUA_VERSION.tar.gz
            cd lua-$LUA_VERSION
            make linux test
            # make install INSTALL_TOP=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install # make local
            make install INSTALL_TOP=`pwd`/install
            export LUA_INCLUDE_DIR=`pwd`/install/include
            cd ..
            echo "*** Lua is built!"
            echo "==========================================================="
            echo "";;

        "jit")
            echo "============================================================"
            echo "*** Building LuaJIT..."
            wget http://luajit.org/download/LuaJIT-$LUA_VERSION.tar.gz
            tar zxf LuaJIT-$LUA_VERSION.tar.gz
            mv LuaJIT-$LUA_VERSION luajit-$LUA_VERSION
            cd luajit-$LUA_VERSION
            mkdir -p install
            make
            make install PREFIX=`pwd`/install
            ln -sfv install/bin/luajit-$LUA_VERSION install/bin/luajit
            ln -sfv install/bin/luajit-$LUA_VERSION install/bin/lua
            export LUA_INCLUDE_DIR=`pwd`/install/include/luajit-2.0
            cd ..
            # ln -sfv -T `pwd`/LuaJIT-$LUA_VERSION `pwd`/luajit-$LUA_VERSION
            echo "*** LuaJIT is built!"
            echo "============================================================"
            echo "";;

        "*")
            echo "================================================[ ERROR ]==="
            echo "*** Invalid lua interpreter suffix $LUA_SUFFIX!"
            echo "============================================================"
            exit -1;;
    esac

    ###########################################################################

    echo ""
    echo "====================================================================="
    echo "*** Building luarocks..."
    CACHE_DIR=`pwd`
    wget https://www.luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz
    tar zxpf luarocks-$LUAROCKS_VERSION.tar.gz
    cd luarocks-$LUAROCKS_VERSION
    ./configure \
      --with-lua-bin=$CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install/bin \
      --prefix=$CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install           \
      --lua-suffix="$LUA_SUFFIX"                                        \
      --with-lua-include=$LUA_INCLUDE_DIR \
      --force-config
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
    ln -sfv -t $CACHE_DIR $CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install/bin     \
                          $CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install/lib     \
                          $CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install/include \
                          $CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install/share   \
                          $CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install/man
    cd $CURRENT_DIRECTORY
    echo "*** Linked directories!"
    echo "==========================================================="
    echo ""
fi

echo ""
echo "==============================================================="
echo "*** Setting up environment..."
PATH=$HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION/bin:$PATH
export PATH
LD_LIBRARY_PATH=$HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
MANPATH=$HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION/man:$MANPATH
export MANPATH
echo "*** Configuration is done!"
echo "==============================================================="
echo ""

# END
