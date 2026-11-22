# Kobo Bluetooth scan dump

This tool shows what the Kobo's Bluetooth service actually finds when it scans.
The Settings → Bluetooth list may hide some of those devices. Comparing the
3-key remote (hidden) with the Xbox controller (shown) tells us what the Kobo
filters on.

The script only reads information and runs one 25-second scan. It doesn't pair
or connect anything, change settings, or load or unload drivers.

## One-time setup: install NickelMenu
1. Download `KoboRoot.tgz` from the latest release at
   https://github.com/pgaskin/NickelMenu/releases
2. Plug the Kobo into your PC over USB. Copy `KoboRoot.tgz` into the hidden
   `.kobo` folder on the Kobo drive.
3. Eject the Kobo safely. It installs the file and restarts.

NickelMenu adds a menu at the bottom right of the Home screen. To remove it
later, create an empty file called `uninstall` in `.adds/nm/` and restart the
Kobo.

## Copy the script
With the Kobo plugged in over USB:
- `btdump.sh` → `.adds/btdump.sh`
- `nm/btdump` → `.adds/nm/btdump`

Eject the Kobo.

## Run it
1. On the Kobo, turn on Bluetooth: Settings → Bluetooth.
2. Wake the 3-key remote and put the **Xbox controller in pairing mode**.
   Keep both close to the Kobo.
3. Open the NickelMenu menu and tap **Bluetooth scan dump**. Wait about 40
   seconds.
4. Plug the Kobo into your PC and send me `btdump.txt` from the root of the
   Kobo drive. You can paste its contents into this chat.
