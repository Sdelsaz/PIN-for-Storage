![alt text](https://github.com/Sdelsaz/PIN-for-Storage/blob/main/icon.png?raw=true)


# PIN-For-Storage<br>

This script is designed for Jamf Pro and that allows users to request a temporary exemption from the removable storage restriction enforced by Jamf Protect. The script will generate a random PIN, which the user will need to provide in order to complete the request. The PIN is sent to Jamf Pro.

This script uses Bart Reardon's swiftDialog for user communication:

https://github.com/bartreardon/swiftDialog<br><br>

## Parameters:<br>

The following can be customized:

$4= Amount of time in minutes: You can set the amount of time for which removable storage is allowed in minutes as Parameter 4. If no amount of time is set, the default is 10 minutes.

$5= Maximum number of attempts: You can set the maximum amount of PIN attempts in Parameter 5. If no value is set, the default is 3.

$6= Number of characters/PIN length: You can set the Length of the PIN in Parameter 6. If no value is set, the default is 5 characters.

$7= Organisation name: You can set the Organisation Name in Paremeter 7. If no Value is set, "Unlock Removable Storage" is used for the title.

$8= Path/Link to a custom icon: You can provide the path or link to a custom icon in Paremeter 8. If no Value is set, the default icon is used.<br><br>


## Requirements:<br>

### Jamf Protect:<br>

- A plan that does not restrict removable storage devices

- A plan that restricts removable storage devices

You can find more information on Removable Storage Control Plans is available on the following page:

https://learn.jamf.com/en-US/bundle/jamf-protect-documentation/page/Device_Controls.html<br><br>


### Jamf Pro:<br>

- Jamf Protect integrated with Jamf pro:

https://learn.jamf.com/en-US/bundle/jamf-pro-documentation-current/page/Jamf_Protect_Integration_with_Jamf_Pro.html

- Plans synced with Jamf pro:

https://learn.jamf.com/en-US/bundle/jamf-protect-documentation/page/Jamf_Protect_Plans_in_Jamf_Pro.html

- An Extension attribute to pick up the PIN:

https://github.com/Sdelsaz/PIN-for-Storage/blob/main/Storage-PIN-EA.sh

- An Extension attribute to pick up the Approval Status:

https://github.com/Sdelsaz/PIN-for-Storage/blob/main/Removable-Storage-Approval-EA

- A Smart Computer Group for which the criteria is as follows:

Name:  (example) Removable Storage Allowed

Criteria: Removable Storage Approval (This is the extension attribute provided on this repository)

Operator: Is

Value: OK

- A PPPC (Privacy Preferences Policy Control), to give the atrun command access to the disk. An example is provided.<br><br>

### Scoping<br>

The configuration Configuration Profile corresponding to your main plan restricting Removable Storage should be scoped as per your preference (example : All Managed Clients) with an exclusion for the smart group mentioned above.

The scope for your  Configuration Profile corresponding to your plan Allowing Removable Storage should be scoped to the smart group mentioned above.<br><br>


### Important<br>

A PPPC (Privacy Preferences Policy Control), aka TCC, configuration profile is required now to give the atrun command access to the disk. An example is provided. IMPORTANT: This profile is needed to re-enable the Removable Storage restriction.

Extensions Attributes are used to collect the PIN and approval status in Jamf pro. These Extension Attributes are provided.




