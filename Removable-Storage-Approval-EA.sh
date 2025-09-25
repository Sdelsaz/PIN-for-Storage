#!/bin/bash
#Extension Attribute to collect the removalbe storage approval status
StorageStatus=$(cat /usr/local/.removablestoragestatus.log)
echo "<result>$StorageStatus</result>"
