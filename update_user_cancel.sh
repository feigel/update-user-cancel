#!/bin/sh

#cat <<"EOF" > /wfs/update_user_cancel
#!/bin/bash

RETRIES=9 #Here you can change how many update retries the script will do.
WAIT=30m #Here you can change how long the script will wait after every retry. Please add the suffix 's' for seconds, 'm' for minutes, 'h' for hours or 'd' for days.

UPTODATE=2
UPDATENEEDED=3

#Logging action
ACTION="update_user_cancel"
#output to systemlog with ID amd tag
LOGGER="logger -it ${ACTION}"

#Starting update script 
echo "Starting" | $LOGGER

#start retry loop 
until [  $RETRIES -lt 0 ]; do
#check if session is active 
if ! pgrep -x "vmware-remotemk" > /dev/null && ! pgrep -x "wfica" > /dev/null
then
    echo "No active session detected, checking for new firmware version" | $LOGGER
    #get latest settings from UMS 
    get_rmsettings_boot
    #Check if update is needed
    CURRENTFIRMWARE=$(cat /etc/os-release | grep VERSION= | egrep -o "([0-9]{1,}\.)+[0-9]{1,}");
    UPDATECHECKRESPONSE=$(update-check --check-only)
    UPDATESTATUS=$?
    if [ $UPDATESTATUS -eq $UPTODATE ]; then
        echo "$UPDATECHECKRESPONSE" | $LOGGER
        exit 0
        else
        echo "Current Firmware: $CURRENTFIRMWARE -- $UPDATECHECKRESPONSE" | $LOGGER
        DISPLAY=:0 zenity --question --text "Update needed $UPDATECHECKRESPONSE\nUpdate NOW?" --width=175 --height=100 --timeout=10 --ok-label="Update" --cancel-label="Cancel"
        DIALOGRESPONSE=$?
        if [ $DIALOGRESPONSE -eq 0 ]; then
            echo "Updating firmware per user request" | $LOGGER
            update
        elif [ $DIALOGRESPONSE -eq 5 ]; then 
            echo "Update dialog timed out. Firmware not updated" | $LOGGER
        elif [ $DIALOGRESPONSE -eq 1 ]; then
            echo "User cancelled. Firmware not update" | $LOGGER
        fi
    fi
    
else 
    echo "Active session detected, waiting" $WAIT "Retries left =" $RETRIES | $LOGGER
    let RETRIES-=1
    sleep $WAIT
fi
done
EOF

chmod +x /wfs/update_user_cancel


# Just notes at the moment
# looking to do this as a user-based thingy at boot
#[Service]
#Environment="DISPLAY=:0"
#Environment="XAUTHORITY=/home/pi/.Xauthority"
#
#[Install]
#WantedBy=graphical.target
#
#https://stackoverflow.com/questions/43001223/how-to-ensure-that-there-is-a-delay-before-a-service-is-started-in-systemd
#You can create a .timer systemd unit file to control the execution of your .service unit file.
#
#So for example, to wait for 1 minute after boot-up before starting your foo.service, create a foo.timer file in the same directory with the contents:
#
#[Timer]
#OnBootSec=1min
#It is important that the service is disabled (so it doesn't start at boot), and the timer enabled, for all this to work (thanks to user tride for this):
#
#systemctl disable foo.service
#systemctl enable foo.timer
#
#
#=== Stuff from sebkur
#systemd-run --unit="update-script" --on-calendar="Tue *-*-* 01:00:00" /wfs/updatescript
#
#cat <<"EOF" > /wfs/updatescript
##!/bin/bash
#
#RETRIES=9 #Here you can change how many update retries the script will do.
#WAIT=30m #Here you can change how long the script will wait after every retry. Please add the suffix 's' for seconds, 'm' for minutes, 'h' for hours or 'd' for days.
#
##Logging action
#ACTION="update-script_${1}"
##output to systemlog with ID amd tag
#LOGGER="logger -it ${ACTION}"
#
##Starting update script 
#echo "Starting" | $LOGGER
#
##start retry loop 
#until [  $RETRIES -lt 0 ]; do
##check if session is active 
#if ! pgrep -x "vmware-remotemk" > /dev/null && ! pgrep -x "wfica" > /dev/null
#then
#    echo "No active session detected, checking for new firmware version" | $LOGGER
#    #get latest settings from UMS 
#    get_rmsettings_boot
#    #Get current firmware version
#    CURRENT=$(cat /etc/os-release | grep VERSION= | egrep -o "([0-9]{1,}\.)+[0-9]{1,}");
#    echo "Current firmware is" $CURRENT | $LOGGER
#    #Get assigned firmware version 
#    NEW=$(cat /wfs/group.ini | grep IGEL_Universal_Desktop | egrep -o "([0-9]{1,}\.)+[0-9]{1,}")
#    echo "New firmware version is" $NEW | $LOGGER
#    
#    #Compare firmware version 
#    if [ $CURRENT !=  $NEW ]
#    then
#    	echo "Current firmware is not equal to new firmware, starting update to version" $NEW | $LOGGER
#    	#If current firmware is not equal to new firmware, start update process 
#        update
#	#Exit the loop after the update
#	echo "Update done, exiting" | $LOGGER
#	exit 1   
#    else
#       echo "Current firmware is equal to new firmware, exiting" | $LOGGER
#       exit 1 
#    fi   
#else 
#    echo "Active session detected, waiting" $WAIT "Retries left =" $RETRIES | $LOGGER
#    let RETRIES-=1
#    sleep $WAIT
#fi
#done
#EOF
#
#chmod +x /wfs/updatescript