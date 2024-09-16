#!/bin/bash


# Display colored and large text
echo -e "\e[38;2;0;255;0m\e[1m
░█░░▒█▒██▀░█▒░░▄▀▀░▄▀▄░█▄▒▄█▒██▀░░░█░█▄░█░▀█▀▒██▀▒█▀▄░█▄░█▒██▀░▀█▀░░░▀█▀░█▄█▒▄▀▄░█░█▒░▒▄▀▄░█▄░█░█▀▄
░▀▄▀▄▀░█▄▄▒█▄▄░▀▄▄░▀▄▀░█▒▀▒█░█▄▄▒░░█░█▒▀█░▒█▒░█▄▄░█▀▄░█▒▀█░█▄▄░▒█▒▒░░▒█▒▒█▒█░█▀█░█▒█▄▄░█▀█░█▒▀█▒█▄▀
\e[0m"

# Function to print messages in red
print_red() {
  echo -e "\033[31m$1\033[0m"
}

# Function to print messages in green
print_green() {
  echo -e "\033[32m$1\033[0m"
}

# Function to print messages in yellow
print_yellow() {
  echo -e "\033[33m$1\033[0m"
}



# Function to check if a package is installed, if not, install it
check_install_package() {
  PACKAGE_NAME=$1
  COMMAND_CHECK=$2
  INSTALL_COMMAND=$3

  $COMMAND_CHECK &> /dev/null
  if [ $? -ne 0 ]; then
    echo "$PACKAGE_NAME not found. Installing $PACKAGE_NAME..."

    # Try yum first
    sudo yum install -y $INSTALL_COMMAND
    if [ $? -ne 0 ]; then
      # If yum fails, try dnf
      echo "yum failed. Trying dnf..."
      sudo dnf install -y $INSTALL_COMMAND
      if [ $? -ne 0 ]; then
        print_red "Cannot install $PACKAGE_NAME with yum or dnf. Skipping..."
        return 1
      fi
    fi

    echo "$PACKAGE_NAME installed successfully."
  else
    print_green "$PACKAGE_NAME is already installed."
  fi
  return 0
}

# Function to check OS version, kernel, hostname, and IP address
check_os_version() {
  echo "Checking OS version, kernel, hostname, and IP address..."
  
  # Retrieve OS version
  OS_VERSION=$(cat /etc/centos-release 2>/dev/null || cat /etc/os-release || hostnamectl)
  
  # Retrieve kernel version
  KERNEL_VERSION=$(uname -r)

  # Check if hostname command is available and get hostname
  if command -v hostname &> /dev/null; then
    HOSTNAME=$(hostname)
  else
    HOSTNAME="Hostname command not found"
  fi

  # Retrieve IP address
  IP_ADDRESS=$(hostname -I | awk '{print $1}')
  if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS="IP Address not found"
  fi

  # Display results
  if [ $? -ne 0 ]; then
    print_red "Cannot determine OS version or kernel"
  else
    print_green "OS version: $OS_VERSION"
    print_green "Kernel version: $KERNEL_VERSION"
    print_green "Hostname: $HOSTNAME"
    print_green "IP Address: $IP_ADDRESS"
  fi

  main_menu
}



# Function to display main menu
main_menu() {
  echo "Select an option:"
  echo "1) Install Duo"
  echo "2) Uninstall Duo"
  echo "3) Check OS Version"
  echo "4) Check Tools"
  echo "5) Check passwd"
  echo "q) Quit"
  read -p "Enter your choice: " CHOICE

  case $CHOICE in
    1)
      install_duo
      ;;
    2)
      uninstall_duo
      ;;
    3)
      check_os_version 
      ;;
    4)
      check_tools
      ;;
    5)
      echo "----------------------------"
      echo ""
      cut -d: -f1 /etc/passwd
      echo ""
      echo "----------------------------"
      main_menu
      ;;
    q)
      self_delete
      ;;
    *)
      print_red "Invalid choice, please try again."
      main_menu
      ;;
  esac
}

# Update the SSH check to try 'openssh-server openssh-clients' if SSH fails
check_tools() {
  echo "Checking tools..."
  check_install_package "wget" "wget --version" "wget" || main_menu
  check_install_package "nano" "nano --version" "nano" || main_menu
  check_install_package "make" "make --version" "make" || main_menu
  check_install_package "gcc" "gcc --version" "gcc" || main_menu
  check_install_package "openssl" "rpm -qi openssl-devel" "openssl-devel" || main_menu
  main_menu
}

