#!/bin/sh
# Gets the Mac's Serial #, then using the API, matches the serial # to the Jamf Computer ID, and then adds that computer to the specified Static Group using its Group ID
# In a Jamf Policy which runs a script, $4 - $11 can be assigned. Be sure to assign values $4, $5, $6, $7 within the Policy

####################################################################
###  FOR TESTING ONLY - DO NOT COPY THIS SECTION TO JAMF SERVER  ###
apiuser="API_USERNAME"
apipass="xxxxxxxxxxxAPI_PASSWORD_xxxxxx_IT_SHOULD_BE_REALLY_STRONG_xxxxxxxxxx"

GroupID="nnnn"
# GroupName - NO LONGER NEEDED
####################################################################

jamfProURL="https://your_org.jamfcloud.com"

###  UN-COMMENT ONCE CONFIGURED IN JAMF SERVER.  ###
#apiuser="$4"
#apipass="$5"

#GroupID="$6"
#GroupName="$7"

# Set default exit code
exitCode=0

# Explicitly set initial value for the api_token variable to null:

api_token=""

# Explicitly set initial value for the token_expiration variable to null:

token_expiration=""

GetJamfProAPIToken() {
	
	# This function uses Basic Authentication to get a new bearer token for API authentication.
	
	# Use user account's username and password credentials with Basic Authorization to request a bearer token.
	
	if [[ $(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}') -lt 12 ]]; then
		api_token=$(/usr/bin/curl -X POST --silent -u "${apiuser}:${apipass}" "${jamfProURL}/api/v1/auth/token" | python -c 'import sys, json; print json.load(sys.stdin)["token"]')
	else
		api_token=$(/usr/bin/curl -X POST --silent -u "${apiuser}:${apipass}" "${jamfProURL}/api/v1/auth/token" | plutil -extract token raw -)
	fi
	
}

APITokenValidCheck() {
	
	# Verify that API authentication is using a valid token by running an API command
	# which displays the authorization details associated with the current API user. 
	# The API call will only return the HTTP status code.
	
	api_authentication_check=$(/usr/bin/curl --write-out %{http_code} --silent --output /dev/null "${jamfProURL}/api/v1/auth" --request GET --header "Authorization: Bearer ${api_token}")
	
}

CheckAndRenewAPIToken() {
	
	# Verify that API authentication is using a valid token by running an API command
	# which displays the authorization details associated with the current API user. 
	# The API call will only return the HTTP status code.
	
	APITokenValidCheck
	
	# If the api_authentication_check has a value of 200, that means that the current
	# bearer token is valid and can be used to authenticate an API call.
	
	
	if [[ ${api_authentication_check} == 200 ]]; then
		
		# If the current bearer token is valid, it is used to connect to the keep-alive endpoint. This will
		# trigger the issuing of a new bearer token and the invalidation of the previous one.
		
		if [[ $(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}') -lt 12 ]]; then
			api_token=$(/usr/bin/curl "${jamfProURL}/api/v1/auth/keep-alive" --silent --request POST --header "Authorization: Bearer ${api_token}" | python -c 'import sys, json; print json.load(sys.stdin)["token"]')
		else
			api_token=$(/usr/bin/curl "${jamfProURL}/api/v1/auth/keep-alive" --silent --request POST --header "Authorization: Bearer ${api_token}" | plutil -extract token raw -)
		fi
		
	else
		
		# If the current bearer token is not valid, this will trigger the issuing of a new bearer token
		# using Basic Authentication.
		
		GetJamfProAPIToken
	fi
}

InvalidateToken() {
	
	# Verify that API authentication is using a valid token by running an API command
	# which displays the authorization details associated with the current API user. 
	# The API call will only return the HTTP status code.
	
	APITokenValidCheck
	
	# If the api_authentication_check has a value of 200, that means that the current
	# bearer token is valid and can be used to authenticate an API call.
	
	if [[ ${api_authentication_check} == 200 ]]; then
		
		# If the current bearer token is valid, an API call is sent to invalidate the token.
		
		authToken=$(/usr/bin/curl "${jamfProURL}/api/v1/auth/invalidate-token" --silent  --header "Authorization: Bearer ${api_token}" -X POST)
		
		# Explicitly set value for the api_token variable to null.
		
		api_token=""
		
	fi
}

GetJamfProAPIToken

APITokenValidCheck
echo "API Token Validation Check (200=current bearer token is valid, 401=token is invalid):"
echo "Validation Code is $api_authentication_check"
# echo "$api_token"

CheckAndRenewAPIToken

APITokenValidCheck
echo "API Token Validation Check (200=current bearer token is valid, 401=token is invalid):"
echo "Validation Code is $api_authentication_check"
# echo "$api_token"
############
echo "script BEGIN"

# get serial number
serial=$(ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')
echo $serial
# request auth token
authToken=$( /usr/bin/curl \
--request POST \
--silent \
--url "$jamfProURL/api/v1/auth/token" \
--user "$apiuser:$apipass" )
# parse auth token
token=$( /usr/bin/plutil \
-extract token raw - <<< "$authToken" )
# Don't edit below this line once script is working
ComputerID=$(/usr/bin/curl -sf --header "Authorization: Bearer ${token}" "${jamfProURL}/api/v1/computers-inventory?filter=hardware.serialNumber==$serial" -H "Accept: application/json" | /usr/bin/plutil -extract results.0.id raw - 2>/dev/null)
echo "$ComputerID"
# Add Mac to Static Group
curl -s -H "Authorization: Bearer ${token}" "${jamfProURL}/JSSResource/computergroups/id/$GroupID" -H "Content-Type: text/xml" -X PUT -s -d "<computer_group><computer_additions><computer><id>$ComputerID</id></computer></computer_additions></computer_group>" > /dev/null
echo "script END"
############

# Invalidate Token
InvalidateToken

APITokenValidCheck
echo "API Token Expiration Check (200=current bearer token is still valid, 401= token has been invalidated):"
echo "Validation Code is $api_authentication_check"
