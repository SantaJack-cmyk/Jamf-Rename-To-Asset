#!/bin/bash

# The "Read" Account can only Read date, it does not Create, Modify, nor Delete data in Jamf Pro.
jamfProURL=https://jamfcloudinstance.com
username=User
password=PASS
MACADDRESS=$(networksetup -getmacaddress en0 | awk '{print $3}')
echo "$MACADDRESS"

# request auth token
authToken=$( /usr/bin/curl \
--request POST \
--silent \
--url "$jamfProURL/api/v1/auth/token" \
--user "$username:$password" )

#echo "$authToken"
# parse auth token\
token=$( /usr/bin/plutil \
-extract token raw - <<< "$authToken" )

tokenExpiration=$( /usr/bin/plutil \
-extract expires raw - <<< "$authToken" )

localTokenExpirationEpoch=$( TZ=GMT /bin/date -j \
-f "%Y-%m-%dT%T" "$tokenExpiration" \
+"%s" 2> /dev/null )

#echo Token: "$token"
#echo Expiration: "$tokenExpiration"
#echo Expiration epoch: "$localTokenExpirationEpoch"

# Pulls the Asset Tag data from Jamf Pro.
ASSET_TAG_INFO=$(curl -k $jamfProURL/JSSResource/computers/macaddress/$MACADDRESS --header "Authorization: Bearer $token" | xmllint --xpath '/computer/general/asset_tag/text()' -)

# Changes the Computer name, using the data from the Asset Tag field in Jamf Pro.
sudo scutil --set HostName "$ASSET_TAG_INFO"
sudo scutil --set LocalHostName "$ASSET_TAG_INFO"
sudo scutil --set ComputerName "$ASSET_TAG_INFO"

echo sudo scutil --get HostName "$ASSET_TAG_INFO"
echo sudo scutil --get LocalHostName "$ASSET_TAG_INFO"
echo sudo scutil --get ComputerName "$ASSET_TAG_INFO"

sudo jamf recon
