# AutoMobSF

[MobSF]

[AutoMobSF](https://github.com/MrPWH/AutoMobSF) is an **automatic script** to run [Mobile Security Framework (MobSF)](https://github.com/MobSF/Mobile-Security-Framework-MobSF) in **Docker** on macOS and automatically connect a running Android emulator (Genymotion, AVD, BlueStacks, LDPlayer) for **dynamic analysis**.

The script detects the emulator/device, sets the proper `ANALYZER_IDENTIFIER`, and runs MobSF in background with persistent storage.

---

## Features

- Automatic detection of Android emulator or real device
- Detects device IP and ADB port
- Connects MobSF Docker container to emulator
- Automatically sets `MOBSF_ANALYZER_IDENTIFIER`
- Runs MobSF in **background** with **persistent storage**
- Works with Genymotion, AVD, BlueStacks, LDPlayer on macOS
- Easy to use: one command to start everything

---

## Requirements

- macOS
- Docker
- adb (Android Platform Tools)
- Android emulator running (Genymotion, AVD, or other)
- Optional: Persistent storage folder (`~/mobsf_data`)

---

## Installation

1. Clone this repository:

```bash
brew install android-platform-tools #Example genimotion
git clone https://github.com/MrPWH/AutoMobSF.git
cd AutoMobSF
chmod +x run_mobsf_auto.sh
mkdir -p ~/mobsf_data
./run_mobsf_auto.sh
