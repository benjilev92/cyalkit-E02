#!/bin/bash
#Launch this bash using "bash bash.sh"

# AUTHOR: BENJAMIN LEVY
# CONTACT : BENJAMINLEVYPRO@GMAIL.COM OR GITHUB BENJILEV92
# RELEASE DATE: 30/05/2018
# YOU CAN RE-USE THIS FILE BUT DON'T FORGET TO LINK
# THE FOLLOWING WEBSITE AND THE AUTHOR
# https://github.com/benjilev92

#-----------------------------------------------
#------------------ PURPOSE --------------------
#-----------------------------------------------
#- This code is doing those steps to get cypress 
#- CYALKIT-E02 informations.

#-----------------------------------------------
#------------------- HOW TO --------------------
#-----------------------------------------------
#- Make sure you called the script after knowing
#- the CYPRESS CYALKIT-E02 mac address (you can
#- see it with sudo hcitool lescan --duplicates
#- it will be like: 00:A0:50:XX:XX:XX
#- To call it do as following: bash bash.sh x y 
#- where X is the number of itteration (to have
#- an average at the end) and Y is the time to 
#- wait until having thefirst information from 
#- the devices dependingon the lights next to it 
#- (less light, biggernumber) for example : 
#- bash bash.sh 5 6

#-----------------------------------------------
#------------------ WARNING --------------------
#-----------------------------------------------
#- For now it is possible to have some errors
#- this is because the bluetooth device is not 
#- advertising constantly, in that case, your 
#- average at the end won't be correct, moreover
#- this is why there is the 'y' value, in order
#- to scan during enough time to get information
#- remember that if there is no light, your BLE
#- device won't advertise.


#-----------------------------------------------
#------------------- STEPS ---------------------
#-----------------------------------------------
#- In order to access the results of the 
#- bluetoothctl command we create a session with
#- tmux to launch an AIOBLESCAN (C) with a 
#- specific mac address (-m)
#- We will do the following steps X times (see purpose)
#	1. Kill tmux servers and redirect the output in ./DOC/OUTPUT_REDIRECT
#	2. Create new tmux session with aioblescan getting information
#	3. Leave and kills server after Y seconds
#	4. Save data in different files/variables to extract the good informations
#	5. Print real-time infomation
#	6. Calculate the averages
#	7. Print the final averages

#MAC ADDRESS (For you to store)
#00:A0:50:XX:XX:XX
#00:A0:50:XX:XX:XX
#00:A0:50:XX:XX:XX

#----------------------- INIT ----------------------------
AVRSSI=0
AVHUMI=0
AVTEMP=0.0

#--------------------- BEGINNING -------------------------
for ((j= 1; j <= $1; j++))
do

#----------------------- STEP 1 --------------------------
    sudo tmux kill-server >./DOC/OUTPUT_REDIRECT 2>&1

#----------------------- STEP 2 --------------------------    
    tmux new-session -d -s ServerFault 'sudo python3.5 -m aioblescan -m 00:A0:50:17:1F:1D > ./DOC/TEXT' 
    
#----------------------- STEP 3 --------------------------
    for ((i = $2; i>=1; i--))
    do
        sleep 1
        #printf $i 
    done
    tmux send-keys -t ServerFault "^C" Enter
    tmux kill-server

#----------------------- STEP 4 --------------------------
    echo ./DOC/TEXT | sed -e/Payload/\{ -e:1 -en\;b1 -e\} -ed ./DOC/TEXT > ./DOC/BLUETOOTH_OUTPUT
    echo ./DOC/BLUETOOTH_OUTPUT | sed '/rssi/d' ./DOC/BLUETOOTH_OUTPUT > ./DOC/INFO_DEVICE
    Data=$(sed '2q;d' ./DOC/INFO_DEVICE)
    RSSI=$(sed '4q;d' ./DOC/BLUETOOTH_OUTPUT)
    RSSI=$(echo "$RSSI" | sed 's/\ //g')
    UUID=${Data:28:47}
    UUID=$(echo "$UUID" | sed 's/\://g')
    UUID=${UUID:0:7}-${UUID:8:4}-${UUID:12:4}-${UUID:16:4}-${UUID:20}
    Major=${Data:76:5}
    Major=$(echo "$Major" | sed 's/\://g')
    Hum16=${Data:82:2}
    Tem16=${Data:85:2}
    Hum10=$((16#$Hum16))
    Tem10=$((16#$Tem16))
    Humi=$(( 125 * ( $Hum10 * 256 ) / 65536 - 6))
    Temp=$(echo "175.72 * ( $Tem10 *256 ) / 65536 - 46.85" | bc)
    Temp=${Temp:0:2}
    AVRSSI=$(echo "$AVRSSI+$RSSI" | bc)
    AVHUMI=$(echo "$AVHUMI+$Humi" | bc)
    AVTEMP=$(echo "$AVTEMP+$Temp" | bc)
    
#----------------------- STEP 5 --------------------------
    if (( $j==1 )); then
	echo -----------------------------------------------------
	echo ------------------- Device info ---------------------
	echo -----------------------------------------------------
	echo -e "UUID\t\t: $UUID"
	echo -e "Major\t\t: $Major"
	echo
    fi
    echo --------------------------
    echo ----- Device data $j ------
    echo --------------------------
    echo -e "RSSI\t\t: $RSSI"
    echo -e "Humidity\t: $Humi%"
    echo -e "Temperature\t: $Temp°C"

#----------------------- END FOR --------------------------
done


#----------------------- STEP 6 --------------------------
AVRSSI=$((AVRSSI/$1))
AVHUMI=$((AVHUMI/$1))
AVTEMP=$(echo "$AVTEMP/$1" | bc)

#----------------------- STEP 7 --------------------------
echo 
echo
echo "On a $1 time test the averages are:"
echo -e "Average RSSI: \t\t$AVRSSI"
echo -e "Average Humidity: \t$AVHUMI%"
echo -e "Average Temperature: \t$AVTEMP°C"
echo
echo