#!/bin/bash

credentials_file="./credentials.txt"


install_openvpn() {
    distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
    case $distro in
        "Ubuntu" | "Debian")
            sudo apt-get update
            sudo apt-get install -y openvpn
            ;;
        "Fedora" | "CentOS" | "Red Hat Enterprise Linux")
            sudo dnf install -y openvpn
            ;;
        "Arch Linux")
            sudo pacman -Sy openvpn
            ;;
        *)
            echo "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}

add_nameserver() {
    sudo sed -i '1s/^/nameserver 10.4.20.21\n/' /etc/resolv.conf
}

remove_nameserver() {
    sudo sed -i '/^nameserver 10.4.20.21$/d' /etc/resolv.conf
}

download_ovpn() {
    echo "Supported Linux distributions:"
    echo "1. Ubuntu / Debian"
    echo "2. Fedora / CentOS / Red Hat Enterprise Linux"
    echo "3. Arch Linux"

    read -p "Enter the number corresponding to your distribution: " distro_choice

    case $distro_choice in
        1)
            install_openvpn
            ;;
        2)
            install_openvpn
            ;;
        3)
            install_openvpn
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    if [ -f "$credentials_file" ]; then
        # Read the username and password from the file
        readarray -t credentials < "$credentials_file"
        username="${credentials[0]}"
        password="${credentials[1]}"
    else
        echo "Enter your username for VPN authentication:"
        read username
        echo "Enter your password for VPN authentication:"
        read -s password
        # Save the username and password to the file
        echo "$username" > "$credentials_file"
        echo "$password" >> "$credentials_file"
    fi

    wget --user="$username" --password="$password" -O ./linux.ovpn https://vpn.iiit.ac.in/file/linux.ovpn
}

run_vpn() {
    if [ -f "$credentials_file" ]; then
        sed -i 's/auth-user-pass/auth-user-pass credentials.txt/g' ./linux.ovpn
    fi
    sudo openvpn --config ./linux.ovpn
}

main() {
    echo "What would you like to do?"
    echo "1. Download VPN configuration file"
    echo "2. Run VPN using existing configuration"
    read -p "Enter your choice (1/2): " choice

    case $choice in
        1)
            download_ovpn
            ;;
        2)
            if [ ! -f "./linux.ovpn" ]; then
                echo "VPN configuration file not found. Please download it first."
                exit 1
            fi

            add_nameserver

            run_vpn
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    if [ "$choice" != "1" ]; then
        sleep 5
        if ! ssh example.com true &> /dev/null; then
            remove_nameserver
        fi
        while true; do
            if ! pgrep -x "openvpn" >/dev/null; then
                break
            fi
            sleep 1
        done
        rm /tmp/linux.ovpn
    fi
}

main
