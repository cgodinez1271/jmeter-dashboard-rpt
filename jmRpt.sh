#!/usr/bin/env bash
#Fri Sep 25 23:02:44 EDT 2020
set -e
#set -x

#TODO: -Jjmeter.reportgenerator.overall_granularity=1000 -Jjmeter.reportgenerator.report_title="My Report"

if [[ "$#" -eq 1 && -f "$1" && "$1" =~ \.jtl$ ]]; then

    path_to_jmeter=$(which jmeter)
    jtl_file="$1"

    if [[ -x "$path_to_jmeter" ]]; then
		# create report directory 
		dashboard_dir=$(/usr/local/opt/coreutils/libexec/gnubin/date +"%Y-%m-%d_%T.%3N")
		mkdir $dashboard_dir

		# save jmeter.log y jmx files
		if [[ -f jmeter.log ]]; then
			jmx_file=$(grep '.jmx' jmeter.log | cut -d ' ' -f 7)
			mv jmeter.log "jmeter.$$"
		fi

		# build dashboard report
		$path_to_jmeter -g $1 -o $dashboard_dir

		# move jtl & jmx files to dashboard directory
		mv $jtl_file $dashboard_dir
		cp jmx_file $dashboard_dir

		# move the jmeter.log to dashboard directory
		mv "jmeter.$$" "$dashboard_dir/jmeter.log"
  	else
		echo "$0: Jmeter executable not found"
		exit 1
    fi
else
    echo "Usage: $0 jmeter-file.jtl"
    exit 1
fi
echo "Report located in $dashboard_dir"
