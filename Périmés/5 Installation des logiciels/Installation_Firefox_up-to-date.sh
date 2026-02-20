echo "Create a directory to store APT repository keys if it doesn't exist :"
sudo install -d -m 0755 /etc/apt/keyrings
# (existe deja, pas besoin)


echo "Import the Mozilla APT repository signing key :"
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
# If you do not have wget installed, you can install it with: sudo apt-get install wget

echo "The fingerprint should be 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3 :"
gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'

echo "Add the Mozilla APT repository to your sources list :"
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null

echo "Configure APT to prioritize packages from the Mozilla repository :"
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

echo "Update your package list, and install Firefox :"
sudo apt-get update && sudo apt-get install firefox firefox-l10n-fr

echo "Uninstall Debian original version of Firefox :"
sudo apt-get remove firefox-esr firefox-esr-l10n-fr
