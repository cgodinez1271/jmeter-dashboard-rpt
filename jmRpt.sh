#!/usr/bin/env bash
# Carlos A. Godinez
#Tue Nov 17 11:53:16 EST 2020
set -e

GRANULARITY=10000
PID=$$

if [[ "$#" -eq 1 && -f "$1" && "$1" =~ \.jtl$ ]]; then

    path_to_jmeter=$(which jmeter)
    jtl_file="$1"

    if [[ -x "$path_to_jmeter" ]]; then
        # create report directory 
        dashboard_dir=$(/usr/local/opt/coreutils/libexec/gnubin/date +"%Y-%m-%d_%T.%3N")
        mkdir $dashboard_dir

        # rename jmeter.log if it contains the jmx filename
        if [[ -f jmeter.log ]]; then
            jmx_file=$(grep '.jmx' jmeter.log | cut -d ' ' -f 7)
            [[ "$jmx_file" ]] && mv jmeter.log jmeter.$PID
        fi    

        # build dashboard report
        $path_to_jmeter \
             -g $jtl_file \
             -o $dashboard_dir \
             -Jjmeter.reportgenerator.overall_granularity=$GRANULARITY

        # move jtl & jmx files to dashboard directory
        mv $jtl_file $dashboard_dir
        [[ "$jmx_file" ]] && cp $jmx_file $dashboard_dir
        [[ -f errors.xml ]] && mv errors.xml $dashboard_dir
        [[ -f jmeter.$PID ]] && mv jmeter.$PID $dashboard_dir/jmeter.log

      else
        echo "$0: Jmeter executable not found"
        exit 1
    fi
else
    echo "Usage: $0 jmeter-file.jtl"
    exit 1
fi
echo "Report located in $dashboard_dir"
