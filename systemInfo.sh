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

if [ -f "/etc/redhat-release" ]; then
    osVersion=`cat /etc/redhat-release`
else
    osVersion=`lsb_release -d | cut -f2-`
fi

if [ "$osVersion" = "" ]; then
    osVersion="Unknown"
fi

systemArch=`arch`
if [ $systemArch = "i686" ]; then
    systemArch=$systemArch" - 32 Bit"
elif [ $systemArch = "x86_64" ]; then
    systemArch=$systemArch" - 64 Bit"
else
    systemArch=$systemArch" - Unknown"
fi

vid=`lspci | grep -i vga | awk -F: '{print $3}' | sed 's/^ //'`

procType=`cat /proc/cpuinfo | egrep "model name" | sort | uniq | cut -f3- -d' ' | sed 's/[ \t]\+/_/g'`
procNum=`cat /proc/cpuinfo | egrep "processor" | tail -1 | awk '{print $NF}'`
procNum=$(expr $procNum + 1)
procFSB=`grep "cpu MHz" /proc/cpuinfo  | awk '{print $NF}' | awk -F"." '{print $1}' | tail -1`


memSize=`grep MemTotal /proc/meminfo | awk '{print $2}'`
memSize=`echo "scale=2; $memSize / 1000" | bc`
# Bash doesn't handle floating points well so we do what we need in awk
    # If the mem size is less than 1,000 then print the raw size + "MB"
    # If the mem size is greater than 1GB then divide the raw number by 1,000 and
    # print it as a floating point with 2 decimal places.
memSize=`echo "$memSize 1000" | awk '{if ($1 < 1000) print $1" MB"; else printf("%.2f%3s\n",$1/$2, "GB")}'`


echo ""
echo "OS:"
printf "\t%8s\t%-15s\n" "Version:" "$osVersion"
printf "\t%-8s\t%-15s\n" "Arch:" "$systemArch"

echo ""
echo "Video:"
echo "$vid" | while read card; do printf "\t%-50s\n" "$card"; done

#
## Extra info if you run as root.
#
if [ `whoami` = "root" ]; then
    echo ""
    echo "Memory:"

    if [ "`echo $osVersion | awk '{print $1}'`" = "CentOS" ]; then
        printf "\t| %6s | %10s | %10s |\n" "Qty" "Size" "Width"
        printf "\t| %6s | %10s | %10s |\n" ______ __________ __________
        printf "\t| %6s | %10s | %10s |\n" `lshw -C memory 2>/dev/null | sed -n '/-bank:/,/clock:/p' | egrep "bank:|size:|width:|clock:" | sed 's/^ *//' | sed 's/ /_/g' | se
d 's/^*-//g' | sed 's/width:_//; s/clock:_//' | awk '/size/{printf $0" ";next;}1' | sed '/^bank\:[0-9]*/d' | sed 's/size:_//g' | sort | uniq -c`
        printf "\t| %6s | %10s | %10s |\n" ______ __________ __________
        printf "\t| %6s | %10s |\n" "Total:" "$memSize"
    else
        printf "\t| %6s | %10s | %10s | %18s |\n" "Qty" "Size" "Width" "Clock"
        printf "\t| %6s | %10s | %10s | %18s |\n" ______ __________ __________ __________________
        printf "\t| %6s | %10s | %10s | %18s |\n" `lshw -C memory 2>/dev/null | sed -n '/-bank:/,/clock:/p' | egrep "bank:|size:|width:|clock:" | sed 's/^ *//' | sed 's/ /_/g' | sed 's/^*-//g' | sed 's/width:_//; s/clock:_//' | awk '/size/{printf $0" ";next;}1'| awk '/size/{printf $0" ";next;}1' | awk '/bits$/{printf $0" ";next;}1' | awk '/bank/{printf $0" ";next;}1' | sed 's/^bank:\w*/bank/g' | sed 's/bank size:_//g' | sed 's/bank /empty /g' | sort | uniq -c`
        printf "\t| %6s | %10s | %10s | %18s |\n" ______ __________ __________ __________________
        printf "\t| %6s | %10s |\n" "Total:" "$memSize"
    fi
else

    echo ""
    echo "Memory:"
    printf "\t%6s  %10s\n" "Total:" "$memSize"

fi

echo ""
echo "CPU:"
printf "\t| %50s | %8s | %8s |\n" "CPU" "FSB" "Cores"
printf "\t| %50s | %8s | %8s |\n" -------------------------------------------------- -------- --------
printf "\t| %50s | %8s | %8s |\n" $procType $procFSB $procNum
printf "\t| %50s | %8s | %8s |\n" -------------------------------------------------- -------- --------

echo ""
echo  "Network:"
printf "\t| %12s | %17s | %15s | %15s |\n" "Interface" "MAC" "IP" "Speed"
printf "\t| %12s | %17s | %15s | %15s |\n" ------------ ----------------- --------------- ---------------

for INT in `ifconfig -a | awk '$0~"^[a-z]" {print $1}'`
do
    MAC=None
    IP=None
    MAC=`ifconfig $INT | grep -i hwaddr | awk '{print $NF}'`
    MAC=`echo $MAC | awk '{if ($1 != "00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00") print $MAC; else print "00-00-00-00-00-00"}'`
    if [ "${MAC}" = "" ]; then
        MAC="None"
    fi

    IP=`ifconfig $INT | grep inet | cut -d':' -f2 | cut -d' ' -f1`
    if [ "$IP" = "" ]; then
        IP="None"
    fi

    SPEED=`mii-tool $INT 2>/dev/null | sed 's/.*negotiat.*\(1.*\).*flow.*/\1/g'`
    if [ "$SPEED" = "" ]; then
        SPEED="N/A"
    fi
    if [ "$SPEED" = "$INT: no link" ]; then
        SPEED="no_link"
    fi

    printf "\t| %12s | %17s | %15s | %15s |\n" $INT $MAC $IP $SPEED
done

if [ `whoami` != "root" ]; then
    printf "\n\n\t*** Additional information is availabe if you run this script as root ***\n"
fi

echo ""
