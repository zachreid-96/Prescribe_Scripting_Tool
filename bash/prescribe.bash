#!/bin/bash

# Enables nullglob to avoid issues with uninitialized variables
shopt -s nullglob

# Color options (format like this \033[0;31m) replace x;xxm bit
# 0;31m - Red, 0;32m - Green, 0;33 - Yellow, 0;34 - Blue, 0;35 - Magenta, 0;36 - Cyan, 0;37 - White
# 1;30 - Gray, 1;31 - Bright Red, 1;32 - Bright Green, 1'33 - Bright Yellow, 1;34 - Bright Blue
# 1;35 - Bright Magenta, 1;36 - Bright Cyan, 1;37 - Bright White

echo -ne "\033[1;36m"
echo -ne "\033]0;Kyocera Prescribe Command\007"

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Gets the IP address from the user. Specifically the IP of the copier/printer
# If no input is entered, the pre-programmed error list will be displayed and exit intentionally
# Will then call split_ip
# NO RETURNS
get_ip() {

	passed_ip="$1"
	passed_command="$2"

	if [[ -n "$passed_ip" ]]; then
		ping_ip "$passed_ip" "passed_command"
	fi

	echo "Please enter Copier IP in the following format: 10.120.1.68"
	echo "Or press enter to display error list"
	echo

	read -r -p "Enter IP Address: " ip
	echo

	if [[ -z "$declared_ip" ]]; then
		error_list
	else
		split_ip "$declared_ip" "$passed_command"
	fi
}

