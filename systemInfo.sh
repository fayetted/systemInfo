#!/usr/bin/env sh
#//////////////////////////////////////////////////////////////////
# Dan Fayette   mailto:fayetted@google.com                      ///
# 20120620                                                      ///
# File: systemInfo.sh                                           ///
# Purpose: Script to print out info about the OS                ///
#                                                               ///
#                                                               ///
# Required Files:                                               ///
#//////////////////////////////////////////////////////////////////

osVersion=`lsb_release -d | cut -f2-`

systemArch=`arch`
if [ $systemArch = "i686" ]; then
    systemArch=$systemArch" - 32 Bit"
elif [ $systemArch = "x86_64" ]; then
    systemArch=$systemArch" - 64 Bit"
else
    systemArch=$systemArch" - Unknown"
fi

procNum=`cat /proc/cpuinfo | egrep "processor" | tail -1 | awk '{print $NF}'`
procNum=$(expr $procNum + 1)

procType=`cat /proc/cpuinfo | egrep "model name" | sort | uniq | cut -f3- -d' ' | sed 's/[ \t]\+/_/g'`

memSize=`grep MemTotal /proc/meminfo | awk '{print $2}'`
memSize=`echo "scale=2; $memSize / 1000" | bc`
# Bash doesn't handle floating points well so we do what we need in awk
    # If the mem size is less than 1,000 then print the raw size + "MB"
    # If the mem size is greater than 1GB then divide the raw number by 1,000 and 
    # print it as a floating point with 2 decimal places.
memSize=`echo "$memSize 1000" | awk '{if ($1 < 1000) print $1" MB"; else printf("%.2f%3s\n",$1/$2, "GB")}'`

printf "OS_Version:\t%-15s\n" "$osVersion"
printf "OS_Arch:\t%-15s\n" "$systemArch"
printf "Proc_Num:\t%-15s\n" "$procNum"
printf "Proc_Type:\t%-15s\n" "$procType"
printf "Mem_Size:\t%-15s\n" "$memSize"

echo ""
echo  "Network:"
printf "%12s\t%16s\t%15s\t%15s\n" "Interface" "MAC" "IP" "Speed"


for INT in `ifconfig -a | awk '$0~"^[a-z]" {print $1}'`
do
    MAC=None
    IP=None
    SPEED=None
    MAC=`ifconfig $INT | grep -i hwaddr | awk '{print $NF}'`
    MAC=`echo $MAC | awk '{if ($1 != "00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00") print $MAC; else print "00-00-00-00-00-00"}'`
    if [ "${MAC}" = "" ]; then
        MAC="None"
    fi

    IP=`ifconfig $INT | grep inet | cut -d':' -f2 | cut -d' ' -f1`
    if [ "$IP" = "" ]; then
        IP="None"
    fi

    printf "%12s\t%16s\t%15s\t%15s\n" $INT $MAC $IP $SPEED
done


                   
if [ `whoami` = "root" ]; then
    echo ""
    echo "Memory:"
    printf "\t|%4s|%8s|%10s|%18s|\n" "Qty" "Size" "Width" "Clock"
    printf "\t|%4s|%8s|%10s|%18s|\n" ____ ________ __________ __________________
    printf "\t|%4s|%8s|%10s|%18s|\n" `sudo lshw -C memory 2>/dev/null | sed -n '/-bank:/,/clock:/p' | egrep "size:|width:|clock:" | sed s'/^ *\w*: //g' | sed 's/ /_/g' | perl -pi -e 's/\n/ / if $.%3' | sort | uniq -c`
    printf "\t|%4s|%8s|%10s|%18s|\n" ____ ________ __________ __________________
else
    printf "\nAdditional information is availabe if you run this script as root\n"
fi
