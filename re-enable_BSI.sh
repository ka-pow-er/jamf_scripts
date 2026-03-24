#!/bin/sh
# re-enable (Background Security Improvements) BSI
/usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist SplatEnabled true
exit 0
