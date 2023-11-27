#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
rest='\033[0m'

#check_dependencies
check_dependencies() {
    local dependencies=("curl" "wget" "unzip")

    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "${dep}" &> /dev/null; then
            echo "${dep} is not installed. Installing..."
            apt install "${dep}" -y
        fi
    done
}

download-xray() {
    pkg update -y
    check_dependencies
    mkdir xy-fragment && cd xy-fragment
    wget https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-android-arm64-v8a.zip
    unzip Xray-android-arm64-v8a.zip
    find /data/data/com.termux/files/home/xy-fragment -type f ! -name 'xray' -delete
    chmod +x xray
}

config() {
    cat << EOL > config.json
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": $port,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct",
            "settings": {
                "domainStrategy": "AsIs",
                "fragment": {
                    "packets": "tlshello",
                    "length": "100-200",
                    "interval": "10-20"
                }
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOL
}

install() {
    download-xray
    uuid=$(./xray uuid)
    config
    clear
    read -p "Enter a Port between [1024 - 65535]: " port
    vmess="{\"add\":\"127.0.0.1\",\"aid\":\"0\",\"alpn\":\"\",\"fp\":\"\",\"host\":\"\",\"id\":\"$uuid\",\"net\":\"ws\",\"path\":\"\",\"port\":\"$port\",\"ps\":\"Peyman YouTube X\",\"scy\":\"auto\",\"sni\":\"\",\"tls\":\"\",\"type\":\"\",\"v\":\"2\"}"
    encoded_vmess=$(echo -n "$vmess" | base64 -w 0)
    echo -e "${blue}--------------------------------------${rest}"
    echo -e "${yellow}vmess://$encoded_vmess${rest}"
    echo -e "${blue}--------------------------------------${rest}"
    echo "vmess://$encoded_vmess" > "xy-fragment/vmess.txt"
}

uninstall() {
    directory="/data/data/com.termux/files/home/xy-fragment"
    if [ -d "$directory" ]; then
        rm -r "$directory"
        echo "Uninstallation completed."
    else
        echo "Please Install First."
    fi
}

#run
run() {
    clear
	xray_directory="xy-fragment"
	config_file="config.json"
	xray_executable="xray"
	
	if [ -f "$xray_directory/$config_file" ] && [ -f "$xray_directory/$xray_executable" ]; then
	    clear
	    echo "Starting..."
	    cd "$xray_directory" && ./"$xray_executable" run "$config_file"
	else
	    echo "Error: The file '$config_file' or '$xray_executable' doesn't exist in the directory: '$xray_directory'."
	fi
}


#menu
clear
echo "By --> Peyman * Github.com/Ptechgithub * "
echo ""
echo -e "${cyan}Bypass Filtering -- Xray Fragment  ${rest}"
echo -e "${yellow}Select an option:${rest}"
echo ""
echo -e "${purple}1)${rest} ${green}Get Your Config${rest}"
echo -e "${purple}2)${rest} ${green}Run VPN${rest}"
echo -e "${purple}3)${rest} ${green}Uninstall${rest}"
echo -e "${red}0)${rest} ${green}Exit${rest}"
read -p "Enter your choice: " choice

case "$choice" in
   1)
        install
        ;;
    2)
        run
        ;;
    3)
        uninstall
        ;;
    0)   
        exit
        ;;
    *)
        echo "Invalid choice. Please select a valid option."
        ;;
esac