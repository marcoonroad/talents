# Coverage report step

echo ""
echo "===> Checking existing reports..."
luacov-coveralls -i src --dryrun
echo "===> Well, everything is fine. Let's send them."
echo ""

#####################################################################

echo ""
echo "===> Sending reports for coverage server..."
luacov-coveralls -i src
echo "===> Yay! Keep going that good practice."
echo ""

# END
