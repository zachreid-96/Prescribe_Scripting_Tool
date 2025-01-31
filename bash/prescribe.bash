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
# If no input is entered, the preprogrammed error list will be displayed and exit intentionally
# Will then call split_ip
# NO RETURNS

get_ip() {

	passed_ip="$1"
	command="$2"

	if [[ -n "$passed_ip" ]]; then
		ping_ip "$passed_ip" "$command"
	fi

	echo "Please enter Copier IP in the following format: 10.120.1.68"
	echo "Or press enter to display error list"
	echo

	read -r -p "Enter IP Address: " ip
	echo

	if [[ -z "$declared_ip" ]]; then
		error_list
	else
		# echo "debug ip -- $declared_ip"
		split_ip "$declared_ip" "$command"
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
# Will call preprogrammed error states if a flag is thrown, like too many or few octets or an invalid number
# Will then call ping_ip
# NO RETURNS

split_ip() {

	# echo "debug -- split_ip"

	passed_ip="$1"
	command="$2"

	local ip="$1"
	local IFS="."

	declare -a ip_arr=()

	read -ra ip_arr <<< "$passed_ip"
	#echo "${ip_arr[0]}.${ip_arr[1]}.${ip_arr[2]}.${ip_arr[3]}"

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
		error_exit "[IP_OCTECT_BOUNDING_ERROR]"
	fi

	ip="${ip_arr[0]}.${ip_arr[1]}.${ip_arr[2]}.${ip_arr[3]}"
	# echo "debugging assembled ip --$declared_ip"
	ping_ip "$ip" "$command"

}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# Pings the passed IP address to confirm a connection before sending the command to the device
# Will call preprogrammed error states if a flag is thrown, like cannot ping device
# Will then call nc_command if all is good
# NO RETURNS

ping_ip() {

	# echo "debug -- ping_ip"

	passed_ip="$1"
	command="$2"

	# echo "debugging passed_ip -- $passed_ip"

	ping -c 1 -W 1 "$passed_ip" > /dev/null 2>&1

	if [ "$?" -eq 0 ]; then
		nc_command "$passed_ip" "$command"
	else
		error_exit "[PING_TEST_FAILED_ERROR]"
	fi

}

# NO PASSED ARGS
# Prints Command List for user to see and make a choice
# Expects a num (int) and will throw intentional error if anything else is entered
# Returns number (int) based on user choice in menu

get_command() {

	command=""

	echo "Command Options:"
	echo "1 - Event Log"
	echo "    prints Event Log"
	echo "2 - 3 Tier Color"
	echo "    enables 3 tiered color"
	echo "3 - 60 Lines"
	echo "    enables 60 lines mode"
	echo "4 - Tray Switch"
	echo "    turns off tray switching"
	echo "5 - Sleep Timer"
	echo "    turns off sleep timer"

	echo "(enter 6 to display error list)"
	read -r -p "Enter Menu Choice: " command
	echo

	# echo "debugging command -- $command"

	if [ "$command" = 1 ]; then
		return 1
	elif [ "$command" = 2 ]; then
		return 2
	elif [ "$command" = 3 ]; then
		return 3
	elif [ "$command" = 4 ]; then
		return 4
	elif [ "$command" = 5 ]; then
		return 5
	elif [ "$command" = 6 ]; then
		error_list
	else
		error_exit "[INVALID_COMMAND_ENTRY_ERROR]"
	fi
}

# Passed args
# 	$1 = arg_1 and should be the IP address
# 	$2 = arg_2 and should be the desired prescribe command
# If $2 is empty, will prompt user to enter command via get_command function
# Will check if prescribe command .txt files exist, if not will create it
# Will then send the prescribe command to device via the NetCat command
# NO RETURNS

nc_command() {

	passed_ip="$1"
	command="$2"

	dir_path="$HOME/Kyocera_Commands"
	prescribe_command=""

	# echo "debug -- nc_command"

	if [[ -z "$command" ]]; then
		get_command
		command="$?"
	fi

	if [[ "$command" =~ ^[0-9]+$ ]]; then
		# echo "command_num"
		command_num="$command"
	else
		# echo "command_str"
		command_str="$command"
	fi

	if [[ "$command_str" = "event_log" || "$command_num" -eq 1 ]]; then
		# echo "debugging -- option 1"
		file_path="$HOME/Kyocera_Commands/event_log.txt"
		prescribe_command="!R!KCFG\"ELOG\";EXIT;"

	elif [[ "$command_str" = "3_tier_color" || "$command_num" -eq 2 ]]; then
		# echo "debugging -- poption 2"
		file_path="$HOME/Kyocera_Commands/3_tier_color.txt"
		prescribe_command="!R!KCFG\"TCCM\",1;EXIT;"

	elif [[ "$command_str" = "60_lines" || "$command_num" -eq 3 ]]; then
		# echo "debugging -- option 3"
		file_path="$HOME/Kyocera_Commands/60_lines.txt"
		prescribe_command="!R! FRPO U0,6; FRPO U1,60; EXIT;"

	elif [[ "$command_str" = "no_tray_switch" || "$command_num" -eq 4 ]]; then
		# echo "debugging -- option 4"
		file_path="$HOME/Kyocera_Commands/no_tray_switch.txt"
		prescribe_command="!R! FRPO A2,10; EXIT;"

	elif [[ "$command_str" = "sleep_timer" || "$command_num" -eq 5 ]]; then
		# echo "debugging -- option 5"
		file_path="$HOME/Kyocera_Commands/sleep_timer.txt"
		prescribe_command="!R! FRPO N5,0; EXIT;"

	else
		error_exit "[INVALID_COMMAND_ENTRY_ERROR]"
	fi

	# echo "debugging -- path set and command set"

	if [ ! -f "$file_path" ]; then
		if [ ! -d "$dir_path" ]; then
			mkdir -p "$dir_path"
		fi
		echo -ne "$prescribe_command" > "$file_path"
	fi

	# echo "debugging -- file exists or has been created"

	if command -v nc >/dev/null 2>&1; then
		echo ""
		echo "Sending command to printer now..."
		nc -w 5 -q 0 "$passed_ip" 9100 < "$file_path"
	else
		error_exit "[NC_NOT_INSTALLED_ERROR]"
	fi

	echo ""
	echo "Sent command to copier/printer. Press any key to exit..."
	read -nr 1 -s
	exit 1
}

# NO PASSED ARGS
# Will let the user know that an intentional error state happened
# Will also print out the programmed error code
# NO RETURNS

error_exit() {
	echo
	echo "$1. Press any key to exit..."
	read -nr 1 -s
	exit 1
}

safe_exit() {
	echo
	echo "Runtime success. Press any key to exit..."
  read -nr 1 -s
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
	echo "Press any key to exit..."
	read -nr 1 -s
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
				*) error_exit "IP_MISMATCH_ERROR" ;;
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
				*) error_exit "IP_MISMATCH_ERROR" ;;
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
				*) error_exit "IP_MISMATCH_ERROR" ;;
			esac
		else
			ping_ip "$arg_2" "$arg_1"
		fi

	# Failsafe if args cannot be parsed or processed correctly
	else
		echo ""
		echo "Error in process: $arg_1 | $arg_2"
		error_exit "CLI_INVALID_ARGUMENTS_ERROR"
    fi
fi

