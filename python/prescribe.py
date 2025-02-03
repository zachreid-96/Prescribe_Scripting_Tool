from __future__ import print_function, absolute_import
import sys
import subprocess
import platform
import os


def get_ip(ip, command):
    passed_ip = ip
    passed_command = command

    try:
        input = raw_input
    except NameError:
        pass

    print("Please enter the Copier's IP in the following format: 10.120.11.68")
    print("Or press enter to display the error list")
    print("")
    machine_ip = input("Copier/Printer IP: ")

    if machine_ip == "":
        error_list()
    else:
        split_ip(machine_ip, passed_command)


def split_ip(ip, command):
    passed_ip = ip
    passed_command = command

    ip_arr = passed_ip.split('.')
    ip_int_arr = []

    if len(ip_arr) == 4:
        for octet in ip_arr:
            try:
                ip_int_arr.append(int(octet))
            except ValueError:
                error_exit("[IP_INVALID_OCTET_ERROR]")

        if not 1 <= ip_int_arr[0] <= 223:
            error_exit("[IP_OCTET_BOUNDING_ERROR]")
        if not 0 <= ip_int_arr[1] <= 255:
            error_exit("[IP_OCTET_BOUNDING_ERROR]")
        if not 0 <= ip_int_arr[2] <= 255:
            error_exit("[IP_OCTET_BOUNDING_ERROR]")
        if not 1 <= ip_int_arr[3] <= 254:
            error_exit("[IP_OCTET_BOUNDING_ERROR]")

        new_ip = "{0}.{1}.{2}.{3}".format(ip_int_arr[0], ip_int_arr[1], ip_int_arr[2], ip_int_arr[3])
        ping_ip(new_ip, passed_command)
    else:
        if len(ip_arr) > 4:
            error_exit("[IP_TOO_MANY_OCTETS_ERROR]")
        else:
            error_exit("[IP_MISSING_OCTETS_ERROR]")


def ping_ip(ip, command):
    passed_ip = ip
    passed_command = command
    system = platform.system().lower()

    if system == 'windows':
        output = subprocess.check_output(['ping', '-n', '1', passed_ip]).decode('utf-8')
    else:
        output = subprocess.check_output(['ping', '-c', '1', passed_ip]).decode('utf-8')

    if output.__contains__("unreachable"):
        error_exit("[PING_TEST_FAILED_ERROR]")
    else:
        get_command(passed_command, passed_command)


def get_command(ip, command):
    passed_ip = ip
    passed_command = command

    try:
        input = raw_input
    except NameError:
        pass

    user_choice = -99
    command_dictionary = []
    command_dictionary.append("space_holder")
    command_dictionary.append("event_log")
    command_dictionary.append("tiered_color_on")
    command_dictionary.append("tiered_color_off")
    command_dictionary.append("60_lines")
    command_dictionary.append("66_lines")
    command_dictionary.append("tray_switch_on")
    command_dictionary.append("tray_switch_off")
    command_dictionary.append("sleep_timer_on")
    command_dictionary.append("sleep_timer_off")
    command_dictionary.append("print_error_list")

    if passed_command == "":
        print("Command Options:")
        print("[ 1 ] - Event Log")
        print("[ 2 ] - Turn on 3 Tier Color")
        print("[ 3 ] - Turn off 3 Tier Color")
        print("[ 4 ] - Turn on 60 Lines Mode")
        print("[ 5 ] - Turn on 66 Lines Mode")
        print("[ 6 ] - Turn on Tray Switch")
        print("[ 7 ] - Turn off Tray Switch")
        print("[ 8 ] - Turn on Sleep Timer")
        print("[ 9 ] - Turn off Sleep Timer")
        print("[ 0 ] - Display Error Menu List")

        print("")
        user_choice = input("Copier/Printer IP: ")

    if user_choice == -99:
        user_choice = str(command_dictionary.index(passed_command))

    if user_choice == "1":
        event_log(passed_ip)
    elif user_choice == "2" or user_choice == "3":
        toggle_tiered_color(passed_ip, user_choice)
    elif user_choice == "4" or user_choice == "5":
        toggle_line_mode(passed_ip, user_choice)
    elif user_choice == "6" or user_choice == "7":
        toggle_tray_switch(passed_ip, user_choice)
    elif user_choice == "8" or user_choice == "9":
        toggle_sleep_timer(passed_ip, user_choice)
    elif user_choice == "0":
        error_list()

    error_exit("[INVALID_COMMAND_ENTRY_ERROR]")


def event_log(ip):
    try:
        file_path = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', 'event_log.txt')
    except KeyError:
        file_path = os.path.join(os.environ['HOME'], 'Kyocera_commands', 'event_log.txt')

    if not os.path.exists(file_path):
        with open(file_path, 'w') as f:
            f.write('!R!KCFG"ELOG";EXIT;')

    send_lpr_command(ip, file_path)


def toggle_tiered_color(ip, command):
    try:
        file_path_on = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', '3_tier_on.txt')
        file_path_off = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', '3_tier_off.txt')
    except KeyError:
        file_path_on = os.path.join(os.environ['HOME'], 'Kyocera_commands', '3_tier_on.txt')
        file_path_off = os.path.join(os.environ['HOME'], 'Kyocera_commands', '3_tier_off.txt')

    if command == "2":
        if not os.path.exists(file_path_on):
            with open(file_path_on, 'w') as f:
                f.write('!R!KCFG"TCCM",1;\n')
                f.write('!R!KCFG"STCT",1,20;\n')
                f.write('!R!KCFG"STCT",2,50;EXIT;')
        send_lpr_command(ip, file_path_on)

    elif command == "3":
        if not os.path.exists(file_path_off):
            with open(file_path_off, 'w') as f:
                f.write('!R!KCFG"TCCM",0;EXIT;')
        send_lpr_command(ip, file_path_off)


