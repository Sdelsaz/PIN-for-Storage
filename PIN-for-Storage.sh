#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# This script will allow users to request tp temporarily enable removable storage devices. A random PIN is generated and sent to Jamf pro. 
# An Extension Attribute is used to populate the PIN in the Jamf Pro Inventory. 
# The user prompted for this PIN in order to approve/validate the request.
#
# Parameters:
#
# $4= Amount of time in minutes
# $5= Maximum number of attempts
# $6= Number of characters/PIN length
# $7= Organisation name
# $8= Path to a custom icon
#
# This script uses Bart Reardon's swiftDialog for user dialogs:
# https://github.com/bartreardon/swiftDialog
#
# Created by: Sebastien Del Saz Alvarez: 22 Sep 2025
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Check if Swift Dialog is installed. if not, Install it
logger "Checking if SwiftDialog is installed"
if [[ -e "/usr/local/bin/dialog" ]]
then
logger "SwiftDialog is already installed"
else
logger "SwiftDialog Not installed, downloading and installing"
/usr/bin/curl https://github.com/swiftDialog/swiftDialog/releases/download/v2.5.5/dialog-2.5.5-4802.pkg -L -o /tmp/dialog-2.5.5-4802.pkg 
cd /tmp
/usr/sbin/installer -pkg dialog-2.5.5-4802.pkg -target /
fi

# Variables:
# Check if there is a value passed as $4 for the number of minutes, if not, defaults to 10
if [ -z "$4" ]; then
	TEMPMINUTES=10
else
	
# Check if the value passed as $4 for the number of minutes is a positive numeric number 
# without any extra characters (i.e. 10, not +10 or -10), if not, defaults to 10
if [[ "$4" =~ [^0-9]+ ]] ; then
	TEMPMINUTES=10
else
	TEMPMINUTES="$4"
fi
fi

# Check if there is a value passed as $5 for the maximum number of attempts, if not, defaults to 3
if [ -z "$5" ]; then
	MaxAttempt="3"	
else
	MaxAttempt="$5"	
fi

# Check if there is a value passed as $6 for the PIN Lenth, if not, defaults to 5 characters
if [ -z "$6" ]; then
	PINLength="5"	
else
	PINLength="$6"	
fi

# Check if there is a value passed as $7 for the Organisation Name, if not, set default title
if [ -z "$7" ]; then
	OrgName="Unlock Removable Storage"	
else
	OrgName="$7"	
fi

# Check if there is a value passed as $8 for the icon, if not, set default icon
if [ -z "$8" ]; then
	Icon="https://i.imgur.com/eicKg4B.png"	
else
Icon="$8"	
fi

# Fonts
MessageFont="size=20,name=PTSans-Regular"
TitleFont="weight=bold,size=30,name=PTSans-Regular"

# Prompts
PINPrompt()
{
UserPin=$(dialog --small --title "$OrgName" --titlefont "$TitleFont" --message "Please enter the PIN provided by IT." --messagefont "$MessageFont" --icon "$Icon" --alignment "left" --textfield "PIN","secure" : true --button2 --alignment "left" --height "30%")
if [ $? == 0 ]
then
UserPin=$(echo "$UserPin" | awk -F ': ' '{print $2}')
else
echo "User cancelled"
exit 0
fi
}

IncorrectPINPrompt()
{
	dialog --small --title "$OrgName" --titlefont "$TitleFont" --message "Incorrect PIN provided too many times.\n\n Please contact IT to obtain a PIN." --icon "$Icon" --messagefont "$MessageFont" --button2 --alignment "left" --height "30%" --witdh "40%"
}

CompletePrompt()
{
	dialog -s --title "$OrgName" --titlefont "$TitleF0nt" --message "You can now temporarily connect removable storage devices to your computer  \n  \nYou can close this window without affecting this approval." --icon "$Icon" --messagefont "$MessageFont" --timer $TEMPSECONDS --button1text "Close" --alignment "left" --height "40%" --witdh "40%" --moveable --position "topright"
}

# Generate a random PIN and populate the attribute of hidden file with the value
PIN=$(printf '%0'$PINLength'd\n' $((1 + RANDOM % 1000000)))

# write PIN to hidden file

touch /usr/local/.storagePIN.txt

echo $PIN > /usr/local/.storagePIN.txt

# Update inventory to populate the Extension Attribute
jamf recon

# Delete PIN
> /usr/local/.storagePIN.txt

while  [[ $UserPin != $PIN ]] && [[ $Attempt -lt $MaxAttempt ]]

do
# Request PIN from enduser
Attempt=$(( Attempt +1 ))
logger "$Attempt Attempt out of $MaxAttempt"

PINPrompt

done

if [[ "$UserPin" == "$PIN" ]]; then

logger "Correct PIN Provided, granting Temporary Admin Rights"
		
# Get username of current logged in user
USERNAME=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
			
# Set logfile to approve external storage
touch /usr/local/.removablestoragestatus.log

# Change owner and permissions so admins can't read the file
chown root:wheel /usr/local/.removablestoragestatus.log
chmod 600 /usr/local/.removablestoragestatus.log

# Add Approval value to the file
echo "OK" > /usr/local/.removablestoragestatus.log

# Update inventory to update Extension ATtribute			
jamf recon

# Give it a few seconds to make sure the next step works
sleep 10

# Force Plan Update in Protect
protectctl repair

# Calculates the number of seconds
TEMPSECONDS=$((TEMPMINUTES * 60))

# Checks if atrun is launched or not (to disable admin privileges after the defined amount of time)
if ! launchctl list|grep -q com.apple.atrun; then launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist; fi
			
# Uses at to execute the cleaning script after the defined amount of time
# Be careful, it can take some time to execute and be delayed under heavy load
echo "#!/bin/bash
rm /usr/local/.removablestoragestatus.log
# Update inventory to update Extension Attribute			
jamf recon
# Give it a few seconds to make sure the next step works
sleep 10
# Force Plan Update in Protect
protectctl repair
exit 0
" | at -t "$(date -v+"$TEMPSECONDS"S "+%Y%m%d%H%M.%S")"

# Display a window showing how much time is left as an admin using Jamf Helper	
CompletePrompt

# Writes in logs when it's done
logger "Removable Storage enabled "
exit 0
fi

if [[ "$UserPin" != "$PIN" ]]; then

logger "Incorrect PIN Provided $MaxAttempt times"
IncorrectPINPrompt
	
fi
exit 0
