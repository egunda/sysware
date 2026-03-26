#!/usr/bin/env bash
set -euo pipefail

LOG="/tmp/fix-atmos.log"
exec > >(tee -a "$LOG") 2>&1

echo "==== Atmos Recovery Script ===="
date

# --- STEP 0: Context ---
echo "[INFO] Checking HDMI device state..."
APLAY_OUT=$(aplay -l || true)

if echo "$APLAY_OUT" | grep -q "DENON-AVR"; then
    echo "[OK] DENON AVR detected"
else
    echo "[WARN] DENON AVR not detected in aplay -l"
fi

BUSY=$(echo "$APLAY_OUT" | grep -A2 "DENON-AVR" | grep "Subdevices" || true)
echo "[INFO] HDMI state: $BUSY"

# --- STEP 1: Check if PipeWire/Pulse is active ---
echo "[INFO] Checking audio daemon status..."
if pactl info >/dev/null 2>&1; then
    echo "[WARN] PipeWire/Pulse is ACTIVE"
    PIPE_ACTIVE=1
else
    echo "[OK] No active Pulse/PipeWire"
    PIPE_ACTIVE=0
fi

# --- STEP 2: Stop audio stack if active ---
if [[ "$PIPE_ACTIVE" -eq 1 ]]; then
    echo "[ACTION] Stopping PipeWire stack..."

    systemctl --user stop pipewire.socket pipewire.service 2>/dev/null || true
    systemctl --user stop pipewire-pulse.socket pipewire-pulse.service 2>/dev/null || true
    systemctl --user stop wireplumber.service 2>/dev/null || true

    echo "[ACTION] Masking services to prevent respawn..."
    systemctl --user mask pipewire pipewire-pulse wireplumber 2>/dev/null || true

    echo "[ACTION] Killing residual processes..."
    killall pipewire wireplumber pulseaudio 2>/dev/null || true

    sleep 1
else
    echo "[INFO] Skipping daemon stop (already inactive)"
fi

# --- STEP 3: Verify shutdown ---
echo "[INFO] Verifying Pulse/PipeWire shutdown..."
if pactl info >/dev/null 2>&1; then
    echo "[ERROR] PipeWire still running. Abort."
    exit 1
else
    echo "[OK] Audio daemons fully stopped"
fi

# --- STEP 4: Verify HDMI release ---
echo "[INFO] Re-checking HDMI device..."
APLAY_OUT=$(aplay -l || true)
BUSY=$(echo "$APLAY_OUT" | grep -A2 "DENON-AVR" | grep "Subdevices" || true)
echo "[INFO] HDMI state after cleanup: $BUSY"

if echo "$BUSY" | grep -q "1/1"; then
    echo "[OK] HDMI device is FREE"
else
    echo "[ERROR] HDMI still busy. Investigate:"
    echo "Run: lsof /dev/snd/*"
    exit 2
fi

# --- STEP 5: Optional Kodi launch ---
read -p "Launch Kodi now? (y/n): " LAUNCH
if [[ "$LAUNCH" == "y" || "$LAUNCH" == "Y" ]]; then
    echo "[ACTION] Launching Kodi..."
    exec kodi
else
    echo "[INFO] Skipping Kodi launch"
fi

echo "==== DONE ===="
