# update-user-cancel-init.sh

#!/bin/bash -   
#title          :update-user-cancel-init.sh
#description    :Allow user to choose to update firmware or not bootstrap file
#author         :Jeff Feige
#date           :20221109
#version        :1.0    
#usage          :./update-user-cancel-init.sh
#notes          :AS-IS NO WARRANTY OF ANY KIND
#notes          :put this file in /wfs
#notes          :call it from System>Firmware Customization>Custom Commands>Base>Initialization
#license	:MIT license (attribution required)       
#bash_version   :5.1.16(1)-release
#============================================================================
cat << "EOF" > /usr/local/bin/update-user-cancel
#!/bin/bash -   
#title          :update-user-cancel.sh
#description    :Allow user to choose to update firmware or not
#author         :Jeff Feige
#date           :20221109
#version        :1.0    
#usage          :./update-user-cancel.sh
#notes          :AS-IS NO WARRANTY OF ANY KIND
#license	:MIT license (attribution required)       
#bash_version   :5.1.16(1)-release
#============================================================================

# Return values from update-check --check-only
UPTODATE=2
UPDATENEEDED=3
# Return values from zenity
ZOK=0
ZCANCEL=1
ZTIMEOUT=5

# Length of time Zenity stays on screen before timeout
DIALOGTIMEOUT=30

# Number of times to retry if the lock screen is up
RETRY=10
# How long to wait between each retry
# If set to 0, then retry indefinitely -- broken
RETRYDELAY=10

# Name of program to log
LOGGERNAME="update_user_cancel"
# Create easy logger command
LOGGER="logger -it $LOGGERNAME"

# Start
echo "Starting $LOGGERNAME" | $LOGGER

    # get latest ums settings
    get_rmsettings
    # See if we need to update or not
    #CURRENTFIRMWARE=$(cat /etc/os-release | grep VERSION= | egrep -o "([0-9]{1,}\.)+[0-9]{1,}");
    # Get the current firmware version for dialog
    CURRENTFIRMWARE=$(get product.version)
    # Check to see if we need to update
    UPDATECHECKRESPONSE=$(update-check --check-only)
    UPDATESTATUS=$?
    if [ $UPDATESTATUS -eq $UPTODATE ]; then
        echo "$UPDATECHECKRESPONSE" | $LOGGER
        exit 0
        else
            until [ $RETRY -lt 1 ]; do
                if pgrep -f lightdm-igel-greeter >> /dev/null; then 
                    sleep $RETRYDELAY
                    if [ $RETRYDELAY -ne 0 ]; then
                        ((RETRY=$RETRY-1))
                    fi
                else 
                    echo "Current Firmware: $CURRENTFIRMWARE -- $UPDATECHECKRESPONSE" | $LOGGER
                    DISPLAY=:0 zenity --question --text "Update needed $UPDATECHECKRESPONSE\nUpdate NOW?" --width=175 --height=100 --timeout=$DIALOGTIMEOUT --ok-label="Update" --cancel-label="Cancel"
                    DIALOGRESPONSE=$?
                    if [ $DIALOGRESPONSE -eq $ZOK ]; then
                        echo "Updating firmware per user request" | $LOGGER
                        update
                        exit 0
                    elif [ $DIALOGRESPONSE -eq $ZTIMEOUT ]; then 
                        echo "Update dialog timed out. Firmware not updated" | $LOGGER
                        exit 0
                    elif [ $DIALOGRESPONSE -eq $ZCANCEL ]; then
                        echo "User cancelled. Firmware not update" | $LOGGER
                        exit 0
                    fi
                fi
            done
    fi

# profit
EOF

cat << "EOF" > /etc/systemd/system/update-user-cancel.service
[Service]
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/userhome/.Xauthority"
ExecStart=/usr/local/bin/update-user-cancel

[Install]
WantedBy=igel-default-boot.target

#systemctl disable foo.service
#systemctl enable foo.timer
#=== Stuff from sebkur
#systemd-run --unit="update-script" --on-calendar="Tue *-*-* 01:00:00" /wfs/updatescript
EOF

cat << "EOF" > /etc/systemd/system/update-user-cancel.timer
[Unit]
Description="Allow user to cancel firmware update"

[Timer]
OnActiveSec=10
RemainAfterElapse=no
#OnBootSec=3min
# If you only want this to happen once a day, uncomment
#OnUnitActiveSec=24h
Unit=update-user-cancel.service

[Install]
WantedBy=igel-default-boot.target
PartOf=igel-default-boot.target
After=igel-default-boot.target
EOF

chmod +x /usr/local/bin/update-user-cancel
systemctl daemon-reload
systemctl disable update-user-cancel.service
systemctl enable update-user-cancel.timer --now