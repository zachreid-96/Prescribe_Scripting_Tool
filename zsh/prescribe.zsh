#!/bin/zsh

declared_ip=""

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
  machine_ip=""

	if [[ -n "$declared_ip" ]]
	then

		ping_ip "$passed_ip" "$passed_command"
	fi

	echo "Please enter the Copier's IP in the following format: 10.120.11.68"
	echo "Or press enter to display error list"
	echo
	vared -p "Copier/Printer IP: " machine_ip

	if [[ -z "$machine_ip" ]]; then
		error_list
	else
		split_ip "$machine_ip" "$passed_command"
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
  echo "Split_IP --- start"
	passed_ip="$1"
  passed_command="$2"

  ip_arr=("${(@s:.:)$(echo "$passed_ip")}")

	len_ip_arr=${#ip_arr}

  echo
	if [[ len_ip_arr -lt 4 ]]; then
		error_exit "[IP_MISSING_OCTETS_ERROR]"
	elif [[ len_ip_arr -gt 4 ]]; then
		error_exit "[IP_TOO_MANY_OCTETS_ERROR]"
	fi

	for i in {1..4}; do
		is_valid_number "${ip_arr[$i]}"
		if [[ "$?" -eq 1 ]]; then
			error_exit "[IP_INVALID_OCTET_ERROR]"
		fi
	done

	invalid_count=0

	if [[ ${ip_arr[1]} -lt 1 || ${ip_arr[1]} -gt 223 ]]; then
		((invalid_count+=1))
	fi
	if [[ ${ip_arr[2]} -lt 0 || ${ip_arr[2]} -gt 255 ]]; then
		((invalid_count+=1))
	fi
	if [[ ${ip_arr[3]} -lt 0 || ${ip_arr[3]} -gt 255 ]]; then
		((invalid_count+=1))
	fi
	if [[ ${ip_arr[4]} -lt 1 || ${ip_arr[4]} -gt 254 ]]; then
		((invalid_count+=1))
	fi

	if [[ $invalid_count -ge 1 ]]; then
		error_exit "[IP_OCTET_BOUNDING_ERROR]"
	fi

	new_ip="${ip_arr[1]}.${ip_arr[2]}.${ip_arr[3]}.${ip_arr[4]}"
	ping_ip "$new_ip" "$passed_command"
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

# NO PASSED ARGS
# Prints Command List for user to see and make a choice
# Expects a num (int) and will throw intentional error if anything else is entered
# Returns number (int) based on user choice in menu
get_command() {

	passed_ip="$1"
	passed_command="$2"

	user_choice=-999

  typeset -A command_dictionary
  command_dictionary["event_log"]=1
  command_dictionary["tiered_color_on"]=2
  command_dictionary["tiered_color_off"]=3
  command_dictionary["60_lines"]=4
  command_dictionary["66_lines"]=5
  command_dictionary["tray_switch_on"]=6
  command_dictionary["tray_switch_off"]=7
  command_dictionary["sleep_timer_on"]=8
  command_dictionary["sleep_timer_off"]=9
  command_dictionary["print_error_list"]=0

	if [[ -z "$passed_command" ]]; then

		echo
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

		echo
		read -r "user_choice?Enter Menu Choice: "
	fi

  if [[ "$user_choice" == -999 ]]; then
    user_choice=command_dictionary["$passed_command"]
  fi

	if [[ "$user_choice" == 1 ]]; then
    event_log $passed_ip
  elif [[ "$user_choice" == 2 || "$user_choice" == 3 ]]; then
    toggle_tiered_color $passed_ip $user_choice
  elif [[ "$user_choice" == 4 || "$user_choice" == 5 ]]; then
    toggle_line_mode $passed_ip $user_choice
  elif [[ "$user_choice" == 6 || "$user_choice" == 7 ]]; then
    toggle_tray_switch $passed_ip $user_choice
  elif [[ "$user_choice" == 8 || "$user_choice" == 9 ]]; then
    toggle_sleep_timer $passed_ip $user_choice
  elif [[ "$user_choice" == 0 ]]; then
    error_list
  else
    error_exit "[INVALID_COMMAND_ENTRY_ERROR]"
	fi

}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
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

  if which nc &>/dev/null; then
    nc "$passed_ip" < "$file_path"
  else
    error_exit "[NC_NOT_INSTALLED_ERROR]"
  fi
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
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_on"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 3 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R!KCFG\"TCCM\",0;EXIT;" > "$file_path_off"
    fi
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_off"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  fi
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
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_60"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 5 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO U0,6; FRPO U1,66; EXIT;" > "$file_path_66"
    fi
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_66"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  fi
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
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_on"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 7 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO A2,10; EXIT;" > "$file_path_off"
    fi
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_off"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  fi
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
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_on"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  elif [[ "$2" == 9 ]]; then
    if [[ ! -f "$file_path" ]]; then
      if [[ ! -f "$dir_path" ]]; then
        mkdir -p "$dir_path"
      fi
      printf "!R! FRPO N5,0; EXIT;" > "$file_path_off"
    fi
    if which nc &>/dev/null; then
      nc "$passed_ip" < "$file_path_off"
    else
      error_exit "[NC_NOT_INSTALLED_ERROR]"
    fi
  fi
}

# Passed args
#   $1 = whatever pre-programmed error code happened
# Will let the user know that an intentional error state happened
# Will also print out the programmed error code
# NO RETURNS

error_exit() {
  exit_condition=""
	echo
	vared -p "$1. Press any key to exit..." exit_condition
	exit 1
}

# NO PASSED ARGS
# Lets the user know that runtime was successful
# Currently Unused (used during testing)
# NO RETURNS

safe_exit() {
  exit_condition=""
	echo
	vared -p "Runtime success. Press any key to exit..." exit_condition
	exit 1
}

# NO PASSED ARGS
# Prints out all pre-programmed error codes, description, and an example or two
# NO RETURNS

error_list() {
  exit_condition=""
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
	echo "ERROR_CODE: IP_OCTECT_BOUNDING_ERROR"
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
	vared -p "Press any key to exit..." exit_condition
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

if [[ -z "$arg_1" && -z "$arg_2" ]]; then
	# Handle no args passed logic here

	if [[ -z "$declared_ip" ]]; then
		get_ip "$arg_1" "$arg_2"

	else
		ping_ip "$declared_ip" "$arg_2"
	fi

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
	safe_exit

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
	safe_exit
fi

