# A tool to find the last known IP of a device with known MAC-address

$config = Get-Content -Path C:\stuff\config.cfg

# Get the mac address from config.cfg
$macLine = $config | Select -Index 0
$mac = $macLine.substring(6)


# Add dashes so that the mac address can be matched to the arp table
if ($mac.length -eq 12){
        $mac = $mac.insert(2,"-").insert(5,"-").insert(8,"-").insert(11,"-").insert(14,"-")
        "Device MAC: " + $mac
    } Else {
        Write-Warning "The MAC Address $($mac) is not 12 characters"
    }

# Look for the ip in the arp table
$ip = arp -a | select-string "$mac" |% {$_.ToString().Trim().Split(" ")[0]}
if ($ip) {
    # Print and write the IP to config file
    "Device IP: " + $ip
    $config[2] = "host = " + $ip
    $config | Set-Content -Path C:\stuff\config.cfg
    
    Write-Warning "Success!"
}else {
    Write-Warning "MAC address not present in arp list."

       
    $lastHost = $lastHost.IPV4Address.IPAddressToString
    "Scanning from IP " + $lastHost
    

    $testIP = $lastHost.split('.')
    
    # Form a template to which we can add the last number
    $templateIP = $testIP[0] + '.' + $testIP[1] + '.' + $testIP[2] + '.'

    $postfix = $testIP[-1] - 10

    # $postfix = $postfix - 5
    
    # Make sure that we only scan addresses with a postfix between 0..255
    if ( $postfix -lt 2) {
        $postfix = 2
    }

    if ($postfix -gt 225) {
        $postfix = 225
    }

    for($i=0; $i -le 30;  $i++){
        
        # Ping the ip-range 
        $postfix | % {echo "$templateIP + $_"; ping -n 1 -w 10 ($templateIP + $_)} | Select-String ttl
        "Pinging " + $templateIP + $postfix
        $postfix = $postfix + 1
    }

    $ip = arp -a | select-string "$mac" |% {$_.ToString().Trim().Split(" ")[0]}
    if ($ip) {
        # Print and write the IP to config file
        "Device IP: " + $ip
        $config[5] = "host = " + $ip
        $config | Set-Content -Path C:\stuff\config.cfg
        
        Write-Warning "Success!" 
    }else {
        Write-Warning "MAC address not present in arp list. Scanning more..."

        for($i=2; $i -le 253;  $i++){
        
            # Ping the ip-range 
            $i | % {echo "$templateIP + $_"; ping -n 1 -w 15 ($templateIP + $_)} | Select-String ttl
            # "Pinging " + $templateIP + $i
            # $postfix = $postfix + 1
            $percent = ($i / 253) * 100
            "Scanning " + [math]::Round($percent) + "%"
        }

        $ip = arp -a | select-string "$mac" |% {$_.ToString().Trim().Split(" ")[0]}

        if ($ip) {
            # Print and write the IP to config file
            "Device IP: " + $ip
            $config[2] = "host = " + $ip
            $config | Set-Content -Path C:\stuff\config.cfg
            
            Write-Warning "Success!" 
        }else {
            Write-Warning "MAC address not present in arp list. Please check connection."
            Start-Sleep -Second 5
        }
    }
}

