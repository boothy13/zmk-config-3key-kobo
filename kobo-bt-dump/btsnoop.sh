#!/bin/sh
# Turn the Kobo's built-in Bluetooth HCI ("btsnoop") log on or off, and copy
# the log to the USB drive. For Kobo MediaTek models (Clara Colour etc.).
#
#   btsnoop.sh on       back up bt_stack.conf, enable logging to /tmp
#   btsnoop.sh collect  copy the log to the Kobo drive as btsnoop_hci.log
#   btsnoop.sh off      restore the original bt_stack.conf, delete the log
#
# The only system file touched is /etc/bluetooth/bt_stack.conf, and only its
# two BtSnoop lines. The original is kept as bt_stack.conf.before-btsnoop
# (and copied to the Kobo drive) until "off" puts it back. Settings are read
# when the Bluetooth service starts, so reboot after "on" and "off".

CONF=/etc/bluetooth/bt_stack.conf
BAK=/etc/bluetooth/bt_stack.conf.before-btsnoop
LOG=/tmp/btsnoop_hci.log
STATUS=/mnt/onboard/btsnoop_status.txt

say() { echo "$*" >> "$STATUS"; }

: > "$STATUS"
say "=== btsnoop $1 $(date)"

case "$1" in
on)
    if [ ! -f "$BAK" ]; then
        cp -p "$CONF" "$BAK" || { say "FAILED: could not back up $CONF"; exit 1; }
    fi
    cp "$BAK" /mnt/onboard/bt_stack.conf.backup
    sed -e 's|^BtSnoopLogOutput=.*|BtSnoopLogOutput=true|' \
        -e "s|^BtSnoopFileName=.*|BtSnoopFileName=$LOG|" \
        "$BAK" > /tmp/bt_stack.conf.new
    # Only install the new file if exactly the two intended lines changed.
    if grep -q '^BtSnoopLogOutput=true$' /tmp/bt_stack.conf.new &&
       grep -q "^BtSnoopFileName=$LOG\$" /tmp/bt_stack.conf.new &&
       [ "$(wc -l < /tmp/bt_stack.conf.new)" -eq "$(wc -l < "$BAK")" ] &&
       [ "$(grep -v -E '^BtSnoop(LogOutput|FileName)=' "$BAK" | md5sum)" = \
         "$(grep -v -E '^BtSnoop(LogOutput|FileName)=' /tmp/bt_stack.conf.new | md5sum)" ]; then
        cat /tmp/bt_stack.conf.new > "$CONF"   # keeps owner and permissions
        rm -f /tmp/bt_stack.conf.new
        say "OK: logging enabled. Reboot, then turn Bluetooth on."
    else
        rm -f /tmp/bt_stack.conf.new
        say "FAILED: unexpected result, nothing changed."
        grep '^BtSnoop' "$CONF" >> "$STATUS" 2>&1
        sync
        exit 1
    fi
    ;;
collect)
    ls -la /tmp/btsnoop* >> "$STATUS" 2>&1
    if [ -f "$LOG" ]; then
        cp "$LOG" /mnt/onboard/btsnoop_hci.log && say "OK: copied to btsnoop_hci.log"
    else
        say "No log found at $LOG"
    fi
    ;;
off)
    if [ -f "$BAK" ]; then
        cat "$BAK" > "$CONF" && rm -f "$BAK" && say "OK: original settings restored. Reboot."
    else
        say "Nothing to restore (no backup found)."
    fi
    rm -f /tmp/btsnoop_hci.log*
    ;;
*)
    say "usage: btsnoop.sh on|collect|off"
    ;;
esac

say "--- current BtSnoop settings:"
grep '^BtSnoop' "$CONF" >> "$STATUS" 2>&1
sync
