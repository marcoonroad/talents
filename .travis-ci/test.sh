# Complete set of test automation

echo ""
echo "===> Checking rockspec..."
luarocks lint "$ROCK_NAME-$ROCK_VERSION.rockspec" || exit 1
echo "===> Good job! Rockspec is OK."
echo ""

#####################################################################

echo ""
echo "===> Statically analyzing code..."
luacheck --std max+busted src spec || exit 1
echo "===> Congratulations! You code is beautifully written."
echo ""

#####################################################################

echo ""
echo "===> Running tests..."
busted --verbose spec || exit 1

if [[ $NOCOVERAGE != "1" ]]
then
    echo "===> Awesome! Your code pass, let's generate coverage reports now."
    echo ""

    #####################################################################

    echo ""
    echo "===> Running tests with coverage enabled..."
    busted --verbose --coverage spec || exit 1
    echo "===> Coverage report was generated without problem. Good work!"
    echo ""
fi

#####################################################################

echo ""
echo "===> Installing the rock..."
luarocks make || exit 1
echo "===> Wow, your package/rock rules! Let's load that."
echo ""

#####################################################################

echo ""
echo "===> Loading the library..."
eval `luarocks path`
lua -l$ROCK_NAME -e "print ('~Library $ROCK_NAME was loaded successfully!~')" || exit 1
echo "===> Fine. Your installed code is loadable. Let's test again using the installed code."
echo ""

#####################################################################

echo ""
echo "===> Testing the installed code rather than project source code..."
eval `luarocks path`
busted --verbose --lpath=$LUA_PATH --cpath=$LUA_CPATH spec || exit 1
echo "===> Hey guy, by now everything is fine. Let's drink a beer..."
echo ""

# END
