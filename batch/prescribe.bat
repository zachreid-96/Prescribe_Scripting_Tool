:: Stylistic section of the program, turns echo off so these commands do not appear in CMD
@echo off
title Kyocera Scripting Tool
setlocal enableextensions enabledelayedexpansion

:: Color options
:: 1 - Blue, 2 - Green, 3 - Aqua, 4 - Red, 5 - Purple, 6 - Yellow, 7 - White, 8 - Gray, 9 - Light Blue
:: A - Light Green, B - Light Aqua, C - Light Red, D - Light Purple, E - Light Yellow, F - Brite White
color B

set "declared_ip="

:: Should be the passed IP
set "arg_1=%1"
:: Should be the passed command
set "arg_2=%2"

:: Handles double clicking the script or by calling it from the CLI

if "%arg_1%"=="" (

	if not defined declared_ip (

		call :get_ip "" ""
		color
		exit

	) else (

		call :get_ip "%declared_ip%" ""
		color
		exit
	)

) else (
    :: Handles CLI activation when args are passed
	echo %arg_1% | findstr /c:"." > nul

	if %errorlevel% equ 0 (

		if "%arg_2%"=="" (

			call :get_ip "%arg_1%" ""
			color
			exit

		) else (

			call :get_ip "%arg_1%" "%arg_2%"
			color
			exit
		)
	) else (

		if "%arg_2%"=="" (

			call :get_ip "" "%arg_1%"
			color
			exit

		) else (

			call :get_ip "%arg_2%" "%arg_1%"
			color
			exit
		)
	)
)

:: Prompts user to enter an IP if not defined or passed as an arg

:get_ip

	set "passed_ip=%~1"
	set "passed_command=%~2"

	if not "%passed_ip%"=="" (
		call :verify_ip "%passed_ip%" "%passed_command%"
		color
		exit
	)

	echo.
	echo Please enter Copier IP in following format 10.120.1.68
	echo Or enter no IP to output the error list
	echo.

	set /p "ip=Enter IP Address: " || set "ip=0.0.0.0"
	echo.

	:: If no IP is entered, a defualt 0.0.0.0 IP is set and the program will exit
	if "%ip%"=="0.0.0.0" (
		call :print_error_codes
		color
		exit
	)
	if not "%ip%"=="0.0.0.0" (
		call :verify_ip "%ip%" "%passed_command%"
		color
		exit
	)

:: Verifies some basic IP info
:: If IP is passed as arg and doesn't match declared IP (if defined) prompts user to choose

:verify_ip

	set "passed_ip=%~1"
	set "passed_command=%~2"

	set IPArr=[]
	set /a pCount=0

	if defined declared_ip (
		if "!declared_ip!"=="!passed_ip!" (
			call :validate_ip "%passed_ip%" "%passed_command%"
		) else (
			echo.
			echo Passed IP does not match Declared IP
			echo Enter ^(Y^) to continue with Passed IP: "!passed_ip!"
			echo Enter ^(N^) to continue with Declared IP: !declared_ip!
			echo.
			set /p "choice=Enter choice (Y/N): " || set "choice=N"

			if /i "!choice!"=="Y" (
				call :validate_ip "%passed_ip%" "%passed_command%"
			) else if /i "!choice!"=="N" (
				call :validate_ip "%declared_ip%" "%passed_command%"
			) else (
				call :error_exit "[INVALID_IP_CHOICE_ERROR]"
				color
				exit
			)
		)
	)

	set g=
	for /l %%i in (0,1,20) do (
		if !pCount! geq 4 (
			call :error_exit "[IP_EXCESS_OCTET_ERROR]"
		)
		set t=!passed_ip:~%%i,1!
		if "!t!"=="" (
			if !pCount! neq 3 (
				call :error_exit "[IP_MISSING_OCTET_ERROR]"
				color
				exit
			)

			call :validate_ip "!IPArr[0]!" "!IPArr[1]!" "!IPArr[2]!" "!IPArr[3]!" "%passed_command%"
		) else if "!t!"=="." (
			::set IPArr[!pCount!]=!g!
			set /a pCount=pCount+1
			set g=
		) else (
			set "g=!g!!t!"
			set IPArr[!pCount!]=!g!
		)
	)

:: Validates the IP based on a very simple IPv4 range
:: 1-223.0-255.0-255.1-254

:validate_ip

	set "arr_pos_0=%~1"
	set "arr_pos_1=%~2"
	set "arr_pos_2=%~3"
	set "arr_pos_3=%~4"
	set "passed_command=%~5"

	set /a invalid_count=0

	if !arr_pos_0! leq 0 set invalid_count=1
	if !arr_pos_0! gtr 223 set invalid_count=1
	if !arr_pos_1! lss 0 set invalid_count=1
	if !arr_pos_1! gtr 255 set invalid_count=1
	if !arr_pos_2! lss 0 set invalid_count=1
	if !arr_pos_2! gtr 255 set invalid_count=1
	if !arr_pos_3! leq 0 set invalid_count=1
	if !arr_pos_3! gtr 254 set invalid_count=1

	if invalid_count==1 (
		call :error_exit "[IP_INVALID_OCTET_ERROR]"
		color
		exit
	)

	set "new_ip=!arr_pos_0!.!arr_pos_1!.!arr_pos_2!.!arr_pos_3!"

	if "%passed_command%"=="" (
		call :get_command "!new_ip!" ""
		color
		exit
	) else (
		call :get_command "!new_ip!" "%passed_command%"
		color
		exit
	)

