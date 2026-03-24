#!/bin/bash
# see https://docs.sophos.com/central/customer/help/en-us/PeopleAndDevices/ProtectDevices/EndpointProtection/MacDeployment/index.html#create-sophos-installation-script for installation details
### This script is not supplied by Sophos. Use at your own risk.
### It adds feedback to your Jamf Policy, reporting success if 1) the scanextension is running and 
### 2) the Sophos Endpoint.app is installed, and times out after 15 minutes.
START="$(date +%s)"
SOPHOS_DIR="/Users/Shared/Sophos_Install"
mkdir $SOPHOS_DIR
cd $SOPHOS_DIR
# Installing Sophos Endpoint
curl -L -O "https://dzr-api-amzn-xxxxxxxxx-SEE-INSTRUCTIONS-URL-ABOVE-xxxxxxxx/SophosInstall.zip"
unzip SophosInstall.zip
chmod a+x $SOPHOS_DIR/Sophos\ Installer.app/Contents/MacOS/Sophos\ Installer
chmod a+x $SOPHOS_DIR/Sophos\ Installer.app/Contents/MacOS/tools/com.sophos.bootstrap.helper
$SOPHOS_DIR/Sophos\ Installer.app/Contents/MacOS/Sophos\ Installer --products # [add products as needed] antivirus intercept mdr deviceEncryption --quiet
while ! /usr/bin/pgrep "com.sophos.endpoint.scanextension" >/dev/null
do
	echo "Sophos scanextension is not running"
	sleep 10
done
rm -rf $SOPHOS_DIR
DURATION=$[ $(date +%s) - ${START} ]
echo "Elapsed time = ${DURATION} seconds."
# Check to see if Sophos Endpoint is installed
if [[ -d "/Applications/Sophos/Sophos Endpoint.app" ]]; [[ "$SECONDS" -lt 900 ]]
then
	echo "Sophos Endpoint App is installed"
    echo "running recon"
    /usr/local/jamf/bin/jamf recon
	exit 0
else
	echo "Sophos Endpoint App did not install or took longer than 15 minutes"
    echo "running recon"
    /usr/local/jamf/bin/jamf recon
#	exit 1
fi
