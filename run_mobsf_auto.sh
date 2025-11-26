#!/bin/bash

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
    # Real device (WiFi mode)
    echo "[+] Real device detected, reading wlan0..."
    EMULATOR_HOST=$(adb shell ip -o -4 addr show wlan0 | awk '{print $4}' | cut -d/ -f1)
    EMULATOR_PORT="5555"
fi

DOCKER_HOST="$EMULATOR_HOST:$EMULATOR_PORT"

echo "[+] Emulator Host: $EMULATOR_HOST"
echo "[+] Emulator Port: $EMULATOR_PORT"
echo "[+] Docker-accessible device address: $DOCKER_HOST"

# --- Prepare config.py ---
CONFIG_DIR=~/mobsf_config
CONFIG_FILE="$CONFIG_DIR/config.py"

mkdir -p "$CONFIG_DIR"

# Create or overwrite config.py
cat > "$CONFIG_FILE" <<EOL
# Auto-generated MobSF config
MOBSF_ANALYZER_IDENTIFIER = "$DOCKER_HOST"
EOL

echo "[+] config.py created at $CONFIG_FILE with MOBSF_ANALYZER_IDENTIFIER=$DOCKER_HOST"

# --- Stop old MobSF ---
echo "[+] Removing old MobSF container (if exists)..."
docker rm -f mobsf >/dev/null 2>&1

# --- Start MobSF with only config.py mounted ---
echo "[+] Starting MobSF container..."
docker run -d \
  --name mobsf \
  -p 8000:8000 \
  -v "$CONFIG_FILE":/home/mobsf/.MobSF/config.py \
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