:: If command is not passed as arg, prompts user to enter command via menu output
:: visited even if command is passed as arg for file checking

:get_command

	set "passed_ip=%~1"
	set "passed_command=%~2"

	set command=0

	if "%passed_command%"=="" (
		echo.
		echo Command Options:
        echo [ 1 ] - Event Log
        echo [ 2 ] - Turn on 3 Tier Color
        echo [ 3 ] - Turn off 3 Tier Color
        echo [ 4 ] - Turn on 60 Lines Mode
        echo [ 5 ] - Turn on 66 Lines Mode
        echo [ 6 ] - Turn on Tray Switch
        echo [ 7 ] - Turn off Tray Switch
        echo [ 8 ] - Turn on Sleep Timer
        echo [ 9 ] - Turn off Sleep Timer
        echo [ 10 ] - Backup FRPO Settings
        echo [ 11 ] - Initialize FRPO Settings
        echo [ 0 ] - Display Error Menu List

		set /p "command=Enter Menu Choice: " || set command=0
	) else (
	    if "%passed_command%"=="print_error_list" ( set command=0 )
        if "%passed_command%"=="event_log" ( set command=1 )
        if "%passed_command%"=="tiered_color_on" ( set command=2 )
        if "%passed_command%"=="tiered_color_off" ( set command=3 )
        if "%passed_command%"=="60_lines" ( set command=4 )
        if "%passed_command%"=="66_lines" ( set command=5 )
        if "%passed_command%"=="tray_switch_on" ( set command=6 )
        if "%passed_command%"=="tray_switch_off" ( set command=7 )
        if "%passed_command%"=="sleep_timer_on" ( set command=8 )
        if "%passed_command%"=="sleep_timer_off" ( set command=9 )
        if "%passed_command%"=="backup" ( set command=10 )
        if "%passed_command%"=="initialize" ( set command=11 )
	)

	set "dir_path=%USERPROFILE%\Kyocera_Commands"

	if not exist "%dir_path%" (
		mkdir %dir_path%
	)

	set match=0

	if %command%==1 ( set match=1 )
	if %command%==2 ( set match=2 )
	if %command%==3 ( set match=3 )
	if %command%==4 ( set match=4 )
    if %command%==5 ( set match=5 )
	if %command%==6 ( set match=6 )
	if %command%==7 ( set match=7 )
	if %command%==8 ( set match=8 )
    if %command%==9 ( set match=9 )
    if %command%==10 ( set match=10 )
    if %command%==11 ( set match=11 )
    if %command%==0 ( set match=0 )

	if %match%==1 ( call :event_log "%passed_ip%" "%match%" )
	if %match%==2 ( call :toggle_tiered_color "%passed_ip%" "%match%" )
	if %match%==3 ( call :toggle_tiered_color "%passed_ip%" "%match%" )
	if %match%==4 ( call :toggle_line_mode "%passed_ip%" "%match%" )
	if %match%==5 ( call :toggle_line_mode "%passed_ip%" "%match%" )
	if %match%==6 ( call :toggle_tray_switch "%passed_ip%" "%match%" )
	if %match%==7 ( call :toggle_tray_switch "%passed_ip%" "%match%" )
	if %match%==8 ( call :toggle_sleep_timer "%passed_ip%" "%match%" )
	if %match%==9 ( call :toggle_sleep_timer "%passed_ip%" "%match%" )
	if %match%==10 ( call :backup_initialize "%passed_ip%" "%match%" )
	if %match%==11 ( call :backup_initialize "%passed_ip%" "%match%" )
	if %match%==0 ( call :print_error_codes )

	call :error_exit "[INVALID_COMMAND_CHOICE_ERROR]"
	color
	exit

:event_log
    set "passed_ip=%~1"
    set "file_path=%USERPROFILE%\Kyocera_Commands\event_log.txt"

	if not exist "!file_path!" (
		(
			echo | set /p="^!R^!KCFG"ELOG";EXIT;">"!file_path!"
		)
	)
	call :lpr_command "%passed_ip%" "!file_path!"
	color
	exit

:toggle_tiered_color

    if "%~2"==2 (
        set "file_path=%USERPROFILE%\Kyocera_Commands\3_tier_color_on.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R!KCFG"TCCM",1;">"!file_path!"
                echo | set /p="!R!KCFG"STCT",1,20;">>"!file_path!"
                echo | set /p="!R!KCFG"STCT",2,50;EXIT;">>"!file_path!"
            )
        )
    ) else (
        set "file_path=%USERPROFILE%\Kyocera_Commands\3_tier_color_off.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R!KCFG"TCCM",0;">"!file_path!"
            )
        )
    )
    call :lpr_command "%passed_ip%" "!file_path!"
    color
    exit

