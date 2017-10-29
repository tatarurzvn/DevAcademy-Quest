#!/bin/bash

#The number of apache2 processes is stored here
NBR_PROCS=`ps cax | grep apache2 | wc -l`

#The port number of apache2 is stored here
PORT_NBR=`lsof -Pni | grep -i apache2 | awk '{print $9}' | sed "s/.*://g"`
PORT_WANTED=80

#The URL status is stored here
URL_STAT="`curl -Is localhost | head -n1 | awk '{print $2}'`"
URL_STAT_WANTED=200

#Number of OK checks
OK_CHECKS=0

#LOG file name
LOG_FILE="/home/DeAcademy-Quest/ok_logs.txt"

#Mail addresses
ADDR_1="tatarurzvn@hotmail.com"
ADDR_2="daniel.dinca@devacademy.ro"

if [ $NBR_PROCS -eq 0 ]
then
	echo "No apache2 processes are running at this moment."
else
	OK_CHECKS=$((OK_CHECKS+1))
fi

if [ "$PORT_NBR" != "$PORT_WANTED" ]
then
	echo "Apache is not using port 80!"
else	
	OK_CHECKS=$((OK_CHECKS+1))
fi

if [ "$URL_STAT" != "$URL_STAT_WANTED" ]
then
	echo "The URL status code returned is: $URL_STAT"
else	
	OK_CHECKS=$((OK_CHECKS+1))
fi

echo "$OK_CHECKS" >> $LOG_FILE

# This part attempts to restart the apache server if something failed

if [ "$OK_CHECKS" -ne 3 ]
then
	`echo "The server failed the check once" | ssmtp $ADDR_1`
	echo "Restarting apache...\n\n"
	`/etc/init.d/apache2 restart`
	echo "\n\nApache restarted"
 
fi

#	The following lines will check if the number of rows in "ok_logs.txt" is 
# greater than 6.
#	If so, the script will only keep the last 5 results in order not to 
# overpopulate the log file

NBR_BAD_LOGS=`grep -v "3" ok_logs.txt | wc -l`
LOG_FILE_ROWS=`cat ok_logs.txt | wc -l`

if [ $LOG_FILE_ROWS -gt 5 ]
then
	`tail -n5 ok_logs.txt > "$LOG_FILE.tmp" \
	&& mv "$LOG_FILE.tmp" "$LOG_FILE"`
fi

#	This part will send the actual email if the script failed more than five
# times and clear all the logs file

if [ $NBR_BAD_LOGS -eq 5 ]
then
	`/etc/init.d/apache2 restart`
        `echo "The server failed the check five times!" | ssmtp $ADDR_2`
	`> $LOG_FILE`
fi

