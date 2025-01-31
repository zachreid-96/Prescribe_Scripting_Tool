# A Multi-Language Kyocera Prescribe Tool

The aim of the repository is to create a Kyocera Prescribe Tool pre-loaded with common prescribe commands that can be easily expanded to fit bigger needs.

This repository contains the script tool in mulitple languages:
- **Batch** (`batch/`): Windows `.bat` scripts
- **Bash** (`bash/`): Linux/macOS shell scripts (v3.2 and higher)
- **Zsh** (`zsh/`): Advanced shell scripting (v5.x)
- **Python** (`python/`): Python 2.7 and Python 3.12
- **PowerShell** (`ps1/`): Windows `.ps1` scripts

## Getting Started
Clone the repository:
```shell
git clone https://github.com/zachreid-96/Prescribe_Scripting_Tool
```

## Setup (Optional)
To declare a static IP the script will *always* use do the following per used script.

`.bat` edit line 11

    line 11:  set "declared_ip="
    line 11:  set "declared_ip=172.10.0.5"

`.bash` edit line 345

    line 345:  declared_ip=""
    line 345:  declared_ip="172.10.0.5"

`.zsh` edit line 3

    line 3:  declared_ip=""
    line 3:  declared_ip="172.10.0.5"


## Using the Script
There are two ways to run and use the script
1) Double Click
2) Call from Command Line Interface (CLI)

### Double Clicking Script
This way of running the script will ask you for the IP (unless already declared) and output a menu for Command options. After inputting both the IP and the desired command, it will run the command and send it to the input IP.

### CLI calling (less prompts)
There are multiple ways to run the script via CLI. The ones the script will handle are as follows:

    prescribe.script                        (no args)
    prescribe.script 172.10.0.5             (IP as arg)
    prescribe.script event_log              (command as arg)
    prescribe.script 172.10.0.5 event_log   (both args)
    prescribe.script event_log 172.10.0.5   (both args)

Running with no passed args will net the same experience as double-clicking the script<br>
Running with 1 passed arg will prompt for input on the missing arg<br>
Running with 2 passed args will not prompt for any input

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
