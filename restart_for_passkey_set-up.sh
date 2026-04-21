#!/bin/bash
currentUser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}' )
userHome=$(/usr/bin/dscl . read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk -F ' ' '{print $2}')
/usr/bin/su -l "$currentUser" -c "mkdir -p \"$userHome/Library/PSSO_Staging\""
/usr/local/bin/dialog \
--title "Restart Required for Passkey Setup" \
--titlefont size=24 \
--message "**Passkeys for macOS** \n\nBefore we can generate a passkey, your Mac requires a restart. \n\nPlease save your work then click 'Restart Now'.\n\nThanks for keeping YOUR_ORG_NAME safe!" \
--button1text "Restart Now" \
--width 600 --height 400 \
--messagefont size=16 \
--position center \
--moveable \
--ontop \
--messagealignment centre \
--messageposition centre \
--centericon \
--icon "COPY_THE_URL_OF_AN_ICON_UPLOADED_TO_JAMF" \
# Trigger a restart without the restart/cancel pop-up
/usr/bin/su - "${currentUser}" -c "/usr/bin/osascript -e 'tell app \"System Events\" to restart'"