# Passed args
# 	$1 = arg to check if a valid number
# Helper function to check if all chars in passed arg are valid numbers
# Returns:
# 	True (0) if $1 (passed arg) is valid number (40)
# 	False (1) if $1 is not a valid number (4O)
is_valid_number() {
	if [[ "$1" =~ ^[0-9]+$ ]]; then
		return 0
	else
		return 1
	fi
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Splits IP into octets and checks each octet to see if it is valid
# Will call pre-programmed error states if a flag is thrown, like too many or few octets or an invalid number
# Will then call ping_ip
# NO RETURNS
split_ip() {

	passed_ip="$1"
	passed_command="$2"

	local ip="$1"
	local IFS="."

	declare -a ip_arr=()

	read -ra ip_arr <<< "$passed_ip"

	if [ ${#ip_arr[@]} -lt 4 ]; then
		error_exit "[IP_MISSING_OCTETS_ERROR]"
	elif [ ${#ip_arr[@]} -gt 4 ]; then
		error_exit "[IP_TOO_MANY_OCTETS_ERROR]"
	fi

	for i in {0..3}; do
		is_valid_number "${ip_arr[$i]}"
		if [ "$?" -eq 1 ]; then
			error_exit "[IP_INVALID_OCTET_ERROR]"
		fi
	done

	invalid_count=0
	if [[ ${ip_arr[0]} -lt 1 || ${ip_arr[0]} -gt 223 ]]; then
		((invalid_count+=1))
	fi
	if [[ ${ip_arr[1]} -lt 0 || ${ip_arr[1]} -gt 255 ]]; then
		((invalid_count+=1))
	fi
	if [[ ${ip_arr[2]} -lt 0 || ${ip_arr[2]} -gt 255 ]]; then
		((invalid_count+=1))
	fi
	if [[ ${ip_arr[3]} -lt 1 || ${ip_arr[3]} -gt 254 ]]; then
		((invalid_count+=1))
	fi

	if [ $invalid_count -ge 1 ]; then
		error_exit "[IP_OCTET_BOUNDING_ERROR]"
	fi

	ip="${ip_arr[0]}.${ip_arr[1]}.${ip_arr[2]}.${ip_arr[3]}"

	ping_ip "$ip" "$passed_command"
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Pings the passed IP address to confirm a connection before sending the command to the device
# Will call pre-programmed error states if a flag is thrown, like cannot ping device
# Will then call nc_command if all is good
# NO RETURNS
ping_ip() {

	passed_ip="$1"
	passed_command="$2"

	ping -c 1 -W 1 "$passed_ip" > /dev/null 2>&1

	if [ "$?" -eq 0 ]; then
		get_command "$passed_ip" "$passed_command"
	else
		error_exit "[PING_TEST_FAILED_ERROR]"
	fi

}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Prints Command List for user to see and make a choice
# Expects a num (int) and will throw intentional error if anything else is entered
# Returns number (int) based on user choice in menu
get_command() {

  passed_ip="$1"
  passed_command="$2"

	user_choice=-999

  command_dictionary=()
  command_dictionary[1]="event_log"
  command_dictionary[2]="tiered_color_on"
  command_dictionary[3]="tiered_color_off"
  command_dictionary[4]="60_lines"
  command_dictionary[5]="66_lines"
  command_dictionary[6]="tray_switch_on"
  command_dictionary[7]="tray_switch_off"
  command_dictionary[8]="sleep_timer_on"
  command_dictionary[9]="sleep_timer_off"
  command_dictionary[0]="print_error_list"

  if [[ -z "$passed_command" ]]; then

    echo "Command Options:"
    echo "[ 1 ] - Event Log"
    echo "[ 2 ] - Turn on 3 Tier Color"
    echo "[ 3 ] - Turn off 3 Tier Color"
    echo "[ 4 ] - Turn on 60 Lines Mode"
    echo "[ 5 ] - Turn on 66 Lines Mode"
    echo "[ 6 ] - Turn on Tray Switch"
    echo "[ 7 ] - Turn off Tray Switch"
    echo "[ 8 ] - Turn on Sleep Timer"
    echo "[ 9 ] - Turn off Sleep Timer"
    echo "[ 0 ] - Display Error Menu List"

    echo ""
    read -r -p "Enter Menu Choice: " user_choice
    echo
  fi

  if [[ "$user_choice" == -999 ]]; then
    for i in "${!command_dictionary[@]}"; do
      if [[ "${command_dictionary[$i]}" == "$passed_command" ]]; then
        user_choice=$i
      fi
    done
  fi

	if [[ "$user_choice" == 1 ]]; then
    event_log "$passed_ip"
  elif [[ "$user_choice" == 2 || "$user_choice" == 3 ]]; then
    toggle_tiered_color "$passed_ip" "$user_choice"
  elif [[ "$user_choice" == 4 || "$user_choice" == 5 ]]; then
    toggle_line_mode "$passed_ip" "$user_choice"
  elif [[ "$user_choice" == 6 || "$user_choice" == 7 ]]; then
    toggle_tray_switch "$passed_ip" "$user_choice"
  elif [[ "$user_choice" == 8 || "$user_choice" == 9 ]]; then
    toggle_sleep_timer "$passed_ip" "$user_choice"
  elif [[ "$user_choice" == 0 ]]; then
    error_list
  else
    error_exit "[INVALID_COMMAND_ENTRY_ERROR]"
  fi
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# Will create command file if needed
# Prints out the machines event log
# Uses netcat to send the command via IP address
# NO RETURNS
event_log() {
  passed_ip="$1"
  dir_path="$HOME/Kyocera_commands"
  file_path="$HOME/Kyocera_commands/event_log.txt"

  if [[ ! -f "$file_path" ]]; then
    if [[ ! -f "$dir_path" ]]; then
      mkdir -p "$dir_path"
    fi
    printf "!R!KCFG\"ELOG\";EXIT;" > "$file_path"
  fi

  if which lpr &>/dev/null; then
    lpr -H "${passed_ip}:9100" -o raw "$file_path" &> /dev/null &
  else
    error_exit "[LPR_NOT_INSTALLED_ERROR]"
  fi

  echo ""
  read -r -p "Sent command to copier/printer. Press any key to exit..." exit_condition
  echo -e "\033[0m"
  exit 1
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Will create command file if needed
# Toggles sleep timer ON/OFF
# When turning ON 3 tiered color
#   Uses the following 'default' structure where
#   Level 1 = 0-2% color, Level 2 = 2-5% color, and Level 3 = 6+% color
# Uses netcat to send the command via IP address
# NO RETURNS
toggle_tiered_color() {
  passed_ip="$1"
  dir_path="$HOME/Kyocera_commands"
  file_path_on="$HOME/Kyocera_commands/3_tier_on.txt"
  file_path_off="$HOME/Kyocera_commands/3_tier_off.txt"

  if [[ "$2" == 2 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R!KCFG\"TCCM\",1;\n" > "$file_path_on"
      printf "!R!KCFG\"STCT\",1,20;\n" >> "$file_path_on"
      printf "!R!KCFG\"STCT\",2,50;EXIT;" >> "$file_path_on"
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_on" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 3 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R!KCFG\"TCCM\",0;EXIT;" > "$file_path_off"
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_off" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  fi

  echo ""
  read -r -p "Sent command to copier/printer. Press any key to exit..." exit_condition
  echo -e "\033[0m"
  exit 1
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Will create command file if needed
# Toggles line mode between 60/66 lines a page
# Uses netcat to send the command via IP address
# NO RETURNS
toggle_line_mode() {
  passed_ip="$1"
  dir_path="$HOME/Kyocera_commands"
  file_path_60="$HOME/Kyocera_commands/60_line_mode.txt"
  file_path_66="$HOME/Kyocera_commands/66_line_mode.txt"

  if [[ "$2" == 4 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO U0,6; FRPO U1,60; EXIT;" > "$file_path_60"
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_60" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 5 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO U0,6; FRPO U1,66; EXIT;" > "$file_path_66"
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_66" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  fi

  echo ""
  read -r -p "Sent command to copier/printer. Press any key to exit..." exit_condition
  echo -e "\033[0m"
  exit 1
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Will create command file if needed
# Toggles tray switch ON/OFF
# Uses netcat to send the command via IP address
# NO RETURNS
toggle_tray_switch() {
  passed_ip="$1"
  dir_path="$HOME/Kyocera_commands"
  file_path_on="$HOME/Kyocera_commands/tray_switch_on.txt"
  file_path_off="$HOME/Kyocera_commands/tray_switch_off.txt"

  if [[ "$2" == 6 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO A2,10; EXIT;" > "$file_path_on" # NEEDS edit
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_on" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 7 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO A2,10; EXIT;" > "$file_path_off"
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_off" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  fi

  echo ""
  read -r -p "Sent command to copier/printer. Press any key to exit..." exit_condition
  echo -e "\033[0m"
  exit 1
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Will create command file if needed
# Toggles sleep timer ON/OFF
# Toggle ON sets Sleep Timer to 5 minutes
# Uses netcat to send the command via IP address
# NO RETURNS
toggle_sleep_timer() {
  passed_ip="$1"
  dir_path="$HOME/Kyocera_commands"
  file_path_on="$HOME/Kyocera_commands/sleep_timer_on.txt"
  file_path_off="$HOME/Kyocera_commands/sleep_timer_off.txt"

  if [[ "$2" == 8 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO N5,1; EXIT;" > "$file_path_on"
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_on" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 9 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO N5,0; EXIT;" > "$file_path_off"
    fi
    if which lpr &>/dev/null; then
      lpr -H "${passed_ip}:9100" -o raw "$file_path_off" &> /dev/null &
    else
      error_exit "[LPR_NOT_INSTALLED_ERROR]"
    fi
  fi

  exit_condition=""
  echo ""
  read -r -p "Sent command to copier/printer. Press any key to exit..." exit_condition
  echo -e "\033[0m"
  exit 1
}

# Passed args
#   $1 = whatever pre-programmed error code happened
# Will let the user know that an intentional error state happened
# Will also print out the programmed error code
# NO RETURNS
error_exit() {

  if [[ $1 == "[LPR_NOT_INSTALLED_ERROR]" ]]; then
    lpr_error_exit
  fi

  exit_condition=""
	echo
	read -r -p "$1. Press any key to exit..." exit_condition
	echo -e "\033[0m"
	exit 1
}

# NO PASSED ARGS
# Shows users how to install lpr onto workstation

lpr_error_exit() {
  echo
  echo "How to install LPR in various OS environments"
  echo "-macOS | brew install cups"
  echo "-Ubuntu/Debian | sudo apt install cups-bsd"
  echo "-Fedora/RHEL | sudo dnf install cups"
  echo "-Windows | Enable LPR Port Monitor in Windows Features"
  echo "-FreeBSD | pkg install cups"
  echo
  read -r -p "%F{cyan}Please install LPR (cups). Press any key to exit...%f" exit_condition
	echo -e "\033[0m"
	exit 1
}

# NO PASSED ARGS
# Lets the user know that runtime was successful
# Currently Unused (used during testing)
# NO RETURNS
safe_exit() {
  exit_condition=""
	echo
  read -r -p "Runtime success. Press any key to exit..." exit_condition
  echo -e "\033[0m"
	exit 1
}

# NO PASSED ARGS
# Prints out all pre-programmed error codes, description, and an example or two
# NO RETURNS
error_list() {
	echo
	echo "ERROR_CODE: IP_MISSING_OCTETS_ERROR"
	echo "DESCRIPTION: The IP address is missing one or more octets."
	echo "EXAMPLE: 192.168.1. or 192..1.25"
	echo
	echo "ERROR_CODE: IP_TOO_MANY_OCTETS_ERROR"
	echo "DESCRIPTION: The IP address has too many octets."
	echo "EXAMPLE: 19.2.168.1.25"
	echo
	echo "ERROR_CODE: IP_INVALID_OCTET_ERROR"
	echo "DESCRIPTION: The IP address contains an invalid octet."
	echo "EXAMPLE: 192.16i.1.25"
	echo
	echo "ERROR_CODE: IP_OCTET_BOUNDING_ERROR"
	echo "DESCRIPTION: The IP address contains an invalid octet."
	echo "EXAMPLE: 192.1680.1.25"
	echo
	echo "ERROR_CODE: PING_TEST_FAILED_ERROR"
	echo "DESCRIPTION: Could not ping the copier/printer."
	echo "Please double check network settings on PC and on copier/printer."
	echo
	echo "ERROR_CODE: NC_NOT_INSTALLED_ERROR"
	echo "DESCRIPTION: NC is not enabled."
	echo "Please install Netcat (nc)."
	echo
	echo "ERROR_CODE: IP_MISMATCH_ERROR"
	echo "DESCRIPTION: Invalid menu selection at IP Mismatch."
	echo "An Invalid menu option was detected when selecting to continue with the passed IP or the defined IP."
	echo
	echo "ERROR_CODE: CLI_INVALID_ARGUMENTS_ERROR"
	echo "DESCRIPTION: A process error with Command Line Interface (CLI) arguments was detected and could not be handled."
	echo "Please review arguments and try again. If error persists, please contact with author of the script."
	echo
	exit_condition=""
	read -r -p "Press any key to exit..." exit_condition
	echo -e "\033[0m"
	exit 1
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Variable declaration
# NO RETURNS

declared_ip=""
declare -a ip_arr=()

arg_1="$1"
arg_2="$2"

# for CLI activation: no args passed
if [[ -z "$arg_1" && -z "$arg_2" ]]; then

	# No IP is defined, ask for one
    if [[ -z "$declared_ip" ]]; then
        get_ip "$declared_ip" "$arg_2"

    # IP is defined in the script, proceed with it
    else
        ping_ip "$declared_ip" "$arg_2"
    fi

# for CLI activation: with one (1) arg passed
elif [[ -n "$arg_1" && -z "$arg_2" ]]; then

	# Checks if first passed arg is in IP address format
  if [[ "$arg_1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then

		# Checks to see if passed IP and defined IP (if applicable) match
		# If not a match, prompts to use defined IP or passed IP
		if [[ -n "$declared_ip" && "$arg_1" != "$declared_ip" ]]; then

			echo ""
			echo "Passed IP does not matched Defined IP"
			echo ""
			echo "Enter (Y) to continue with Passed IP: $arg_1"
			echo "Enter (N) to continue with Defined IP: $declared_ip"
			read -pr "Your choice (Y/N): " choice

			case "$choice" in
				[Yy]*) ping_ip "$arg_1" "$arg_2" ;;
				[Nn]*) ping_ip "$declared_ip" "$arg_2" ;;
				*) error_exit "[IP_MISMATCH_ERROR]" ;;
			esac
		else
			ping_ip "$arg_1" "$arg_2"
		fi
	# If not in IP address format will pass arg_1 in the place of arg_2
	# This will prompt the user for an IP in get_ip or use defined IP (if applicable)
	else
		if [[ -z "$declared_ip" ]]; then
			get_ip "$declared_ip" "$arg_1"
		else
			ping_ip "$declared_ip" "$arg_1"
		fi
  fi

# for CLI activation: with two (2) passed args
elif [[ -n "$arg_1" && -n "$arg_2" ]]; then

	# Checks if first passed arg is in IP address format
  if [[ "$arg_1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then

		# Checks to see if passed IP and defined IP (if applicable) match
		# If not a match, prompts to use defined IP or passed IP
		if [[ -n "$declared_ip" && "$arg_1" != "$declared_ip" ]]; then

			echo ""
			echo "Passed IP does not matched Defined IP"
			echo ""
			echo "Enter (Y) to continue with Passed IP: $arg_1"
			echo "Enter (N) to continue with Defined IP: $declared_ip"
			read -pr "Your choice (Y/N): " choice

			case "$choice" in
				[Yy]*) ping_ip "$arg_1" "$arg_2" ;;
				[Nn]*) ping_ip "$declared_ip" "$arg_2" ;;
				*) error_exit "[IP_MISMATCH_ERROR]" ;;
			esac
		else
			ping_ip "$arg_1" "$arg_2"
		fi

	# Checks to see if the IP is passed as second arg instead of first arg (SHOULD BE FIRST ARG)
	# If args are swapped (event_ log 172.1.0.214) will swap positions when calling ping_ip
	elif [[ ! "$arg_1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && "$arg_2" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		echo ""
		echo "Detected swapped argument ordering. Correcting..."

		# Checks to see if passed IP and defined IP (if applicable) match
		# If not a match, prompts to use defined IP or passed IP
		if [[ -n "$declared_ip" && "$arg_2" != "$declared_ip" ]]; then

			echo ""
			echo "Passed IP does not matched Defined IP"
			echo "Enter (Y) to continue with Passed IP: $arg_2"
			echo "Enter (N) to continue with Defined IP: $declared_ip"
			read -pr "Your choice (Y/N): " choice

			case "$choice" in
				[Yy]*) ping_ip "$arg_2" "$arg_1" ;;
				[Nn]*) ping_ip "$declared_ip" "$arg_1" ;;
				*) error_exit "[IP_MISMATCH_ERROR]" ;;
			esac
		else
			ping_ip "$arg_2" "$arg_1"
		fi

	# Failsafe if args cannot be parsed or processed correctly
	else
		echo ""
		echo "Error in process: $arg_1 | $arg_2"
		error_exit "[CLI_INVALID_ARGUMENTS_ERROR]"
    fi
fi

echo -ne "\033[0m"
exit 1