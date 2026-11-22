#!/bin/sh
# Read-only probe of the Kobo's MediaTek Bluetooth stack (Clara Colour/BW,
# Libra Colour). Looks for config files and any built-in HCI ("btsnoop")
# logging support, so we can tell whether a radio-level log is possible.
#
# It only lists files, reads small config files and searches program files
# for text. It writes nothing except /mnt/onboard/btprobe.txt (plus a temporary
# file list in /tmp that it deletes) and changes no settings.
# Turn Bluetooth ON in Kobo settings before running it.

OUT=/mnt/onboard/btprobe.txt
PAT='snoop|bt_stack|hci_?log|hcilog|btlog|bt_log|trace_level|TRC_|LogLevel|log_level'

run() {
    echo
    echo "### $*"
    "$@" 2>&1
}

{
    echo "=== btprobe started $(date)"
    run cat /mnt/onboard/.kobo/version
    run uname -a
    run mount

    echo
    echo "### Bluetooth processes"
    for name in mtkbtd btservice wmt_launcher wmt_loader; do
        for pid in $(pidof "$name" 2>/dev/null); do
            echo "--- $name pid $pid"
            echo -n "cmdline: "; tr '\0' ' ' < /proc/$pid/cmdline; echo
            echo "cwd: $(readlink /proc/$pid/cwd)"
            echo "exe: $(readlink /proc/$pid/exe)"
            echo "environ:"; tr '\0' '\n' < /proc/$pid/environ
            echo "open files:"; ls -l /proc/$pid/fd 2>&1 | grep -v -E 'socket:|pipe:|anon_inode:'
        done
    done

    for d in /etc/bluetooth /usr/local/Kobo /data /data/misc /data/misc/bluetooth \
             /data/misc/bluedroid /var/lib/bluetooth /var/log /tmp /usr/share/dbus-1/system-services; do
        run ls -la "$d"
    done

    echo
    echo "### files with Bluetooth-related names (system partition, not books)"
    find / \( -path /proc -o -path /sys -o -path /dev -o -path /mnt/onboard -o -path /mnt/sd \) -prune -o \
        \( -iname '*snoop*' -o -iname '*bt*.conf' -o -iname 'bt_*' -o -iname '*bluetooth*' \
           -o -iname '*bluedroid*' -o -iname '*btmw*' -o -iname '*mtkbt*' -o -iname 'libbt*' \) \
        -print 2>/dev/null | head -400 > /tmp/btprobe_files.txt
    cat /tmp/btprobe_files.txt

    echo
    echo "### contents of small Bluetooth config files"
    while read -r f; do
        [ -f "$f" ] || continue
        case "$f" in
            *.conf|*.cfg|*.ini|*.xml|*.sh|*.service|*.txt) ;;
            *) continue ;;
        esac
        size=$(wc -c < "$f")
        [ "$size" -lt 20000 ] || continue
        echo "----- $f ($size bytes)"
        head -n 120 "$f"
    done < /tmp/btprobe_files.txt

    echo
    echo "### logging/snoop-related text inside Bluetooth programs and libraries"
    for f in /usr/bin/btservice /usr/local/Kobo/mtkbtd $(grep -E '\.so' /tmp/btprobe_files.txt); do
        [ -f "$f" ] || continue
        echo "----- $f"
        grep -a -o -i -E "[[:alnum:]_./=%:-]*($PAT)[[:alnum:]_./=%:-]*" "$f" 2>/dev/null | sort -u | head -80
    done

    echo
    echo "### config file paths referenced by Bluetooth programs"
    for f in /usr/bin/btservice /usr/local/Kobo/mtkbtd; do
        [ -f "$f" ] || continue
        echo "----- $f"
        grep -a -o -E '/[[:alnum:]_./-]+\.(conf|cfg|ini|xml|log|cfa|bin)' "$f" 2>/dev/null | sort -u | head -80
    done

    echo
    echo "### log lines mentioning snoop/hci"
    (logread 2>/dev/null || dmesg 2>/dev/null) | grep -i -E 'snoop|hci' | tail -60

    rm -f /tmp/btprobe_files.txt
    echo
    echo "=== btprobe finished $(date)"
} > "$OUT" 2>&1

sync
