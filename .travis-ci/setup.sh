# Travis-CI custom script

if [[ ( -d $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION/bin ) && ( $REBUILD != "1" ) ]]
then
    echo ""
    echo "==========================================================="
    echo "*** Reusing cache directory $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION..."
    echo "==========================================================="
    echo ""

    ###########################################################################

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
else
    echo "===> Cleanup of cache directory..."
    rm -Rf $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION || :

    mkdir -p $HOME/.travis-ci-lua
    mkdir -p $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION
    CURRENT_DIRECTORY=`pwd`
    cd $HOME/.travis-ci-lua/lua$LUA_SUFFIX-$LUA_VERSION

    export LUA_RELEASE=`echo $LUA_VERSION | sed 's/^\(...\).*/\1/'`

    case $LUA_SUFFIX in
        "")
            echo ""
            echo "==========================================================="
            echo "*** Building lua..."
            echo "===> Downloading from lua.org..."
            curl -R -O http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz

            echo "===> Unpacking zipped file..."
            tar zxf lua-$LUA_VERSION.tar.gz
            cd lua-$LUA_VERSION

            echo "===> Building lua..."
            make linux test
            # make install INSTALL_TOP=$HOME/.travis-ci-lua/$LUA_BIN-$LUA_VERSION/install # make local

            echo "===> Installing lua..."
            make install INSTALL_TOP=`pwd`/install
            export LUA_INCLUDE_DIR=`pwd`/install/include
            cd ..
            echo "*** Lua is built!"
            echo "==========================================================="
            echo "";;

        "jit")
            echo "============================================================"
            echo "*** Building LuaJIT..."
            echo "===> Downloading luajit..."
            wget --no-check-certificate http://luajit.org/download/LuaJIT-$LUA_VERSION.tar.gz

            echo "===> Unpacking zipped file..."
            tar zxf LuaJIT-$LUA_VERSION.tar.gz
            mv LuaJIT-$LUA_VERSION luajit-$LUA_VERSION
            cd luajit-$LUA_VERSION
            mkdir -p install

            echo "===> Building luajit..."
            make

            echo "===> Installing luajit..."
            make install PREFIX=`pwd`/install
            ln -sfv `pwd`/install/bin/luajit-$LUA_VERSION `pwd`/install/bin/luajit
            chmod +x `pwd`/install/bin/luajit
            ### THIS IS POSSIBLY THE SOURCE OF ERROR FROM THE LUAROCKS BUILD FAILURE
            # ln -sfv install/bin/luajit-$LUA_VERSION install/bin/lua

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

    export CACHE_DIR=`pwd`
    export BUILD_DIRECTORY="$CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION"
    export ROOT_DIRECTORY="$BUILD_DIRECTORY/install"
    echo ""
    echo "==========================================================="
    echo "*** Linking directories..."
    ln -sfv -t $CACHE_DIR $ROOT_DIRECTORY/bin     \
                          $ROOT_DIRECTORY/lib     \
                          $ROOT_DIRECTORY/include \
                          $ROOT_DIRECTORY/share   \
                          $ROOT_DIRECTORY/man
    echo "*** Linked directories!"
    echo "==========================================================="
    echo ""

    ###########################################################################

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

    ###########################################################################

    echo ""
    echo "====================================================================="
    echo "*** Building luarocks..."
    echo "===> Downloading luarocks..."
    wget --no-check-certificate https://www.luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz

    echo "===> Unpacking zipped file..."
    tar zxpf luarocks-$LUAROCKS_VERSION.tar.gz
    cd luarocks-$LUAROCKS_VERSION

    case $LUA_SUFFIX in
        "")
            echo "===> Configuring luarocks for Lua..."
            ./configure                                                   \
                --with-lua=$CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install \
                --prefix=$CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install   \
                --with-lua-include=$LUA_INCLUDE_DIR                       \
                --force-config;;

        "jit")
            echo "===> Configuring luarocks for LuaJIT..."

            ./configure                                                          \
                --with-lua=$CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install        \
                --prefix=$CACHE_DIR/lua$LUA_SUFFIX-$LUA_VERSION/install          \
                --with-lua-include="$ROOT_DIRECTORY/include/luajit-$LUA_RELEASE" \
                --lua-suffix=jit                                                 \
                --force-config;;
    esac

    echo "===> Building luarocks..."
    make build

    echo "===> Installing luarocks..."
    make install
    cd ..
    echo "*** Luarocks is built!"
    echo "====================================================================="
    echo ""

    cd $CURRENT_DIRECTORY
fi

# END
