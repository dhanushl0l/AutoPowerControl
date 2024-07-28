# AutoPowerControl
This script automatically powers off and powers on a Windows PC based on the charging status of a laptop if linux running on it. 

## Requirements

- `upower` to check the battery status of the laptop.
- `sshpass` to automate SSH login without a password prompt.
- `wakeonlan` to send Wake-on-LAN packets to the Windows PC.

## Setup

1. **Install Dependencies**:
   ```sh
   sudo apt-get install upower sshpass wakeonlan
   
2. **Clone the Repository**:
   ```sh
   git clone https://github.com/dhanushl0l/AutoPowerControl.git
   ```sh
   cd auto_power_control

4. **Configure Script**:
   Edit the autopowercontrol.sh script and replace the placeholders with your actual information:
   
   YOUR_WINDOWS_PC_IP
   YOUR_WINDOWS_USER
   YOUR_SSH_PASSWORD
   YOUR_WINDOWS_PC_MAC
   
   ```sh
   sudo nano AutoPowerControl.sh

5. **Make Script Executable**:
   ```sh
   chmod +x auto_power_control.sh

6. **Run the Script & test the working properly**:
   ```sh
   ./AutoPowerControl.sh

## Now you can run this as service
by following this instrections [follow this](https://tecadmin.net/run-shell-script-as-systemd-service/)
