# update-user-cancel

## Notes
* Using this in a production environment is not supported
* **Don't enable automatic firmware updates!**
* It has been tested with:
    * IGELOS 11.07.110
    * IGELOS 11.08.200
    * A standard IGEL desktop
    * A standard IGEL desktop with initial logon password
* It has **not** been tested with:
    * Autostart sessions of *any* kind
    * Imprivata
    * Anything not explicitly mentioned above!
* This will be moot in OS12, as OS12 has an **AWESOME** update process
* This was built for my personal use, but I'm always willing to share. :-)
  * I find this to be especially helpful when I'm traveling. I have an automated script that puts the latest IGEL firmware in my DigitalOcean spaces repository and having automatic updates on at home works well, but on the road it has rendered my device unusable until I find a stable internet connection - lol

## Usage

1. Import "*profile-script-update-user-cancel.xml*" as profile.
2. If you have something in Firmware Customization>Base>Initialization on the device or in another profile, you will need to make adjustments.
3. Create a file object for "*update-user-cancel-init.sh*"
   1. Put it in /wfs
   2. Owner root:root
   3. r-xr-xr-x

**The init script creates three files:**
1. /wfs/update-user-cancel
2. /etc/systemd/system/update-user-cancel.service
3. /etc/systemd/system/update-user-cancel.timer

## Expected Behavior

At every boot, the device will check to see if there is an updated (not necessarily *newer*) firmware available. It will display a dialog box to ask the user if they want to update now or cancel. The dialog times out with a cancel after 30 seconds (configurable in the *update-user-cancel-init.sh* script).

If there is a login prompt, the script will wait until the lightdm lock goes away.

If the device doesn't get rebooted for 24h, the dialog will display again.
