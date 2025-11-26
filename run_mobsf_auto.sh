#!/bin/bash

echo "==========================================="
echo "  MobSF Auto Detector & Docker Runner"
echo "==========================================="

# --- Detect ADB Path ---
ADB=$(which adb)
if [[ -z "$ADB" ]]; then
    echo "[!] adb not found! Install platform-tools first."
    exit 1
fi

echo "[+] Using ADB: $ADB"

# --- Detect running emulator/device ---
echo "[+] Detecting Android emulator/device..."

DEV_LINE=$(adb devices | grep -w "device" | grep -v "List" | head -n 1)

if [[ -z "$DEV_LINE" ]]; then
    echo "[!] No Android emulator/device detected!"
    exit 1
fi

DEVICE_ID=$(echo "$DEV_LINE" | awk '{print $1}')
echo "[+] Detected device: $DEVICE_ID"

# --- Extract host IP & port ---
if [[ "$DEVICE_ID" == *":"* ]]; then
    # Emulator (127.0.0.1:port)
    EMULATOR_HOST=$(echo "$DEVICE_ID" | cut -d: -f1)
    EMULATOR_PORT=$(echo "$DEVICE_ID" | cut -d: -f2)
else
    # Real device (in WiFi mode)
    echo "[+] Real device detected, reading wlan0..."
    EMULATOR_HOST=$(adb shell ip -o -4 addr show wlan0 | awk '{print $4}' | cut -d/ -f1)
    EMULATOR_PORT="5555"
fi

echo "[+] Emulator Host: $EMULATOR_HOST"
echo "[+] Emulator Port: $EMULATOR_PORT"

# Fix for Docker internal networking
DOCKER_HOST="host.docker.internal:$EMULATOR_PORT"
echo "[+] Docker-accessible device address: $DOCKER_HOST"

# --- Stop old MobSF ---
echo "[+] Removing old MobSF container (if exists)..."
docker rm -f mobsf >/dev/null 2>&1

# --- Start MobSF ---
echo "[+] Starting MobSF with ANALYZER_IDENTIFIER=$DOCKER_HOST"

docker run -d \
  --name mobsf \
  -p 8000:8000 \
  -v ~/mobsf_data:/home/mobsf/.MobSF \
  -e MOBSF_ANALYZER_IDENTIFIER="$DOCKER_HOST" \
  opensecurity/mobile-security-framework-mobsf

sleep 4

# --- Connect ADB inside Docker ---
echo "[+] Connecting emulator inside MobSF container..."

docker exec mobsf adb connect "$DOCKER_HOST"

echo "[+] Checking devices inside container:"
docker exec mobsf adb devices

echo "==========================================="
echo "   MobSF is running at http://localhost:8000"
echo "   Device available inside Docker as $DOCKER_HOST"
echo "==========================================="