def toggle_line_mode(ip, command):
    try:
        file_path_60 = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', 'file_path_60.txt')
        file_path_66 = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', 'file_path_66.txt')
    except KeyError:
        file_path_60 = os.path.join(os.environ['HOME'], 'Kyocera_commands', 'file_path_60.txt')
        file_path_66 = os.path.join(os.environ['HOME'], 'Kyocera_commands', 'file_path_66.txt')

    if command == "2":
        if not os.path.exists(file_path_60):
            with open(file_path_60, 'w') as f:
                f.write('!R! FRPO U0,6; FRPO U1,60; EXIT;')
        send_lpr_command(ip, file_path_60)

    elif command == "3":
        if not os.path.exists(file_path_66):
            with open(file_path_66, 'w') as f:
                f.write('!R! FRPO U0,6; FRPO U1,66; EXIT;')
        send_lpr_command(ip, file_path_66)


def toggle_tray_switch(ip, command):
    try:
        tray_switch_on = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', 'tray_switch_on.txt')
        tray_switch_off = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', 'tray_switch_off.txt')
    except KeyError:
        tray_switch_on = os.path.join(os.environ['HOME'], 'Kyocera_commands', 'tray_switch_on.txt')
        tray_switch_off = os.path.join(os.environ['HOME'], 'Kyocera_commands', 'tray_switch_off.txt')

    if command == "2":
        if not os.path.exists(tray_switch_on):
            with open(tray_switch_on, 'w') as f:
                f.write('!R! FRPO A2,10; EXIT;') # NEED edit
        send_lpr_command(ip, tray_switch_on)

    elif command == "3":
        if not os.path.exists(tray_switch_off):
            with open(tray_switch_off, 'w') as f:
                f.write('!R! FRPO A2,10; EXIT;')
        send_lpr_command(ip, tray_switch_off)


def toggle_sleep_timer(ip, command):
    try:
        sleep_timer_on = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', 'sleep_timer_on.txt')
        sleep_timer_off = os.path.join(os.environ['USERPROFILE'], 'Kyocera_commands', 'sleep_timer_off.txt')
    except KeyError:
        sleep_timer_on = os.path.join(os.environ['HOME'], 'Kyocera_commands', 'sleep_timer_on.txt')
        sleep_timer_off = os.path.join(os.environ['HOME'], 'Kyocera_commands', 'sleep_timer_off.txt')

    if command == "2":
        if not os.path.exists(sleep_timer_on):
            with open(sleep_timer_on, 'w') as f:
                f.write('!R! FRPO N5,0; EXIT;') # NEED edit
        send_lpr_command(ip, sleep_timer_on)

    elif command == "3":
        if not os.path.exists(sleep_timer_off):
            with open(sleep_timer_off, 'w') as f:
                f.write('!R! FRPO N5,0; EXIT;')
        send_lpr_command(ip, sleep_timer_off)


def send_lpr_command(ip, command):

    system = platform.system().lower()
    if system == 'windows':
        try:
            subprocess.call(['where', 'lpr'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            error_exit("[LPR_NOT_ENABLED_ERROR]")
    else:
        try:
            subprocess.call(['which', 'lpr'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            error_exit("[LPR_NOT_ENABLED_ERROR]")

    subprocess.call(['lpr', '-S', ip, '-P', '9100', command],
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def error_exit(err_condition):
    try:
        input = raw_input
    except NameError:
        pass

    print("")
    input("{0}. Press any key to exit...".format(err_condition))
    exit()


def error_list():
    print("")
    print("ERROR_CODE: IP_MISSING_OCTETS_ERROR")
    print("DESCRIPTION: The IP address is missing one or more octets.")
    print("EXAMPLE: 192.168.1. or 192..1.25")
    print("")
    print("ERROR_CODE: IP_TOO_MANY_OCTETS_ERROR")
    print("DESCRIPTION: The IP address has too many octets.")
    print("EXAMPLE: 19.2.168.1.25")
    print("")
    print("ERROR_CODE: IP_INVALID_OCTET_ERROR")
    print("DESCRIPTION: The IP address contains an invalid octet.")
    print("EXAMPLE: 192.16i.1.25")
    print("")
    print("ERROR_CODE: IP_OCTET_BOUNDING_ERROR")
    print("DESCRIPTION: The IP address contains an invalid octet.")
    print("EXAMPLE: 192.1680.1.25")
    print("")
    print("ERROR_CODE: PING_TEST_FAILED_ERROR")
    print("DESCRIPTION: Could not ping the copier/printer.")
    print("Please double check network settings on PC and on copier/printer.")
    print("")
    print("ERROR_CODE: LP_NOT_ENABLED_ERROR")
    print("DESCRIPTION: LPR is not enabled.")
    print("Please enable LPR.")
    print("")
    print("ERROR_CODE: IP_MISMATCH_ERROR")
    print("DESCRIPTION: Invalid menu selection at IP Mismatch.")
    print("An Invalid menu option was detected when selecting to continue with the passed IP or the defined IP.")
    print("")
    print("ERROR_CODE: CLI_INVALID_ARGUMENTS_ERROR")
    print("DESCRIPTION: A process error with Command Line Interface (CLI) arguments was detected and could not be "
          "handled.")
    print("Please review arguments and try again. If error persists, please contact with author of the script.")
    print("")

    input("Press any key to exit...")
    exit()


if __name__ == "__main__":

    declared_ip = "0.0.0.0"
    print(len(sys.argv), sys.argv)
    if len(sys.argv) == 1:
        get_ip("", "")
    elif len(sys.argv) == 2:
        pass
    elif len(sys.argv) == 3:
        pass
