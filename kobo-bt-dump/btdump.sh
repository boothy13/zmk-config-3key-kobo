#!/bin/sh
# Read-only diagnostic for Kobo MediaTek models (Clara Colour / Clara BW /
# Libra Colour). Asks Kobo's own Bluetooth service what it can see, including
# devices the Settings > Bluetooth list may be hiding, and saves it to
# btdump.txt on the Kobo's USB drive.
#
# It only starts/stops a scan and reads properties: it does not pair, connect,
# change settings or load/unload drivers.
#
# Before running: turn Bluetooth ON in Kobo settings, put the 3-key remote
# (and, for comparison, the Xbox controller) in pairing mode next to the Kobo.

OUT=/mnt/onboard/btdump.txt
D=com.kobo.mtk.bluedroid

run() {
    echo
    echo "### $*"
    "$@" 2>&1
}

{
    echo "=== btdump started $(date)"
    run cat /etc/version /mnt/onboard/.kobo/version
    run dbus-send --system --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
        org.freedesktop.DBus.ListNames
    run dbus-send --system --print-reply --dest=$D /org/bluez/hci0 \
        org.freedesktop.DBus.Properties.GetAll string:org.bluez.Adapter1
    run dbus-send --system --print-reply --dest=$D /org/bluez/hci0 \
        org.bluez.Adapter1.StartDiscovery
    echo "(scanning for 25 seconds)"
    sleep 25
    run dbus-send --system --print-reply --dest=$D / \
        org.freedesktop.DBus.ObjectManager.GetManagedObjects
    run dbus-send --system --print-reply --dest=$D /org/bluez/hci0 \
        org.bluez.Adapter1.StopDiscovery
    echo
    echo "### recent Bluetooth log lines"
    (logread 2>/dev/null || dmesg 2>/dev/null) | grep -i -E 'bt|blue|hid|gatt|scan|inquir' | tail -400
    echo
    echo "=== btdump finished $(date)"
} > "$OUT" 2>&1

sync
