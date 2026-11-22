# Changelog: getting the 3-key remote to pair with a Kobo Clara Colour

Symptom: the board pairs and works on Android and on a PC, but the Kobo Clara
Colour doesn't register it.

## Current approach (Claude)

Back to **stock upstream ZMK v0.3** plus one small patch, applied during the CI
build (`zmk-patches/`, step "Apply ZMK patches" in `.github/workflows/build.yml`).
This replaces the `boothy13/zmk` fork (`kobo-remote-hid` branch).

What changed and why:

1. **Allow BLE legacy pairing** (`zmk-patches/0001-ble-allow-legacy-pairing.patch`
   and `CONFIG_ZMK_BLE_ALLOW_LEGACY_PAIRING=y`). Stock ZMK hard-selects
   `BT_SMP_SC_PAIR_ONLY`, so it refuses any host that can't do *LE Secure
   Connections* pairing. You can't turn that off from a `.conf` file. Phones and
   PCs support Secure Connections, which would explain why they work. The Clara
   Colour uses a MediaTek Bluetooth stack that Kobo customised. A known-working
   DIY Kobo remote (ESP32 / Bluedroid, Just Works) does not require Secure
   Connections. Copilot never tested this difference. Hosts that support Secure
   Connections still use it.
   The cost: legacy Just Works pairing is easier to eavesdrop on *during
   pairing*. That is fine for a page turner, but don't type passwords on it.
2. **`CONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y`**: ZMK's documented fix for hosts
   with connection problems. It turns off the 2M PHY and uses conservative
   connection parameters.
3. **A Bluetooth profile switch combo** (middle + right key = `BT_NXT`). ZMK
   *rejects pairing on a profile that is already bonded*, and it stops
   advertising while the active profile is connected. Before this change the
   keymap couldn't switch profiles. So if the phone or PC owned profile 0, the
   Kobo could never pair unless you cleared it first.
4. Undid the speculative changes: the "Chromecast remote" name, the limited
   discovery timeout, sleep turned off, and TX power. Advertising is stock ZMK
   again, with the name in the primary advertising packet.
5. Removed `kobo_remote_hid_patch.diff`. Nothing ever applied it, and it doesn't
   match the code.

### How to test
1. Flash `nice_nano_settings_reset` once, to wipe old bonds. Then flash
   `mini_keyboard_with_studio`.
2. On the Kobo, forget any old entry for the remote. Turn Bluetooth off and on.
3. Press **middle + right** once to move to an empty profile. Your phone or PC
   stays on the first profile.
4. On the Kobo, open Settings → Bluetooth, scan, and pick **Page Turner**.
5. The keys send Left / Enter / Right. Kobo turns pages on arrow keys.

## Findings from the Kobo itself (kobo-bt-dump, 22 Nov 2026)

- Kobo software 4.46.23852. Bluetooth runs on Kobo's MediaTek service
  (`com.kobo.mtk.bluedroid`), not BlueZ.
- Nickel scans with `Transport=auto, RSSI=-90`. The service picks up about
  20 nearby devices, both classic Bluetooth and Low Energy (LE). That includes
  LE devices with random static addresses (`C3:`, `D4:`, `D8:`).
- **The 3-key board (C8:ED:3A:21:78:D3) never shows up, not even in the raw
  results.** We checked this while nRF Connect on a phone showed it
  advertising.
- The Xbox controller, which the Kobo *does* list, is classic Bluetooth.
  It has Class 0x508 (peripheral/gamepad) and Icon "input-gaming".
  Every LE device comes through as Class 0x1F00 (uncategorised) with
  Appearance 0. Nickel's list was empty while only those devices were found,
  so Nickel probably also filters on class or icon. That will matter once the
  board is actually received.
- ZMK v0.3 **hardcodes** the advertised appearance (0x03C1, keyboard).
  So none of the earlier `CONFIG_BT_DEVICE_APPEARANCE` changes ever reached
  the radio.

### Discovery experiments
`zmk-patches/0002-ble-configurable-advertising-data.patch` makes each part of
the advertisement optional. `build.yaml` builds one test firmware per change:

| Firmware | Advertisement |
|---|---|
| `mini_keyboard_with_studio` | appearance + flags + HID/Battery UUIDs + name (stock) |
| `kobo_test_A_bare_name_only` | flags + name only |
| `kobo_test_B_no_appearance` | flags + UUIDs + name |
| `kobo_test_C_no_service_uuids` | appearance + flags + name |
| `kobo_test_D_name_in_scan_response` | stock, but the name is in the scan response |

## What Copilot tried before (all unsuccessful)

Rebuilt from git history. None of these touched pairing security.

### This repo, Sept to Oct 2026
- Added and then removed `boot-protocol` in the overlay.
- Added Bluetooth SMP / signing configs, then removed them.
- Renamed the device: "mini" → "Kobo Remote" → "Chromecast remote" →
  "Chromecast" → "Chromecast remote" (with `BT_DEVICE_NAME_MAX=24`).
- Changed `BT_DEVICE_APPEARANCE`: 832 → 964 (gamepad) → 971 → 384 (generic
  remote) → 961 (keyboard).
- Changed the keymap from media keys (prev / play / next) to Left / Enter /
  Right.
- Turned off the TX power boost and deep sleep "for diagnosis".
- Added `BT_LIM_ADV_TIMEOUT=180`. ZMK doesn't use limited advertising, so this
  had no effect.
- Pointed `west.yml` at the `boothy13/zmk` fork, `kobo-remote-hid` branch.

### `boothy13/zmk` fork
- PR #1 / #2, merged to the fork's `main`: tried consumer-only, gamepad, and
  then keyboard-only HID report maps. Removed the consumer report from HOGP.
  Re-enabled the HIDS Protocol Mode characteristic. Advertised a complete
  UUID16 list.
- `kobo-remote-hid` branch: moved the name to the scan response, so it was no
  longer in the advertising packet. Switched to the *limited* discoverable flag.
  Added a TX power AD field and Google's manufacturer ID (0x00E0) to copy a
  Chromecast remote. Added an external report reference to Battery Level.
