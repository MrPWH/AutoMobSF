#!/bin/bash

echo "[+] Detecting Android emulator/device..."
DEV_LINE=$(adb devices | grep -w "device" | grep -v "List" | head -n 1)

if [[ -z "$DEV_LINE" ]]; then
    echo "[!] No Android emulator/device detected!"
    exit 1
fi

DEVICE_ID=$(echo "$DEV_LINE" | awk '{print $1}')
echo "[+] Detected device: $DEVICE_ID"

if [[ "$DEVICE_ID" == *":"* ]]; then
    EMULATOR_HOST=$(echo "$DEVICE_ID" | cut -d: -f1)
    EMULATOR_PORT=$(echo "$DEVICE_ID" | cut -d: -f2)
else
    echo "[+] Real device detected, reading wlan0 IP..."
    EMULATOR_HOST=$(adb shell ip -o -4 addr show wlan0 | awk '{print $4}' | cut -d/ -f1)
    EMULATOR_PORT="5555"
fi

DOCKER_HOST="$EMULATOR_HOST:$EMULATOR_PORT"
echo "[+] Device/Emulator address: $DOCKER_HOST"

# --- Stop old MobSF ---
docker rm -f mobsf >/dev/null 2>&1

# --- Start MobSF normally ---
docker run -d \
  --name mobsf \
  -p 8000:8000 \
  opensecurity/mobile-security-framework-mobsf

sleep 4

# --- Update ANALYZER_IDENTIFIER inside container ---
echo "[+] Updating ANALYZER_IDENTIFIER inside container config..."

docker exec mobsf bash -c "sed -i.bak '/ANALYZER_IDENTIFIER/c\ANALYZER_IDENTIFIER = \"$DOCKER_HOST\"' /home/mobsf/.MobSF/config.py"

echo "[+] Updated /home/mobsf/.MobSF/config.py successfully."

# --- Connect ADB inside container ---
docker exec mobsf adb connect "$DOCKER_HOST"

echo "[+] Devices inside container:"
docker exec mobsf adb devices

echo "==========================================="
echo "   MobSF is running at http://localhost:8000"
echo "   Device available inside Docker as $DOCKER_HOST"
echo "==========================================="