:toggle_line_mode

    if "%~2"==4 (
        set "file_path=%USERPROFILE%\Kyocera_Commands\60_line_mode.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! FRPO U0,6; FRPO U1,60; EXIT;">"!file_path!"
            )
        )
    ) else (
        set "file_path=%USERPROFILE%\Kyocera_Commands\66_line_mode.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! FRPO U0,6; FRPO U1,66; EXIT;">"!file_path!"
            )
        )
    )
    call :lpr_command "%passed_ip%" "!file_path!"
    color
    exit

:toggle_tray_switch

    if "%~2"=="6" (
        set "file_path=%USERPROFILE%\Kyocera_Commands\tray_switch_on.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! FRPO X9,9; FRPO R2,0; EXIT;">"!file_path!"
            )
        )
    ) else (
        set "file_path=%USERPROFILE%\Kyocera_Commands\tray_switch_off.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! FRPO X9,0; FRPO R2,0; EXIT;">"!file_path!"
            )
        )
    )
    call :lpr_command "%passed_ip%" "!file_path!"
    color
    exit

:toggle_sleep_timer

    if "%~2"==8 (
        set "file_path=%USERPROFILE%\Kyocera_Commands\sleep_timer_on.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! FRPO N5,1; EXIT;">"!file_path!"
            )
        )
    ) else (
        set "file_path=%USERPROFILE%\Kyocera_Commands\sleep_timer_off.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! FRPO N5,0; EXIT;">"!file_path!"
            )
        )
    )
    call :lpr_command "%passed_ip%" "!file_path!"
    color
    exit

:backup_initialize

    if "%~2"==10 (
        set "file_path=%USERPROFILE%\Kyocera_Commands\initialize.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! STAT 1; EXIT;">"!file_path!"
            )
        )
    ) else (
        set "file_path=%USERPROFILE%\Kyocera_Commands\backup.txt"
        if not exist "!file_path!" (
            (
                echo | set /p="!R! FRPO INIT; EXIT;">"!file_path!"
            )
        )
    )
    call :lpr_command "%passed_ip%" "!file_path!"
    color
    exit

:: Uses LPR to send the command to the Device
:: Does ping the device first to see if it is reachable

:lpr_command

	set "passed_ip=%~1"
	set "passed_command=%~2"

	where lpr >nul

	if %ERRORLEVEL%==1 (
		echo.
		echo LPR is not enabled, please enable LPR...
		echo   Turn Windows Features On or Off ^>
		echo   Print and Document Services ^>
		echo   LPR Port Monitor ^>
		echo   Restart Device
		call :error_exit "[LPR_NOT_ENABLED_ERROR]"
	)

	ping %passed_ip% -n 2 | findstr /i "Destination host unreachable."

	if %ERRORLEVEL%==0 (
		call :error_exit "[NO_PING_NETWORK_ERROR]"
		color
		exit
	)

	lpr -S %passed_ip% -P 9100 "%passed_command%" >nul 2>&1
	echo.
	<nul set /p "=Sending Command"
		for /l %%i in (1,1,4) do (
			<nul set /p "=."
			timeout /t 1 >nul
		)
	echo .
	timeout /t 1 >nul

	echo Command sent. Press any key to exit...
	pause>nul | echo.
	color
	exit

:: Here is a list of all pre-programmed error codes that can be experienced

:print_error_codes
	echo.
	echo Here is a list of the error codes and what they mean...
	echo.

	echo ERROR_CODE: INVALID_IP_CHOICE_ERROR
	echo DESCRIPTION: Invalid menu choice at Declared IP vs Passed IP.
	echo.
	echo ERROR_CODE: IP_MISSING_OCTET_ERROR
	echo DESCRIPTION: The IP address is missing one or more octets.
	echo EXAMPLE: 192.168.1. or 192..1.25
	echo.
	echo ERROR_CODE: IP_EXCESS_OCTET_ERROR
	echo DESCRIPTION: The IP address has too many octets.
	echo EXAMPLE: 19.2.168.1.25
	echo.
	echo ERROR_CODE: IP_INVALID_OCTET_ERROR
	echo DESCRIPTION: The IP address contains an invalid octet.
	echo EXAMPLE: 192.1680.1.25
	echo.
	echo ERROR_CODE: LPR_NOT_ENABLED_ERROR
	echo DESCRIPTION: LPR is not enabled.
	echo Please enable LPR and run again.
	echo.
	echo ERROR_CODE: NO_PING_NETWORK_ERROR
	echo DESCRIPTION: Could not ping device.
	echo Please double check network connectivity.
	echo.
	echo ERROR_CODE: INVALID_COMMAND_CHOICE_ERROR
	echo DESCRIPTION: Invalid menu choice at Command Prompt.
	echo.
	echo Press any key to exit...
	pause>nul | echo.
	color
	exit

:: Intentional exit of the program in case of a pre-programmed error

:error_exit
	echo.
	echo %~1 Press any key to exit...
	pause>nul | echo.
	color
	exit

:eof