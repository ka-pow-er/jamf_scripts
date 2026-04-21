#!/bin/bash
currentUser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
userHome=$(/usr/bin/dscl . read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk -F ' ' '{print $2}')
/usr/bin/su -l "$currentUser" -c "rm -r \"$userHome/Library/PSSO_Staging\""
# add psso_migrated key to host-info.plist
PLIST=/var/db/.com.org_name.host-info.plist
KEY=psso_migrated
CHECK=$(defaults read $PLIST $KEY)
if [ "$CHECK" == "YES" ]; then
	echo "psso_migrated key already exists. exiting"
	exit 0
else
/usr/libexec/PlistBuddy -c "Add :psso_migrated string YES" $PLIST
	echo "psso_migrated key added"
fi
exit 0
