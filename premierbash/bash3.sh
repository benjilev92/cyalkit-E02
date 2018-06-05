#!/bin/bash
#Launch this bash using "bash bash.sh"

# AUTHOR: BENJAMIN LEVY
# CONTACT: BENJAMINLEVYPRO@GMAIL.COM OR GITHUB
# RELEASE DATE: 28TH MAY 2018
# YOU CAN RE-USE THIS FILE BUT DON'T FORGET TO LINK
# THE FOLLOWING WEBSITE AND THE AUTHOR
# https://github.com/benjilev92

#-----------------------------------------------
#------------------ PURPOSE --------------------
#-----------------------------------------------
#- This code is doing those steps to get cypress 
#- CYALKIT-E02 informations
#- if you don't want any debuging information 
#- make sure you called the .sh as following
#- bash bash.sh 1 1

#-----------------------------------------------
#------------------- STEPS ---------------------
#-----------------------------------------------
#- In order to access the results of the bluetoothctl command, 
#- we create a session with tmux to access to it via a file in run/shm/ called BLUETOOTH_OUTPUT
	#1. Test if server are running, if there are some, we kill them
	#2. Test if reseting HCI0 works
	#3. Test if putting HCI0 down works
	#4. Test if putting HCI0 up works
	#5. Create new tmux session
	#6. Scan all bluetooth devices
	#7. Checking MAC address device info
	#8. Sending command scan off
	#9. Killing created server
	#10.Show the result

#-----------------------------------------------
#---------------- ERROR CODES ------------------
#-----------------------------------------------
#- 1 : HCI0 reseting failed
#- 2 : Failed creating new session


#-----------------------------------------------
#- This next address is the MAC of your device -
#-----------------------------------------------

#- To know your device address run the following
#- commands in a first terminal to make sure ---
#- your device can be seen by your computer ----
#- $bluetoothctl -------------------------------
#- [bluetooth] scan on -------------------------
#- ---------------------------------------------
#- Now open a second terminal and execute ------
#- the following command -----------------------
#- $sudo btmon ---------------------------------
#- ---------------------------------------------
#- Now you see devices, check your's address ---
#- and replace the one following ---------------
#- ---------------------------------------------

Address=00:A0:50:29:34:D5

#-----------------------------------------------
#------------- OTHER INFORMATION ---------------
#-----------------------------------------------
#- this following command is here to remove ----
#- debugging "echo" if you use 1 parameter on --
#- calling the bash script ---------------------
#- if [ -z "$1" ];	 then 
#- fi
#- ---------------------------------------------
#- Using the second parameter remove the part --
#- where we delete the server ------------------
#- ---------------------------------------------

#-----------------------------------------------
#------- test if server is running -------------
#-----------------------------------------------

if [ -z "$1" ];	 then echo "1. Checking running servers..." 
fi

#If we want to delete the running server even if 
#we are supposed to delete them at the end
if [ -z "$2" ];	 then Server=$(tmux ls) 2>/dev/null
	if [ "$Server" = "" ]; then
		if [ -z "$1" ];	 then echo "No server running."
		fi
	else
		if [ -z "$1" ];	 then echo "Running server detected\nTmux is killing server."
		fi
		tmux kill-server
		Server=$(tmux ls) 2>/dev/null
		if [ -z "$1" ];	 then echo "No server running anymore."
		fi
	fi
fi
#------------------------------------------------
#------- Test if reseting HCI0 works ------------
#------------------------------------------------
if [ -z "$1" ];	 then echo "2. Reseting HCI0..."
fi
Reset=$(sudo hciconfig hci0 reset) 2>/dev/null
if [ "$Reset" = "" ]; then
	if [ -z "$1" ];	 then echo "HCI0 reseted"
	fi
else
	if [ -z "$1" ];	 then echo "Please check HCI config for reset, problem occured\nExiting ..."
	fi
	exit 1
fi

#------------------------------------------------
#------ Test if putting HCI0 down works ---------
#------------------------------------------------
if [ -z "$1" ];	 then echo "3. Putting HCI0 down..."
fi
sudo hciconfig hci0 down
StatusDown=$(sudo hciconfig status | sed -n 3p) 2>/dev/null
if [ -z "$1" ];	 then echo "Status is $StatusDown.		If not wanted please check HCI config" 
fi

