# Complete set of test automation

echo ""
echo "===> Checking rockspec..."
luarocks lint "$ROCK_NAME-$ROCK_VERSION.rockspec"
echo "==> Good job! Rockspec is OK."
echo ""

#####################################################################

echo ""
echo "===> Statically analyzing code..."
luacheck --std max+busted src spec
echo "===> Congratulations! You code is beautifully written."
echo ""

#####################################################################

echo ""
echo "===> Running tests..."
busted --verbose spec
echo "===> Awesome! Your code pass, let's generate coverage reports now."
echo ""

#####################################################################

echo ""
echo "===> Running tests with coverage enabled..."
busted --verbose --coverage spec
echo "===> Coverage report was generated without problem. Good work!"
echo ""

#####################################################################

echo ""
echo "===> Installing the rock..."
luarocks make
echo "===> Wow, your package/rock rules! Let's load that."
echo ""

#####################################################################

echo ""
echo "===> Loading the library..."
eval `luarocks path`
lua -l$ROCK_NAME -e "print ('~Library $ROCK_NAME was loaded successfully!~')"
echo "===> Fine. Your installed code is loadable. Let's test again using the installed code."
echo ""

#####################################################################

echo ""
echo "===> Testing the installed code rather than project source code..."
eval `luarocks path`
busted --verbose --lpath=$LUA_PATH --cpath=$LUA_CPATH spec
echo "===> Hey guy, by now everything is fine. Let's drink a beer..."
echo ""

# END