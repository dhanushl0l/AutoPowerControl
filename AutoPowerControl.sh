#!/bin/bash

# IP address of the Windows PC
WINDOWS_PC_IP="YOUR_WINDOWS_PC_IP"

# SSH user on the Windows PC
WINDOWS_USER="YOUR_WINDOWS_USER"

# SSH password on the Windows PC
SSH_PASSWORD="YOUR_SSH_PASSWORD"

# MAC address of the Windows PC (formatted with colons)
WINDOWS_PC_MAC="YOUR_WINDOWS_PC_MAC"

# Interval to check the charging status (in seconds)
INTERVAL=1

# Function to check if the laptop is charging
is_charging() {
    local state=$(upower -i $(upower -e | grep 'BAT') | grep -E "state:" | awk '{print $2}')
    if [ "$state" == "charging" ] || [ "$state" == "fully-charged" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if Windows PC is online
is_windows_pc_online() {
    echo "$(date): Pinging Windows PC at ${WINDOWS_PC_IP}"
    ping -c 1 -W 1 ${WINDOWS_PC_IP} >/dev/null 2>&1
    local ping_result=$?
    if [ $ping_result -eq 0 ]; then
        echo "$(date): Ping successful. Windows PC is online."
    else
        echo "$(date): Ping failed. Windows PC is offline."
    fi
    return $ping_result
}

# Function to put Windows PC to sleep (using SSH)
sleep_windows_pc() {
    echo "$(date): Putting Windows PC at ${WINDOWS_PC_IP} to sleep"
    nohup sshpass -p ${SSH_PASSWORD} ssh ${WINDOWS_USER}@${WINDOWS_PC_IP} \
    "rundll32.exe powrprof.dll,SetSuspendState 0,1,0" >/dev/null 2>&1 &
    echo "$(date): Windows PC command sent. Continuing to next function."
}

# Function to wake up Windows PC using Wake-on-LAN
wake_windows_pc() {
    echo "$(date): Sending Wake-on-LAN packet to ${WINDOWS_PC_MAC}"
    sudo wakeonlan ${WINDOWS_PC_MAC}
    if [ $? -eq 0 ]; then
        echo "$(date): Wake-on-LAN packet sent successfully."
        # Wait a bit and then check if the PC has woken up
        sleep 10
        if sshpass -p ${SSH_PASSWORD} ssh -o ConnectTimeout=5 ${WINDOWS_USER}@${WINDOWS_PC_IP} "exit" >/dev/null 2>&1; then
            echo "$(date): Windows PC is awake."
        else
            echo "$(date): Windows PC is still asleep or not reachable."
        fi
    else
        echo "$(date): Failed to send Wake-on-LAN packet."
    fi
}

# Track the previous state to avoid redundant commands
previous_state=""
pc_was_put_to_sleep=false

while true; do
    if is_charging; then
        if [ "$previous_state" != "charging" ]; then
            echo "$(date): Laptop is charging."
            # Wait for 5 seconds to ensure the charger stays connected
            for i in {5..1}; do
                echo "$(date): Waiting $i seconds to verify charger connection."
                sleep 1
            done
            if is_charging; then
                echo "$(date): Charger remained connected."
                if $pc_was_put_to_sleep; then
                    echo "$(date): Waking Windows PC."
                    wake_windows_pc
                    pc_was_put_to_sleep=false
                else
                    echo "$(date): Windows PC was not put to sleep. No need to wake it."
                fi
                previous_state="charging"
            else
                echo "$(date): Charger disconnected during wait period. Not waking PC."
            fi
        fi
    else
        if [ "$previous_state" != "not_charging" ]; then
            echo "$(date): Laptop is not charging."
            # Wait for 30 seconds before putting the PC to sleep
            for i in {30..1}; do
                echo "$(date): Waiting $i seconds to verify if charger is reconnected."
                sleep 1
            done
            if ! is_charging; then
                echo "$(date): Charger not reconnected within 30 seconds."
                if is_windows_pc_online; then
                    echo "$(date): Windows PC is online. Putting it to sleep."
                    sleep_windows_pc
                    pc_was_put_to_sleep=true
                else
                    echo "$(date): Windows PC is offline. Not sending sleep command."
                    pc_was_put_to_sleep=false
                fi
                previous_state="not_charging"
            else
                echo "$(date): Charger reconnected within 30 seconds. Not putting PC to sleep."
            fi
        fi
    fi
    sleep $INTERVAL
done
