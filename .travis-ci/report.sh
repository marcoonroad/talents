# Coverage report step

if [[ $NOCOVERAGE != "1"  ]]
then
    echo ""
    echo "===> Checking existing reports..."
    luacov-coveralls -i src --dryrun || exit 1
    echo "===> Well, everything is fine. Let's send them."
    echo ""

    #####################################################################

    echo ""
    echo "===> Sending reports for coverage server..."
    luacov-coveralls -i src || exit 1
    echo "===> Yay! Keep going that good practice."
    echo ""
fi

# END
