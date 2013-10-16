#!/bin/bash

path=$1

pid=`cat $path/pid`

echo > $path/stats.txt

while true; do


    if [ ! -d /proc/$pid ]; then
	echo "Training ended. Exiting"
	rm $path/pid
	exit
    fi

    # I'm not proud to this
    cpu=`top -b -n 1 | grep $pid | grep "opencv" | awk '{print($9)}'`
    vsz=`ps -p $pid -o pcpu,vsz,rss | tail -n 1 | awk '{print($2)}'`
    rss=`ps -p $pid -o pcpu,vsz,rss | tail -n 1 | awk '{print($3)}'`
    lines=`cat $path/logs.txt | wc -l`
    threads=`ps -o nlwp $pid | tail -n 1 | egrep -o '[0-9]+'`
    files=`lsof -p $pid | wc -l`
    stamp=`date +%s`

    line="$stamp $cpu $vsz $rss $lines $threads $files"

    echo $line >> $path/stats.txt

    sleep 1
done
