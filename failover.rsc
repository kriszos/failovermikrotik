# ------------------- header -------------------
# Script by Tomas Kirnak, version 1.0.7
# If you use this script, or edit and
# re-use it, please keep the header intact.
#
# For more information and details about
# this script please visit the wiki page at
# http://wiki.mikrotik.com/wiki/Failover_Scripting
# ------------------- header -------------------



# ------------- start editing here -------------
# changes by Kriszos
# Edit the variables below to suit your needs

# Please fill the WAN interface names
#:local InterfaceISP1 ether1
#:local InterfaceISP2 ether2

# Please fill the gateway IPs (or interface names in case of PPP)
#:local GatewayISP1 1.1.1.1
#:local GatewayISP2 2.2.2.2

# Please fill the ping check host - currently: resolver1.opendns.com
:local PingTarget1 192.58.128.30
:local PingTarget2 192.203.230.10

# Please fill how many ping failures are allowed before fail-over happends
:local FailTreshold 10

# Define the distance increase of a route when it fails
:local DistanceIncrease 50

# Define name of main ISP for mail
:local MainISPname UPC

# Define name of TO & CC field for mail both MUST be SET
:local TOmail1 monitoring@allware.pro
:local TOmail2 krzysztof.szostak@allware.pro




# Editing the script after this point may break it
# -------------- stop editing here --------------

# Define System identity to variable
:local ThisBox [/system identity get name]

# Declare the global variables
:global PingFailCountISP1
#:global PingFailCountISP2

# This inicializes the PingFailCount variables, in case this is the 1st time the script has ran
:if ([:typeof $PingFailCountISP1] = "nothing") do={:set PingFailCountISP1 0}
#:if ([:typeof $PingFailCountISP2] = "nothing") do={:set PingFailCountISP2 0}

# This variable will be used to keep results of individual ping attempts
:local PingResult1
:local PingResult2



# Check ISP1
:set PingResult1 [ping $PingTarget1 count=1]
:put $PingResult1

# IF FAIL
:if ($PingResult1 = 0) do={
	:if ($PingFailCountISP1 < ($FailTreshold+2)) do={
		:set PingFailCountISP1 ($PingFailCountISP1 + 1)
		:log warning "$MainISPname lost $PingFailCountISP1 pings to $PingTarget1 - checking."

		:if ($PingFailCountISP1 = $FailTreshold) do={
			:log warning "$MainISPname has a problem en route to $PingTarget1 - increasing distance of routes."
			:foreach i in=[/ip route find comment=MAIN && static] do={
				/ip route set $i distance=([/ip route get $i distance] + $DistanceIncrease)
				/ip firewall connection remove [/ip firewall connection find protocol=udp]
				/ip firewall connection remove [/ip firewall connection find protocol=icmp]
				:log warning "$MainISPname Route distance increase finished."
				:delay 4
				/tool e-mail send to=$TOmail1 cc=$TOmail2 subject="PROBLEM_$ThisBox_$MainISPname"
			}
		}
	}
}

# IF NOT FAIL
:if ($PingResult1 = 1) do={
	:if ($PingFailCountISP1 > 0) do={
		:set PingFailCountISP1 ($PingFailCountISP1 - 1)

		:if ($PingFailCountISP1 = ($FailTreshold - $FailTreshold)) do={
			:log warning "$MainISPname can reach $PingTarget1 again - bringing back original distance of routes."
			:foreach i in=[/ip route find comment=MAIN && static] do={
				/ip route set $i distance=([/ip route get $i distance] - $DistanceIncrease)
				/ip firewall connection remove [/ip firewall connection find protocol=udp]
				/ip firewall connection remove [/ip firewall connection find protocol=icmp]
				:log warning "$MainISPname Route distance decrease finished."
				:delay 4
				/tool e-mail send to=$TOmail1 cc=$TOmail2 subject="OK_$ThisBox_$MainISPname"
			}
		}
	}
}


























# Check ISP2
#:set PingResult1 [ping $PingTarget1 count=1 interface=$InterfaceISP2]
#:put $PingResult1

#:if ($PingResult1 = 0) do={
#	:if ($PingFailCountISP2 < ($FailTreshold+2)) do={
#		:set PingFailCountISP2 ($PingFailCountISP2 + 1)

#		:if ($PingFailCountISP2 = $FailTreshold) do={
#			:log warning "ISP2 has a problem en route to $PingTarget1 - increasing distance of routes."
#			:foreach i in=[/ip route find gateway=$GatewayISP2 && static] do=\
#				{/ip route set $i distance=([/ip route get $i distance] + $DistanceIncrease)}
#			:log warning "Route distance increase finished."
#		}
#	}
#}
#:if ($PingResult1 = 1) do={
#	:if ($PingFailCountISP2 > 0) do={
#		:set PingFailCountISP2 ($PingFailCountISP2 - 1)

#		:if ($PingFailCountISP2 = ($FailTreshold -1)) do={
#			:log warning "ISP2 can reach $PingTarget1 again - bringing back original distance of routes."
#			:foreach i in=[/ip route find gateway=$GatewayISP2 && static] do=\
#				{/ip route set $i distance=([/ip route get $i distance] - $DistanceIncrease)}
#			:log warning "Route distance decrease finished."
#		}
#	}
#}
