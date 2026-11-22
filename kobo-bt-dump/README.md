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

## Bluetooth probe (read-only)
`btprobe.sh` looks for Bluetooth config files and checks whether Kobo's
MediaTek Bluetooth software has a built-in radio-level ("btsnoop") log.

To install it, copy `btprobe.sh` to `.adds/btprobe.sh`. Replace
`.adds/nm/btdump` with the new version, which adds the menu item. Turn
Bluetooth on, then tap **Bluetooth probe (read-only)** and wait about a
minute. Then send `btprobe.txt` from the root of the Kobo drive.

## Bluetooth radio log (btsnoop)
`btsnoop.sh` turns on the radio log that is built into Kobo's MediaTek
Bluetooth software. It records every packet the Bluetooth chip passes to that
software, which shows whether the Kobo's radio hears the board at all.

It changes only the `BtSnoopLogOutput` and `BtSnoopFileName` lines in
`/etc/bluetooth/bt_stack.conf`. The original is saved first, both next to that
file and as `bt_stack.conf.backup` on the Kobo drive. **BT log 3** puts the
original back exactly. Each step writes a report to `btsnoop_status.txt` on the
Kobo drive.

1. Copy `btsnoop.sh` to `.adds/btsnoop.sh`. Replace `.adds/nm/btdump` with the
   new version.
2. Tap **BT log 1 - turn ON and reboot**. The Kobo restarts.
3. Turn on Bluetooth, wake the remote, then tap **Bluetooth scan dump** and wait
   about 40 seconds.
4. Tap **BT log 2 - save to USB drive**.
5. Tap **BT log 3 - turn OFF and reboot**.
6. Send `btsnoop_hci.log`, `btsnoop_status.txt` and `btdump.txt`.
