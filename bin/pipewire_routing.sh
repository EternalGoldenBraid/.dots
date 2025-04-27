#!/bin/bash

# Disconnect everything first (to avoid duplicates)
pw-link -d "REAPER:out1" "alsa_output.usb-Focusrite_Scarlett_Solo_USB-00.pro-output-0:playback_AUX0"
pw-link -d "REAPER:out2" "alsa_output.usb-Focusrite_Scarlett_Solo_USB-00.pro-output-0:playback_AUX1"
pw-link -d "REAPER:out1" "alsa_output.usb-Solid_State_System_Co._Ltd._SPDIF_Device_24BIT_ALL_____000000000000-00.analog-stereo:playback_FL"
pw-link -d "REAPER:out2" "alsa_output.usb-Solid_State_System_Co._Ltd._SPDIF_Device_24BIT_ALL_____000000000000-00.analog-stereo:playback_FR"
pw-link -d "alsa_input.usb-Focusrite_Scarlett_Solo_USB-00.pro-input-0:capture_AUX0" "PulseAudio Volume Control:input_FL"
pw-link -d "alsa_input.usb-Focusrite_Scarlett_Solo_USB-00.pro-input-0:capture_AUX1" "PulseAudio Volume Control:input_FR"

# Reconnect cleanly
pw-link "alsa_input.usb-Focusrite_Scarlett_Solo_USB-00.pro-input-0:capture_AUX0" "REAPER:in1"
pw-link "alsa_input.usb-Focusrite_Scarlett_Solo_USB-00.pro-input-0:capture_AUX1" "REAPER:in2"

pw-link "alsa_input.usb-Focusrite_Scarlett_Solo_USB-00.pro-input-0:capture_AUX0" "PulseAudio Volume Control:input_FL"
pw-link "alsa_input.usb-Focusrite_Scarlett_Solo_USB-00.pro-input-0:capture_AUX1" "PulseAudio Volume Control:input_FR"

pw-link "REAPER:out1" "alsa_output.usb-Focusrite_Scarlett_Solo_USB-00.pro-output-0:playback_AUX0"
pw-link "REAPER:out2" "alsa_output.usb-Focusrite_Scarlett_Solo_USB-00.pro-output-0:playback_AUX1"

pw-link "REAPER:out1" "alsa_output.usb-Solid_State_System_Co._Ltd._SPDIF_Device_24BIT_ALL_____000000000000-00.analog-stereo:playback_FL"
pw-link "REAPER:out2" "alsa_output.usb-Solid_State_System_Co._Ltd._SPDIF_Device_24BIT_ALL_____000000000000-00.analog-stereo:playback_FR"
