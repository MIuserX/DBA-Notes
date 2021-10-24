@echo off

set workdir=D:\pg_backup
set pg_basebackup_exe=C:\Program Files\PostgreSQL\bin\pg_basebackup.exe
set PGPASSWORD=dcsm8523

D:
cd D:\
if exist %workdir% (
    cd %workdir%
) else (
    exit
)

call:aLogger "Log","---- backup begin ----"

::---- delete 3-days-ago backup directory
set prefix=bak_
for /F %%i in ('dateCompution.exe') do set delete_one=%prefix%%%i
call:aLogger "Log","-- remove %delete_one%"
if not exist %delete_one% (
    call:aLogger "Warning","directory `%delete_one%` not exist"
) else (
    rd /S /Q %delete_one%
    if not exist %delete_one% (
        call:aLogger "Log","== remove OK"
    ) else (
        call:aLogger "Error","== remove failed"
    )
)

::---- backup and update
set bak_name=%prefix%%date:~0,4%%date:~5,2%%date:~8,2%
call:force_mk_bak_dir %bak_name%
call:do_basebackup %bak_name%


:end
call:aLogger "Log","---- backup end ----"
exit

:aLogger
if exist log.txt (
    echo "[ %date% %time% ] %1: %2" >> log.txt
) else (
    echo "[ %date% %time% ] %1: %2" > log.txt
)
goto:eof

:force_mk_bak_dir
call:aLogger "Log","-- mkdir `%1`"
if exist %1 (
    call:aLogger "Warning","directory `%1` already exists"
) else (
    mkdir %1
    if not exist %1 (
        call:aLogger "Error","== mkdir failed"
        goto:end
    ) else (
        call:aLogger "Log","== mkdir OK"
    )
)
goto:eof

:do_basebackup
call:aLogger "Log","-- do basebackup"
pg_basebackup.exe -h 127.0.0.1 -p 5430 -U replica1 -D %1 -F t -R -z -c fast
set arg1=%1
set suffix=\base.tar.gz
set tname=%arg1%%suffix%
if exist %tname% (
    call:aLogger "Log","== do basebackup OK"
) else (
    call:aLogger "Error","== do basebackup failed"
)
goto:eof