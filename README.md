# 60G-radio-cir-fpga

# prerequisites - Install RFSoC-MTS overlay
https://github.com/Xilinx/RFSoC-MTS

# Regenerating the Vivado Project
Unzip cir_sounder.sources.zip.  cd to the folder and 

source cir_sounder.tcl

in Vivado to regenerate the project.

# Wireless connection
Connect a USB Wi-Fi dongle that is supported by RFSoC 4x2. 

sudo wpa_passphrase "SSID_NAME" "YOUR_PASSWORD" | sudo tee /etc/wpa_supplicant.conf

cd /etc/network/interfaces.d

Create a file named wlan0, enter the following and save: 

    auto wlan0
    
    iface wlan0 inet dhcp
    
        wpa-conf /etc/wpa_supplicant.conf

Reboot and RFSoC should connect to Wi-Fi automatically. 