#------------------------------------------------
#------ Test if putting HCI0 up works -----------
#------------------------------------------------
if [ -z "$1" ];	 then echo "4. Putting HCI0 up..."
sudo hciconfig hci0 up
fi
StatusUp=$(sudo hciconfig status | sed -n 3p) 2>/dev/null
if [ -z "$1" ];	 then echo "Status is $StatusUp.	If not wanted please check HCI config" 
fi

#------------------------------------------------
#------ Creating new tmux session ---------------
#------------------------------------------------
if [ -z "$1" ];	 then echo "5. Creating new session with tmux for bluetoothctl."
fi
Server=$(tmux new-session -d -s ServerFault 'sudo bluetoothctl -a |& tee /run/shm/BLUETOOTH_OUTPUT') 2>/dev/null
if [ "$Server" = "" ]; then
	if [ -z "$1" ];	 then echo "Server running."
	fi
else
	if [ -z "$1" ];	 then echo "Failed to create server\nExiting ..."
	fi
	sleep 1
	exit 2
fi


#------------------------------------------------
#------- Scan all bluetooth devices -------------
#------------------------------------------------
if [ -z "$1" ];	 then echo "6.sending command scan for devices to the created tmux server."
fi
ScanCommand=$(tmux send-keys -t ServerFault "scan on" Enter) 2>/dev/null
if [ -z "$1" ];	 then echo "Five second sleep for scanning devices"
fi
sleep 5


#------------------------------------------------
#---- Checking MAC address device info  ---------
#------------------------------------------------
if [ -z "$1" ];	 then echo "7. Asking for $Address info."
fi
DeviceInfo=$(tmux send-keys -t ServerFault "info $Address" Enter) 2>/dev/null


#------------------------------------------------
#-------- Sending command scan off  -------------
#------------------------------------------------
if [ -z "$1" ];	 then echo "8. sending command scan off"
fi
tmux send-keys -t ServerFault "scan off" Enter
tmux send-keys -t ServerFault "exit" Enter


#------------------------------------------------
#-------- Killing created server ----------------
#------------------------------------------------
if [ -z "$1" ];	 then echo "9. killing server."
fi
tmux kill-server



#------------------------------------------------
#-------- Extracting device information ---------
#------------------------------------------------
cp /run/shm/BLUETOOTH_OUTPUT ./BLUETOOTH_OUTPUT.txt

#two next lines are here to exctract the wanted text between "info" and "scan off"
echo /run/shm/BLUETOOTH_OUTPUT | sed -e/info/\{ -e:1 -en\;b1 -e\} -ed /run/shm/BLUETOOTH_OUTPUT > BLUETOOTH_OUTPUT.txt
echo BLUETOOTH_OUTPUT.txt | sed '/scan off/q;' ./BLUETOOTH_OUTPUT.txt > ./INFO_DEVICE.txt

#the next line save the two wanted lines : Humidity and Temperature
sed -e '1,30d' < ./INFO_DEVICE.txt > ./TREATED_INFO.txt 
Info=$(sed -e '3,4d' < ./TREATED_INFO.txt) # > ./FINAL_INFO.txt

if [ -z "$1" ];	 then 
	echo ------------------------------------------
	echo ---------- DETECTED INFORMATION ----------
	echo ------------------------------------------
fi

#Number in base 16
Hum16=${Info:27:2}
Tem16=${Info:57:2}
#Number in base 10
Hum10=$((16#$Hum16))
Tem10=$((16#$Tem16))

if [ -z "$1" ];	 then echo Calculation ...
fi


#RESULTS ARE MADE FROM CYPRESS DATASHEETS
Humi=$(( 125 * ( $Hum10 * 256 ) / 65536 - 6))
Temp=$(echo "175.72 * ( $Tem10 *256 ) / 65536 - 46.85" | bc) # BC  for decimal numbers





#------------------------------------------------
#---------------- DISPLAY PART ------------------
#------------------------------------------------
echo Humidity: $Humi
echo Temperature: $Temp




 


#saved lines
#Info=$(cat ./INFO_DEVICE.txt | awk -v n=2 '/ManufacturerData Value: 0xbe/ && !--n {for(i=0;i<2;i++){getline; print}}')