# Function to install Duo
install_duo() {
  # Ping check
  echo "Checking internet connection..."
  ping -c 1 google.com
  if [ $? -ne 0 ]; then
    print_red "Internet no connection"
    main_menu
  else
    echo "Internet is connected."
  fi
  sleep 5

  # Check GCC installation
  check_install_package "GCC" "gcc --version" "yum install -y gcc"

  # Install OpenSSL
  check_install_package "OpenSSL" "rpm -qi openssl-devel" "yum install -y openssl-devel"

  # Check wget installation
  check_install_package "wget" "wget --version" "yum install -y wget"

    # Check for existing Duo Unix files
  DUO_FILE_1="duo_unix-latest.tar.gz"
  DUO_FILE_2="duo_unix-2.0.3.tar.gz"

  if [ -f "$DUO_FILE_1" ] && [ -f "$DUO_FILE_2" ]; then
    print_green "Using existing Duo Unix files: $DUO_FILE_1 and $DUO_FILE_2"
  else
    echo "Downloading Duo Unix..."
    
    if [ ! -f "$DUO_FILE_1" ]; then
      wget --content-disposition https://dl.duosecurity.com/duo_unix-latest.tar.gz
      if [ $? -ne 0 ]; then
        print_red "Cannot wget duo_unix-latest.tar.gz"
        main_menu
      fi
    fi

    if [ ! -f "$DUO_FILE_2" ]; then
      wget --content-disposition https://dl.duosecurity.com/duo_unix-2.0.3.tar.gz
      if [ $? -ne 0 ]; then
        print_red "Cannot wget duo_unix-2.0.3.tar.gz"
        main_menu
      fi
    fi
  fi

  # Unzip Duo Unix
  echo "Unzipping Duo Unix..."
  tar -xzvf duo_unix-2.0.3.tar.gz
  if [ $? -ne 0 ]; then
    print_red "Cannot tar duo_unix-2.0.3.tar.gz"
    main_menu
  fi

  # Change directory to Duo Unix
  echo "Changing directory to duo_unix-2.0.3..."
  cd duo_unix-2.0.3
  if [ $? -ne 0 ]; then
    print_red "Cannot cd into duo_unix-2.0.3"
    main_menu
  fi

  # Install Duo Unix
  echo "Installing Duo Unix..."
  ./configure --prefix=/usr && make && sudo make install
  if [ $? -ne 0 ]; then
    print_red "Error during Duo Unix installation"
    main_menu
  else
    print_green "Duo Unix installed successfully."
  fi

# Configure Duo Unix
  echo "Configuring Duo Unix..."
  if [ -f /etc/duo/login_duo.conf ]; then
    echo "Found login_duo.conf file."
    if [ -x "$(command -v nano)" ]; then
      nano /etc/duo/login_duo.conf
    else
      vi /etc/duo/login_duo.conf
    fi
  elif [ -f /etc/login_duo.conf ]; then
    echo "Found login_duo.conf file in /etc."
    if [ -x "$(command -v nano)" ]; then
      nano /etc/login_duo.conf
    else
      vi /etc/login_duo.conf
    fi
  else
    print_red "Error: login_duo.conf file not found in /etc/duo or /etc."
    main_menu
  fi

  # Function to display Duo 2FA login configuration
show_duo_config() {
  clear
  echo ""
  echo ""
  echo ""
  echo -e "\e[38;2;0;255;0m\e[1m# Duo 2FA login\e[0m"
  echo "ForceCommand /usr/sbin/login_duo"
  echo "PermitTunnel no"
  echo "AllowTcpForwarding no"
  echo ""
  echo ""
  echo ""
  
  read -p "Copy to continue, Enter..."
}

# Call the function where necessary in your script
show_duo_config

  # Edit SSH configuration
  echo "Editing SSH configuration..."
  cd /etc/ssh
  nano sshd_config
  if [ $? -ne 0 ]; then
    vi sshd_config
  fi

  # Restart SSH service
  echo "Restarting SSH service..."
  sudo systemctl restart sshd
  if [ $? -ne 0 ]; then
    print_red "Error restarting SSH service"
    main_menu
  else
    print_green "SSHD service restarted successfully."
  fi

  print_green "Duo installation completed."
  main_menu
}

# Function to uninstall Duo
uninstall_duo() {
  if [ ! -d "/etc/duo" ]; then
    print_yellow "Duo is already uninstalled."
    sleep 3
  else
    print_yellow "Uninstalling Duo..."
    # Remove Duo files
    sudo rm -f /etc/duo/login_duo.conf
    sudo rm -f /usr/sbin/login_duo
    sudo rm -f /usr/lib/libduo.*
    sudo rmdir /etc/duo

    sleep 2

    # Edit SSH configuration
    echo "Editing SSH configuration..."
    cd /etc/ssh
    nano sshd_config
    if [ $? -ne 0 ]; then
      vi sshd_config
    fi

    # Restart SSH service
    echo "Restarting SSH service..."
    sudo systemctl restart sshd
    if [ $? -ne 0 ]; then
      print_red "Error restarting SSH service"
    else
      echo "SSH service restarted successfully."
    fi

    print_green "Duo uninstallation completed."
  fi

  main_menu
}

# Function to delete this script
self_delete() {
    print_green "Deleting this script..."
    rm -- "$0"
}


# Start with the main menu
main_menu


