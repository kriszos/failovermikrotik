#
# This script converts any new DHCP leases to static automatically and transfers them to the failover router
#
# Base for this script was taken from dynamic to static lease script by Jotne <jo.overland at gmail.com>
# https://forum.mikrotik.com/viewtopic.php?t=147251
#
# Author Lukáš Krejza <gryffus@hkfree.org>
#
#
###########################################

#
# Config:
#

# IP address of the slave router
:local failoverIP 127.0.0.1

# Login and password to the failover router

# Username (ftp) on slave router
:local failoverUsername admin

# Password (ftp) on slave router
:local failoverPassword admin

# Local and remote lease file names
#
# Local will have rsc.txt extension
# Remote will have .auto.rsc extension
#
# Both filenames will be prepended with MAC address of the client
#
# Sent files are removed, received files are kept, so cleaning
# needs to be done on the slave.
#

# Fixed part of temp file names on master router (local)
:local localLeaseFilename lease

# Fixed part of temp file names on slave router (remote)
:local remoteLeaseFilename lease

###########################################

# Test if this is a Bound session and the lease is a dynamic one. Do not change older reservation
:if (($leaseBound=1) && ([/ip dhcp-server lease find where dynamic mac-address=$leaseActMAC]!="")) do {

# Get the lease number
	:local Lease [/ip dhcp-server lease find mac-address=$leaseActMAC]

# Get date and time
	:local date [/system clock get date]
	:local time [/system clock get time]

# Make the lease static
	/ip dhcp-server lease make-static $Lease

# Get host name
	:local Name [/ip dhcp-server lease get $Lease host-name ]

# Add date and time as a comment to show when it was seen first time
	/ip dhcp-server lease comment comment="$date $time $Name" $Lease

# Generate file name
	:local localLeaseFile ($leaseActMAC."-".$localLeaseFilename.".rsc.txt")
	:local remoteLeaseFile ($leaseActMAC."-".$remoteLeaseFilename.".auto.rsc")

# Create new lease import file
	if ([:len [/file find name=$localLeaseFile]]>0) do={/file remove $localLeaseFile}
	/file print file=$localLeaseFile

# Wait for the file to be available on FS
	:while ([:len [/file find name=$localLeaseFile]]<1) do={ :delay 1 };

# Write import string for the lease to the file
	/file set $localLeaseFile contents="/ip dhcp-server lease add address=$leaseActIP mac-address=$leaseActMAC comment=\"From Primary: $date $time $Name\" server=$leaseServerName"

# Transfer and import lease file to slave (automatic import works only via FTP and file name *.auto.rsc)
	/tool fetch address=$failoverIP src-path=$localLeaseFile dst-path=$remoteLeaseFile user=$failoverUsername password=$failoverPassword mode=ftp upload=yes

# Cleanup after ourselves
	if ([:len [/file find name=$localLeaseFile]]>0) do={/file remove $localLeaseFile}

# Send a message to the log
	:log info message="script=dhcp_lease server=$leaseServerName IP=$leaseActIP MAC=$leaseActMAC name=$Name"
}
