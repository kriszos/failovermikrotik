# ------------------- header -------------------
# Script by Tomas Kirnak, version 1.0.7
# If you use this script, or edit and
# re-use it, please keep the header intact.
#
# For more information and details about
# this script please visit the wiki page at
# http://wiki.mikrotik.com/wiki/Failover_Scripting
# ------------------- header -------------------
# changes by Kriszos, version 1.2.2
# changes:
# added support for multpile hosts to check connectivity
# added mail notification,



# ------------- start editing here -------------

# Edit the variables below to suit your needs
# Fill the ping check host,manualy add static routes via main or backup gateway
# In example below are anycast root DNS servers
# MAINISP
:local PingTarget1 192.58.128.30
:local PingTarget2 192.203.230.10
:local PingTarget3 199.7.91.13
# BACKUPISP
:local PingTarget4 192.5.5.241
:local PingTarget5 193.0.14.129
:local PingTarget6 199.7.83.42



# Please fill how many ping failures are allowed before fail-over happends
:local FailTresholdISP1 30
:local FailTresholdISP2 30

# Define the distance increase of a route when it fails
:local DistanceIncrease 200

# Define name of main and backup ISP for mail and logging
:local MainISPname SWIATLOWOD
:local BackupISPname NEOSTRADA

# Define name of TO & CC field for mail both MUST be SET
:local TOmail1 admin1@example.com
:local TOmail2 admin2@example.com




# Editing the script after this point may break it
# -------------- stop editing here --------------

# Define System identity to variable
:local ThisBox [/system identity get name]

# Declare the global variables
:global PingFailCountISP1
:global PingFailCountISP2

# This inicializes the PingFailCount variables, in case this is the 1st time the script has ran
:if ([:typeof $PingFailCountISP1] = "nothing") do={:set PingFailCountISP1 0}
:if ([:typeof $PingFailCountISP2] = "nothing") do={:set PingFailCountISP2 0}

# This variable will be used to keep results of individual ping attempts
:local PingResult1
:local PingResult2
:local PingResult3
:local PingResult4
:local PingResult5
:local PingResult6

# Check hosts
:set PingResult1 [ping $PingTarget1 count=1]
:put $PingResult1
:set PingResult2 [ping $PingTarget2 count=1]
:put $PingResult2
:set PingResult3 [ping $PingTarget3 count=1]
:put $PingResult3
:set PingResult4 [ping $PingTarget4 count=1]
:put $PingResult4
:set PingResult5 [ping $PingTarget5 count=1]
:put $PingResult5
:set PingResult6 [ping $PingTarget6 count=1]
:put $PingResult6

# sumarize PingResults
:local TotalResult1 0
:set TotalResult1 ($PingResult1 + $PingResult2 + $PingResult3)
:local TotalResult2 0
:set TotalResult2 ($PingResult4 + $PingResult5 + $PingResult6)

# MAIN ISP
# IF FAIL
:if ($TotalResult1 < 1) do={
	:if ($PingFailCountISP1 < ($FailTresholdISP1+2)) do={
		:set PingFailCountISP1 ($PingFailCountISP1 + 1)
		:log warning "$MainISPname lost $PingFailCountISP1 pings to WAN - checking."

		:if ($PingFailCountISP1 = $FailTresholdISP1) do={
			:log warning "$MainISPname has a problem en route to WAN - increasing distance of routes."
			:foreach i in=[/ip route find comment=MAIN && static] do={
				/ip route set $i distance=([/ip route get $i distance] + $DistanceIncrease)
				/ip firewall connection remove [/ip firewall connection find protocol=udp]
				/ip firewall connection remove [/ip firewall connection find protocol=icmp]
        /ip firewall connection remove [/ip firewall connection find where connection-type=sip]
				:log warning "$MainISPname Route distance increase finished."
				:delay 1
				/tool e-mail send to=$TOmail1 cc=$TOmail2 subject="PROBLEM_$ThisBox_$MainISPname"
			}
		}
	}
}

# IF NOT FAIL
:if ($TotalResult1 > 0) do={
	:if ($PingFailCountISP1 > 0) do={
		:set PingFailCountISP1 ($PingFailCountISP1 - 1)

		:if ($PingFailCountISP1 = 0) do={
			:log warning "$MainISPname can reach WAN again - bringing back original distance of routes."
			:foreach i in=[/ip route find comment=MAIN && static] do={
				/ip route set $i distance=([/ip route get $i distance] - $DistanceIncrease)
				/ip firewall connection remove [/ip firewall connection find protocol=udp]
				/ip firewall connection remove [/ip firewall connection find protocol=icmp]
        /ip firewall connection remove [/ip firewall connection find where connection-type=sip]
				:log warning "$MainISPname Route distance decrease finished."
				:delay 1
				/tool e-mail send to=$TOmail1 cc=$TOmail2 subject="OK_$ThisBox_$MainISPname"
			}
		}
	}
}

# BACKUP ISP
# IF FAIL
:if ($TotalResult2 < 1) do={
	:if ($PingFailCountISP2 < ($FailTresholdISP2+2)) do={
		:set PingFailCountISP2 ($PingFailCountISP2 + 1)
		:log warning "$BackupISPname lost $PingFailCountISP2 pings to WAN - checking."

		:if ($PingFailCountISP2 = $FailTresholdISP2) do={
			:log warning "$BackupISPname has a problem en route to WAN - increasing distance of routes."
			:foreach i in=[/ip route find comment=BACKUP && static] do={
				/ip route set $i distance=([/ip route get $i distance] + $DistanceIncrease)
				:log warning "$BackupISPname Route distance increase finished."
				:delay 1
				/tool e-mail send to=$TOmail1 cc=$TOmail2 subject="PROBLEM_$ThisBox_$BackupISPname"
			}
		}
	}
}

# IF NOT FAIL
:if ($TotalResult2 > 0) do={
	:if ($PingFailCountISP2 > 0) do={
		:set PingFailCountISP2 ($PingFailCountISP2 - 1)

		:if ($PingFailCountISP2 = 0) do={
			:log warning "$BackupISPname can reach WAN again - bringing back original distance of routes."
			:foreach i in=[/ip route find comment=BACKUP && static] do={
				/ip route set $i distance=([/ip route get $i distance] - $DistanceIncrease)
				:log warning "$BackupISPname Route distance decrease finished."
				:delay 1
				/tool e-mail send to=$TOmail1 cc=$TOmail2 subject="OK_$ThisBox_$BackupISPname"
			}
		}
	}
}
