# Build process dependencies

echo ""
echo "===> Installing build dependencies..."
luarocks install luasocket
luarocks install LuaFileSystem
luarocks install busted
luarocks install luacov
luarocks install luacov-coveralls
luarocks install luacheck
echo "===> Packages were installed without problems, let's move on."
echo ""

# END
