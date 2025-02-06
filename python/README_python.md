# Prescribe Bash Script Tool

This script has been tested with Python 2.7 and Python 3.12. This script was written with backwards compatibility in mind, and with a unified user experience across all scripts in the repo.

## Setup

### Make Executable (recommended)

#### Unix/Linux/macOS

To make the script executable run the following after navigating to the correct directory in terminal

```shell
chmod +x prescribe.py
```

To add the script to PATH run the following, may need admin rights to move script

```shell
mv prescribe.py /usr/local/bin
chmod +x /usr/local/bin/prescribe.py
```

Once the script has been moved and given executable rights, calling from CLI would look where {arg1} and {arg2} are optional arguments (see below)

```shell
prescribe.py {arg1} {arg2}
```

#### Windows 10/11

Move the .py file to a permanent location, like 

    C:\Scripts\Kyocera\Prescribe\prescribe.py

Press Win+R, type 'sysdm.cpl', then <Enter>

Advanced > Environment Variables > System Variables > Path > Edit > New

Add the permanent folder you just made > Ok

Restart terminal (command prompt)

Then running from CLI, with script in PATH, where {arg1} and {arg2} are optional arguments (see below)

```shell
prescribe.py {arg1} {arg2}
```

### Declare Static IP (optional)
To declare a static IP the script will *always* use do the following per used script.

`.py` edit line 386

    line 386:  declared_ip=""
    line 386:  declared_ip="172.10.0.5"

## Using the Script
There are two ways to run and use the script
1) Double Click
2) Call from Command Line Interface (CLI)

### Double Clicking Script
This way of running the script will ask you for the IP (unless already declared) and output a menu for Command options. After inputting both the IP and the desired command, it will run the command and send it to the input IP.

### CLI calling (less prompts)
There are multiple ways to run the script via CLI. The ones the script will handle are as follows:

    prescribe.py                        (no args)
    prescribe.py 172.10.0.5             (IP as arg)
    prescribe.py event_log              (command as arg)
    prescribe.py 172.10.0.5 event_log   (both args)
    prescribe.py event_log 172.10.0.5   (both args)

Running with no passed args will net the same experience as double-clicking the script<br>
Running with 1 passed arg will prompt for input on the missing arg<br>
Running with 2 passed args will not prompt for any input

In order to run this script via CLI (see above for PATH), the command is as follows for NOT PATH where {arg1} and {arg2} are optional arguments

```shell
bash /path/to/file/prescribe.py {arg1} {arg2}
```

All Scripts will work in the same fashion. Able to be interacted with in the same fashion. All Scripts will be able to take the following commands as arguments (args)

    event_log
    tiered_color_on
    tiered_color_off
    60_lines
    66_lines
    tray_switch_on
    tray_switch_off
    sleep_timer_on
    sleep_timer_off
    print_error_list