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
# Edit the variables below to suit your needs

# Please fill the WAN interface names
:local InterfaceISP1 ether1
:local InterfaceISP2 ether2

# Please fill the gateway IPs (or interface names in case of PPP)
:local GatewayISP1 1.1.1.1
:local GatewayISP2 2.2.2.2

# Please fill the ping check host - currently: resolver1.opendns.com
:local PingTarget 208.67.222.222

# Please fill how many ping failures are allowed before fail-over happends
:local FailTreshold 3

# Define the distance increase of a route when it fails
:local DistanceIncrease 2

# Editing the script after this point may break it
# -------------- stop editing here --------------



# Declare the global variables
:global PingFailCountISP1
:global PingFailCountISP2

# This inicializes the PingFailCount variables, in case this is the 1st time the script has ran
:if ([:typeof $PingFailCountISP1] = "nothing") do={:set PingFailCountISP1 0}
:if ([:typeof $PingFailCountISP2] = "nothing") do={:set PingFailCountISP2 0}

# This variable will be used to keep results of individual ping attempts
:local PingResult



# Check ISP1
:set PingResult [ping $PingTarget count=1 interface=$InterfaceISP1]
:put $PingResult

:if ($PingResult = 0) do={
	:if ($PingFailCountISP1 < ($FailTreshold+2)) do={
		:set PingFailCountISP1 ($PingFailCountISP1 + 1)

		:if ($PingFailCountISP1 = $FailTreshold) do={
			:log warning "ISP1 has a problem en route to $PingTarget - increasing distance of routes."
			:foreach i in=[/ip route find gateway=$GatewayISP1 && static] do=\
				{/ip route set $i distance=([/ip route get $i distance] + $DistanceIncrease)}
			:log warning "Route distance increase finished."
		}
	}
}
:if ($PingResult = 1) do={
	:if ($PingFailCountISP1 > 0) do={
		:set PingFailCountISP1 ($PingFailCountISP1 - 1)

		:if ($PingFailCountISP1 = ($FailTreshold -1)) do={
			:log warning "ISP1 can reach $PingTarget again - bringing back original distance of routes."
			:foreach i in=[/ip route find gateway=$GatewayISP1 && static] do=\
				{/ip route set $i distance=([/ip route get $i distance] - $DistanceIncrease)}
			:log warning "Route distance decrease finished."
		}
	}
}



# Check ISP2
:set PingResult [ping $PingTarget count=1 interface=$InterfaceISP2]
:put $PingResult

:if ($PingResult = 0) do={
	:if ($PingFailCountISP2 < ($FailTreshold+2)) do={
		:set PingFailCountISP2 ($PingFailCountISP2 + 1)

		:if ($PingFailCountISP2 = $FailTreshold) do={
			:log warning "ISP2 has a problem en route to $PingTarget - increasing distance of routes."
			:foreach i in=[/ip route find gateway=$GatewayISP2 && static] do=\
				{/ip route set $i distance=([/ip route get $i distance] + $DistanceIncrease)}
			:log warning "Route distance increase finished."
		}
	}
}
:if ($PingResult = 1) do={
	:if ($PingFailCountISP2 > 0) do={
		:set PingFailCountISP2 ($PingFailCountISP2 - 1)

		:if ($PingFailCountISP2 = ($FailTreshold -1)) do={
			:log warning "ISP2 can reach $PingTarget again - bringing back original distance of routes."
			:foreach i in=[/ip route find gateway=$GatewayISP2 && static] do=\
				{/ip route set $i distance=([/ip route get $i distance] - $DistanceIncrease)}
			:log warning "Route distance decrease finished."
		}
	}
}
