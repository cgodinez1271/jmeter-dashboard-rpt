#!/usr/bin/env perl -w

=head1 NAME

aix_nmon_cap_anal_rev1.pl - time series data to capacity planning information

=head1 SYNOPSIS

aix_nmon_cap_anal_rev1.pl server_name

=head1 DESCRIPTION

This script converts time series data to capacity planning information

=head1 OPTIONS

 -a create statistical average files
 -c create comma delimited files
 -d create data rows
 -g create graph files
 -h display help text
 -m let avg graph scale float
 -p create header rows
 -r rev number (default is 1)
 -s switch graph colors (bars and background)
 -w process weekday data (M-F)
 -y do not remove first data sample

=head1 EXAMPLES

 aix_nmon_cap_anal_rev1.pl server_name
 aix_nmon_cap_anal_rev1.pl -cwr 2 server_name
 aix_nmon_cap_anal_rev1.pl -p server_name > out1p.txt
 aix_nmon_cap_anal_rev1.pl -d server_name > out1d.txt

=cut

##########################################################################
# Perl Script:                                                           #
# Purpose:   Convert Time Series Data Into Capacity Planning Information #
# Author:    James F Brady                                               #
# Copyright: © Copyright 2013, James F Brady, All rights reserved        #
##########################################################################
require 5.004;
use strict;
#use lib "$ENV{CMG13_S214}";
use lib '/Users/carlos/bin';
use Getopt::Std;
use POSIX;
use GraphPNG;
use vars qw($opt_a $opt_c $opt_d $opt_g $opt_h $opt_m
            $opt_p $opt_r $opt_s $opt_w $opt_y);

##############################################
# Default graphical scale - max y_axis value #
##############################################
my($scale_cpu1)=100;
my($scale_cpu2)=1;
my($scale_lpar1)=1;
my($scale_lpar2)=1;
my($scale_pools1)=1;
my($scale_pools2)=1;
my($scale_pools3)=1;
my($scale_pools4)=1;
my($scale_mem_free1)=10;
my($scale_mem_used1)=10;
my($scale_proc1)=10;
my($scale_proc2)=10;
my($scale_disk1)=10;
my($scale_disk2)=10;
my($scale_pkt1)=10;
my($scale_pkt2)=10;

##############################################
# Range variable settings                    #
##############################################
my($max) = 9999999;
my(%max_stats) = ('CPU_ALL1'=>100,
                  'CPU_ALL2'=>100,
                  'LPAR1'=>100,
                  'LPAR2'=>100,
                  'POOLS1'=>100,
                  'POOLS2'=>100,
                  'POOLS3'=>100,
                  'POOLS4'=>100,
                  'MEM_FREE1'=>999999,
                  'MEM_USED1'=>999999,
                  'PROC_PROCESS1'=>999999,
                  'PROC_QUEUE1'=>999999,
                  'DISK_READ1'=>999999,
                  'DISK_WRITE1'=>999999,
                  'PKT_RCV1'=>999999,
                  'PKT_XMIT1'=>999999);

##################################
# Script index defaults          #
##################################
my($cpu1_index)=4;
my($cpu2_index)=6;
my($lpar1_index)=1;
my($lpar2_index)=5;
my($pools1_index)=4;
my($pools2_index)=5;
my($pools3_index)=6;
my($pools4_index)=7;
my($mem_free1_index)=3;
my($mem_total1_index)=5;
my($proc_process_index)=3;
my($proc_queue_index)=1;

##################################
# Initialized Script variables   #
##################################
my($skip_sample)="T0001";
my($dircsv)="CapCsv"; 
my($diravg)="CapAvg"; 
my($dirgrh)="CapGraph"; 
my($direrr)="CapErr"; 
my($rev)=1; 
my($format)='%.2f';
my(%month) = ('JAN'=>'01','FEB'=>'02','MAR'=>'03',
              'APR'=>'04','MAY'=>'05','JUN'=>'06',
              'JUL'=>'07','AUG'=>'08','SEP'=>'09',
              'OCT'=>'10','NOV'=>'11','DEC'=>'12');

###########################################################################
# Action: Enter Valid Machine Serial Number Instead of XXXXXXX or YYYYYYY #
###########################################################################
my(%serial_val) = ('XXXXXXX'=>'sysxx',
                   'YYYYYYY'=>'sysyy');
my($pool_id)=0;

#############################
# Script variables          #
#############################
my($infile);
my($infile_list_ref);
my($system_name);
my($sys_val);
my($sys);
my($serial);
my($date_yyyymmdd);
my($date_val);
my($date_day);
my($date_month);
my($date_year);
my($date_dow);
my($date_beg);
my($date_beg1);
my($date_beg2);
my($date_end);
my($date_end1);
my($date_end2);
my($date_all);
my($yyyymmdd);
my($day1);
my($month1);
my($year1);
my($sub_title);
my($outgraph);
my($color_switch);
my($y_max);
my($sample);
my($i);

my(%time);
my($time_hour);
my($time_min);
my($time_sec);
my($time_val);
my($time_day);
my($time_mon);
my($time_year);
my($time_date_val);

my(@headers);
my(@samples);
my($label);
my(@data);
my($val);
my($sample_val);
my($att_ref);
my(@errors);
my($er);

my(%cpu);
my(@cpu_list);
my($cpu1);
my(@cpu1_days);
my($cpu1_avg);
my($cpu1_max);
my($cpu1_min);
my($cpu1_avg2);
my($cpu1_max2);
my($cpu1_min2);
my($cpu2);
my(@cpu2_days);
my($cpu2_avg);
my($cpu2_max);
my($cpu2_min);
my($cpu2_avg2);
my($cpu2_max2);
my($cpu2_min2);

my(%lpar);
my(@lpar_list);
my($lpar1);
my(@lpar1_days);
my($lpar1_avg);
my($lpar1_max);
my($lpar1_min);
my($lpar1_avg2);
my($lpar1_max2);
my($lpar1_min2);
my($lpar2);
my(@lpar2_days);
my($lpar2_avg);
my($lpar2_max);
my($lpar2_min);
my($lpar2_avg2);
my($lpar2_max2);
my($lpar2_min2);

my(%pools);
my(@pools_list);
my($pools1);
my(@pools1_days);
my($pools1_avg);
my($pools1_max);
my($pools1_min);
my($pools1_avg2);
my($pools1_max2);
my($pools1_min2);
my($pools2);
my(@pools2_days);
my($pools2_avg);
my($pools2_max);
my($pools2_min);
my($pools2_avg2);
my($pools2_max2);
my($pools2_min2);
my($pools3);
my(@pools3_days);
my($pools3_avg);
my($pools3_max);
my($pools3_min);
my($pools3_avg2);
my($pools3_max2);
my($pools3_min2);
my($pools4);
my(@pools4_days);
my($pools4_avg);
my($pools4_max);
my($pools4_min);
my($pools4_avg2);
my($pools4_max2);
my($pools4_min2);

my(%mem);
my(@mem_list);
my($mem_free);
my(@mem_free_days);
my($mem_free1_avg);
my($mem_free1_max);
my($mem_free1_min);
my($mem_free1_avg2);
my($mem_free1_max2);
my($mem_free1_min2);
my($mem_used);
my(@mem_used_days);
my($mem_used1_avg);
my($mem_used1_max);
my($mem_used1_min);
my($mem_used1_avg2);
my($mem_used1_max2);
my($mem_used1_min2);

my(%proc);
my(@proc_list);
my($proc_process);
my($proc_queue);
my(@proc_process_days);
my(@proc_queue_days);
my($proc_process1_avg);
my($proc_process1_max);
my($proc_process1_min);
my($proc_process1_avg2);
my($proc_process1_max2);
my($proc_process1_min2);
my($proc_queue1_avg);
my($proc_queue1_max);
my($proc_queue1_min);
my($proc_queue1_avg2);
my($proc_queue1_max2);
my($proc_queue1_min2);

my(%diskr);
my(@diskr_list);
my($disk_read);
my(@disk_read_days);
my($disk_read1_avg);
my($disk_read1_max);
my($disk_read1_min);
my($disk_read1_avg2);
my($disk_read1_max2);
my($disk_read1_min2);

my(%diskw);
my(@diskw_list);
my($disk_write);
my(@disk_write_days);
my($disk_write1_avg);
my($disk_write1_max);
my($disk_write1_min);
my($disk_write1_avg2);
my($disk_write1_max2);
my($disk_write1_min2);

my(%packet);
my(@packet_list);
my($packet_rcv);
my($packet_xmit);
my(@packet_rcv_days);
my(@packet_xmit_days);
my($pkt_rcv1_avg);
my($pkt_rcv1_max);
my($pkt_rcv1_min);
my($pkt_rcv1_avg2);
my($pkt_rcv1_max2);
my($pkt_rcv1_min2);
my($pkt_xmit1_avg);
my($pkt_xmit1_max);
my($pkt_xmit1_min);
my($pkt_xmit1_avg2);
my($pkt_xmit1_max2);
my($pkt_xmit1_min2);

my($stat_max);
my($stat_avg);
my(@stats_avg);

################################
# Check command line options   #
################################
getopts('acdghmpr:swy');

################################
# Display help text            #
################################
if ($opt_h)
{
  system ("perldoc",$0);
  exit 0;
}

#########################################
# Check if any arguments set            #
#########################################
if (!@ARGV or @ARGV gt 1)
{
  die "\nUsage: $0 [opt-acdghmpr:swy] - one argument required\n\n";
}

################################
# Get system name              #
################################
$system_name = shift @ARGV;

################################
# Create input file list       #
################################
$infile_list_ref = create_infile_list('.',$system_name);
if (!@$infile_list_ref)
{
  print "Error - No input files\n";
  exit(1);
}

################################
# If rev number set            #
################################
if ($opt_r)
{
  $rev = $opt_r;
}

####################################
# If graph color switch option set #
####################################
if ($opt_s)
{
  $color_switch = $opt_s;
}

###########################################
# Do not remove first data sample - T0001 #
###########################################
if ($opt_y)
{
  $skip_sample = "T9999";
}

################################
# Print heading                #
################################
print "\n\nAIX Nmon Statistics - aix_nmon_cap_anal_rev1.pl\n";
print     "-------------------\n";

################################
# Process input file list      #
################################
INPUT_FILE: foreach $infile (@$infile_list_ref)
{
  if (!open INFILE,$infile)
  {
    print "Error - $infile failed to open\n"; 
    next;
  }
  else
  {
    print "  - $infile\n";
  }

  ################################
  # Read input file              #
  ################################
  while (<INFILE>)
  {
    chomp $_;

    ################################
    # System Serial Number         #
    ################################
    if ($_ =~ /,SerialNumber,/)
    {
      (undef,undef,$serial) = split(',',$_);
    }

    ################################
    # LPAR Pool id                 #
    ################################
    if ($_ =~ /,pool id,/)
    {
      (undef,undef,undef,$pool_id) = split(',',$_);
    }

    ################################
    # System Name                  # 
    ################################
    if ($_ =~ /,runname,/)
    {
      (undef,undef,$sys_val) = split(',',$_);

      ################################
      # Check against list           # 
      ################################
      if ($sys_val ne $system_name)
      {
        next INPUT_FILE;
      }
    }

    ################################
    # Date                         # 
    ################################
    if ($_ =~ /,date,/)
    {
      (undef,undef,$date_val) = split(',',$_);
      ($date_day,$date_month,$date_year) = split('-',$date_val);
      ($date_dow) = day_of_week($month{$date_month},$date_day,$date_year);
      ($date_yyyymmdd) = sprintf('%04d%02d%02d',$date_year,
                                                $month{$date_month},
                                                $date_day);
      ################################
      # Save date_beg and date_end   # 
      ################################
      if (!$date_beg)
      {
        $date_beg = join('-',$date_month,$date_day,$date_year);
        $date_end = join('-',$date_month,$date_day,$date_year);
        $date_beg1 = join('/',$month{$date_month},$date_day,$date_year);
        $date_end1 = join('/',$month{$date_month},$date_day,$date_year);
        $yyyymmdd = $date_yyyymmdd;
      }
      else
      {
        $date_end = join('-',$date_month,$date_day,$date_year);
        $date_end1 = join('/',$month{$date_month},$date_day,$date_year);
      }

      ########################################
      # Check if process only weekdays (M-F) # 
      ########################################
      if ($opt_w)
      {
        if ($date_dow eq 'SAT' or 
            $date_dow eq 'SUN' or
	    $date_dow eq 'ERR')
        {
          next INPUT_FILE;
        }
      }
    }

    ################################
    # Headers                      # 
    ################################
    if ($_ =~ /^CPU_ALL,C/ or
        $_ =~ /^LPAR,L/ or
        $_ =~ /^POOLS,M/ or
        $_ =~ /^MEM,M/ or
        $_ =~ /^PROC,P/ or
        $_ =~ /^DISKREAD,D/ or
        $_ =~ /^DISKWRITE,D/ or
        $_ =~ /^NETPACKET,N/)
    {
      
      ################################################
      # Set mem_free1 and mem_total1 index for Linux # 
      ################################################
      if ($_ =~ /^MEM,M/ and $_ =~ /,memfree,/)
      {
        $mem_free1_index = 5;
        $mem_total1_index = 1;
      }
      ########################
      # Put header on list   # 
      ########################
      push @headers,$_;
    }

    ################################
    # Time/Date Stamp row          #
    ################################
    if ($_ =~ /^ZZZZ,/)
    {
      (undef,$sample,$time_val,$time_date_val) = split(',',$_);

      ###################################
      # Skip Sample - T0001             #
      ###################################
      if ($sample eq $skip_sample)
      {
        next;
      }

      #####################################
      # Timestamp - Extract Time and Data #
      #####################################
      ($time_hour,$time_min,$time_sec) = split(':',$time_val);
      ($time_day,$time_mon,$time_year) = split('-',$time_date_val);

      ############################################################
      # Timestamp - Use Date row for date portion if available   #
      ############################################################
      if ($date_year and $date_month and $date_day and $month{$date_month})
      {
        $time{$sample} = sprintf('%04d%02d%02d%02d%02d%02d',
                              $date_year,$month{$date_month},$date_day,
                              $time_hour,$time_min,$time_sec);
        push @samples,$sample;
      }
      ###############################################################
      # Timestamp - Else use ZZZZ row for date portion if available #
      ###############################################################
      elsif ($time_year and $time_mon and $time_day and $month{$time_mon})
      {
        $time{$sample} = sprintf('%04d%02d%02d%02d%02d%02d',
                              $time_year,$month{$time_mon},$time_day,
                              $time_hour,$time_min,$time_sec);
        push @samples,$sample;
      }
      ###################################
      # Timestamp - Unable to construct #
      ###################################
      else
      {
        next;
      }
    }

    ################################
    # CPU_ALL row                  # 
    ################################
    if ($_ =~ /^CPU_ALL,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $cpu{$sample} = join ('|',$label,@data);
    }

    ################################
    # LPAR row                     # 
    ################################
    if ($_ =~ /^LPAR,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      pop @data; # Pop last data item because not used and huge for Linux #
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $lpar{$sample} = join ('|',$label,@data);
    }

    ################################
    # POOLS row                    # 
    ################################
    if ($_ =~ /^POOLS,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $pools{$sample} = join ('|',$label,@data);
    }

    ################################
    # MEM row                      # 
    ################################
    if ($_ =~ /^MEM,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $mem{$sample} = join ('|',$label,@data);
    }

    ################################
    # PROC row                     # 
    ################################
    if ($_ =~ /^PROC,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $proc{$sample} = join ('|',$label,@data);
    }

    ################################
    # DISKREAD row                 # 
    ################################
    if ($_ =~ /^DISKREAD,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $diskr{$sample} = join ('|',$label,@data);
    }

    ################################
    # DISKREAD row                 # 
    ################################
    if ($_ =~ /^DISKWRITE,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $diskw{$sample} = join ('|',$label,@data);
    }

    ################################
    # NETPACKET row                # 
    ################################
    if ($_ =~ /^NETPACKET,T/)
    {
      ($label,$sample,@data) = split(',',$_);
      if(error($max,\@data)){$er=join('->',$date_day,$_);push @errors,$er;next;}
      $packet{$sample} = join ('|',$label,@data);
    }
  } 
  close INFILE;

  ###################################
  # Print headers - opt_p           #
  ###################################
  if ($opt_p)
  {
    print_headers($sys_val,\@headers);
  }

  ###################################
  # Create time stamp lists         #
  ###################################
  foreach $sample_val (sort @samples)
  {
    ($val) = create_time_stamp_row($sample_val,\%time,\%cpu);
    if ($val) {push @cpu_list,$val};
    ($val) = create_time_stamp_row($sample_val,\%time,\%lpar);
    if ($val) {push @lpar_list,$val};
    ($val) = create_time_stamp_row($sample_val,\%time,\%pools);
    if ($val) {push @pools_list,$val};
    ($val) = create_time_stamp_row($sample_val,\%time,\%mem);
    if ($val) {push @mem_list,$val};
    ($val) = create_time_stamp_row($sample_val,\%time,\%proc);
    if ($val) {push @proc_list,$val};
    ($val) = create_time_stamp_row($sample_val,\%time,\%diskr);
    if ($val) {push @diskr_list,$val};
    ($val) = create_time_stamp_row($sample_val,\%time,\%diskw);
    if ($val) {push @diskw_list,$val};
    ($val) = create_time_stamp_row($sample_val,\%time,\%packet);
    if ($val) {push @packet_list,$val};
  }

  ###################################
  # Print data rows - opt_d         #
  ###################################
  if ($opt_d)
  {
    print_data_rows(\@cpu_list);
    print_data_rows(\@lpar_list);
    print_data_rows(\@pools_list);
    print_data_rows(\@mem_list);
    print_data_rows(\@proc_list);
    print_data_rows(\@diskr_list);
    print_data_rows(\@diskw_list);
    print_data_rows(\@packet_list);
  }

  ###################################
  # Create summary statistics       #
  ###################################
  if (@cpu_list)
  {
    ($cpu1) = compute_stats('CPU_ALL1',\@cpu_list);
    push @cpu1_days,$cpu1;
    ($cpu2) = compute_stats('CPU_ALL2',\@cpu_list);
    push @cpu2_days,$cpu2;
  }
  if (@lpar_list)
  {
    ($lpar1) = compute_stats('LPAR1',\@lpar_list);
    push @lpar1_days,$lpar1;
    ($lpar2) = compute_stats('LPAR2',\@lpar_list);
    push @lpar2_days,$lpar2;
  }
  if (@pools_list)
  {
    ($pools1) = compute_stats('POOLS1',\@pools_list);
    push @pools1_days,$pools1;
    ($pools2) = compute_stats('POOLS2',\@pools_list);
    push @pools2_days,$pools2;
    ($pools3) = compute_stats('POOLS3',\@pools_list);
    push @pools3_days,$pools3;
    ($pools4) = compute_stats('POOLS4',\@pools_list);
    push @pools4_days,$pools4;
  }
  if (@mem_list)
  {
    ($mem_free) = compute_stats('MEM_FREE1',\@mem_list);
    push @mem_free_days,$mem_free;
    ($mem_used) = compute_stats('MEM_USED1',\@mem_list);
    push @mem_used_days,$mem_used;
  }
  if (@proc_list)
  {
    ($proc_process) = compute_stats('PROC_PROCESS1',\@proc_list);
    push @proc_process_days,$proc_process;
    ($proc_queue) = compute_stats('PROC_QUEUE1',\@proc_list);
    push @proc_queue_days,$proc_queue;
  }
  if (@diskr_list)
  {
    ($disk_read) = compute_stats('DISK_READ1',\@diskr_list);
    push @disk_read_days,$disk_read;
  }
  if (@diskw_list)
  {
    ($disk_write) = compute_stats('DISK_WRITE1',\@diskw_list);
    push @disk_write_days,$disk_write;
  }
  if (@packet_list)
  {
    ($packet_rcv) = compute_stats('PKT_RCV1',\@packet_list);
    push @packet_rcv_days,$packet_rcv;
    ($packet_xmit) = compute_stats('PKT_XMIT1',\@packet_list);
    push @packet_xmit_days,$packet_xmit;
  }

  ###################################
  # Re-initialize lists and hashes  #
  ###################################
  initialize_variables();
}

################################
# No valid input files         #
################################
if (!$yyyymmdd)
{
  print "Error - No input files with lpar name = $system_name\n";
  exit(1);
}

###################################
# Set up sys = sysNNpNN           #
###################################
if ($serial and $serial_val{$serial})
{
  $sys = sprintf('%s%s%02d',$serial_val{$serial},'p',$pool_id);
}
else
{
  $sys = sprintf('%s%s%02d','sysxx','p',$pool_id);
}
$sys = join('_',$sys,$sys_val);

###################################
# Create Data Error File          #
###################################
if (@errors)
{
  $direrr = join('_',$direrr,$sys,$yyyymmdd);
  mkdir $direrr,0777;
  write_errors($direrr,$sys,'errors',$yyyymmdd,$rev,\@errors);
}

###################################
# create summary statistics       #
###################################
($cpu1_avg,$cpu1_avg2,
 $cpu1_max,$cpu1_max2,
 $cpu1_min,$cpu1_min2) = summary_stats(\@cpu1_days);
push @cpu1_days,$cpu1_avg2,$cpu1_max2,$cpu1_min2;
($cpu2_avg,$cpu2_avg2,
 $cpu2_max,$cpu2_max2,
 $cpu2_min,$cpu2_min2) = summary_stats(\@cpu2_days);
push @cpu2_days,$cpu2_avg2,$cpu2_max2,$cpu2_min2;
($lpar1_avg,$lpar1_avg2,
 $lpar1_max,$lpar1_max2,
 $lpar1_min,$lpar1_min2) = summary_stats(\@lpar1_days);
($lpar2_avg,$lpar2_avg2,
 $lpar2_max,$lpar2_max2,
 $lpar2_min,$lpar2_min2) = summary_stats(\@lpar2_days);
if ($lpar1_avg2 and $lpar1_max2 and $lpar1_min2)
{
  push @lpar1_days,$lpar1_avg2,$lpar1_max2,$lpar1_min2;
  push @lpar2_days,$lpar2_avg2,$lpar2_max2,$lpar2_min2;
}
($pools1_avg,$pools1_avg2,
 $pools1_max,$pools1_max2,
 $pools1_min,$pools1_min2) = summary_stats(\@pools1_days);
($pools2_avg,$pools2_avg2,
 $pools2_max,$pools2_max2,
 $pools2_min,$pools2_min2) = summary_stats(\@pools2_days);
($pools3_avg,$pools3_avg2,
 $pools3_max,$pools3_max2,
 $pools3_min,$pools3_min2) = summary_stats(\@pools3_days);
($pools4_avg,$pools4_avg2,
 $pools4_max,$pools4_max2,
 $pools4_min,$pools4_min2) = summary_stats(\@pools4_days);
if ($pools1_avg2 and $pools1_max2 and $pools1_min2)
{
  push @pools1_days,$pools1_avg2,$pools1_max2,$pools1_min2;
  push @pools2_days,$pools2_avg2,$pools2_max2,$pools2_min2;
  push @pools3_days,$pools3_avg2,$pools3_max2,$pools3_min2;
  push @pools4_days,$pools4_avg2,$pools4_max2,$pools4_min2;
}
($mem_free1_avg,$mem_free1_avg2,
 $mem_free1_max,$mem_free1_max2,
 $mem_free1_min,$mem_free1_min2) = summary_stats(\@mem_free_days);
push @mem_free_days,$mem_free1_avg2,$mem_free1_max2,$mem_free1_min2;
($mem_used1_avg,$mem_used1_avg2,
 $mem_used1_max,$mem_used1_max2,
 $mem_used1_min,$mem_used1_min2) = summary_stats(\@mem_used_days);
push @mem_used_days,$mem_used1_avg2,$mem_used1_max2,$mem_used1_min2;
($proc_process1_avg,$proc_process1_avg2,
 $proc_process1_max,$proc_process1_max2,
 $proc_process1_min,$proc_process1_min2) = summary_stats(\@proc_process_days);
push @proc_process_days,$proc_process1_avg2,$proc_process1_max2,$proc_process1_min2;
($proc_queue1_avg,$proc_queue1_avg2,
 $proc_queue1_max,$proc_queue1_max2,
 $proc_queue1_min,$proc_queue1_min2) = summary_stats(\@proc_queue_days);
push @proc_queue_days,$proc_queue1_avg2,$proc_queue1_max2,$proc_queue1_min2;
($disk_read1_avg,$disk_read1_avg2,
 $disk_read1_max,$disk_read1_max2,
 $disk_read1_min,$disk_read1_min2) = summary_stats(\@disk_read_days);
push @disk_read_days,$disk_read1_avg2,$disk_read1_max2,$disk_read1_min2;
($disk_write1_avg,$disk_write1_avg2,
 $disk_write1_max,$disk_write1_max2,
 $disk_write1_min,$disk_write1_min2) = summary_stats(\@disk_write_days);
push @disk_write_days,$disk_write1_avg2,$disk_write1_max2,$disk_write1_min2;
($pkt_rcv1_avg,$pkt_rcv1_avg2,
 $pkt_rcv1_max,$pkt_rcv1_max2,
 $pkt_rcv1_min,$pkt_rcv1_min2) = summary_stats(\@packet_rcv_days);
push @packet_rcv_days,$pkt_rcv1_avg2,$pkt_rcv1_max2,$pkt_rcv1_min2;
($pkt_xmit1_avg,$pkt_xmit1_avg2,
 $pkt_xmit1_max,$pkt_xmit1_max2,
 $pkt_xmit1_min,$pkt_xmit1_min2) = summary_stats(\@packet_xmit_days);
push @packet_xmit_days,$pkt_xmit1_avg2,$pkt_xmit1_max2,$pkt_xmit1_min2;

###################################
# Create csv directory and files  #
###################################
if ($opt_c)
{
  $dircsv = join('_',$dircsv,$sys,$yyyymmdd);
  mkdir $dircsv,0777;

  #################################################
  # CPU %Used                                     # 
  #################################################
  create_csv($dircsv,$sys,'cpu__BusyTotal',$yyyymmdd,$rev,\@cpu1_days);

  #################################################
  # Physical CPUs (No LPAR row - Linux )          #
  #################################################
  create_csv($dircsv,$sys,'cpu__PhysUsed',$yyyymmdd,$rev,\@cpu2_days);

  ###################################
  # Physical and Entitled CPUs      #
  ###################################
  if (@lpar1_days)
  {
    create_csv($dircsv,$sys,'cpu__PhysUsed',$yyyymmdd,$rev,\@lpar1_days);
    create_csv($dircsv,$sys,'cpu__Entitled',$yyyymmdd,$rev,\@lpar2_days);
  }

  ###################################
  # Pooled CPU Statistics           #
  ###################################
  if (@pools1_days)
  {
    create_csv($dircsv,$sys,'cpu_MyPoolMax',$yyyymmdd,$rev,\@pools1_days);
    create_csv($dircsv,$sys,'cpu_MyPoolUsed',$yyyymmdd,$rev,\@pools2_days);
    create_csv($dircsv,$sys,'cpu_SharedTotal',$yyyymmdd,$rev,\@pools3_days);
    create_csv($dircsv,$sys,'cpu_SharedUsed',$yyyymmdd,$rev,\@pools4_days);
  }

  ###################################
  # Non CPU Resources               #
  ###################################
  create_csv($dircsv,$sys,'mem_free1',$yyyymmdd,$rev,\@mem_free_days);
  create_csv($dircsv,$sys,'mem_used1',$yyyymmdd,$rev,\@mem_used_days);
  create_csv($dircsv,$sys,'proc_process1',$yyyymmdd,$rev,\@proc_process_days);
  create_csv($dircsv,$sys,'proc_queue1',$yyyymmdd,$rev,\@proc_queue_days);
  create_csv($dircsv,$sys,'disk_read1',$yyyymmdd,$rev,\@disk_read_days);
  create_csv($dircsv,$sys,'disk_write1',$yyyymmdd,$rev,\@disk_write_days);
  create_csv($dircsv,$sys,'pkt_rcv1',$yyyymmdd,$rev,\@packet_rcv_days);
  create_csv($dircsv,$sys,'pkt_xmit1',$yyyymmdd,$rev,\@packet_xmit_days);
}

###################################
# Create avg directory and files  #
###################################
if ($opt_a)
{
  $diravg = join('_',$diravg,$sys,$yyyymmdd);
  mkdir $diravg,0777;

  ####################################
  # Create date portion of file name #
  ####################################
  ($month1,$day1,$year1) = split ('\/',$date_beg1);
  ($date_beg2) = sprintf('%04d%02d%02d',$year1,$month1,$day1);
  ($month1,$day1,$year1) = split ('\/',$date_end1);
  ($date_end2) = sprintf('%04d%02d%02d',$year1,$month1,$day1);

  ###################################
  # Create Averages                 #
  ###################################
  if ($lpar1_avg2)
  {
    $stat_avg = join(',',$sys,'cpu_PhysUsed',$date_beg1,$date_end1,$lpar1_avg2);
    push @stats_avg,$stat_avg;
    $stat_avg = join(',',$sys,'cpu_Entitled',$date_beg1,$date_end1,$lpar2_avg2);
    push @stats_avg,$stat_avg;
  }
  else
  {
    $stat_avg = join(',',$sys,'cpu_PhysUsed',$date_beg1,$date_end1,$cpu2_avg2);
    push @stats_avg,$stat_avg;
  }
  $stat_avg = join(',',$sys,'mem_free',$date_beg1,$date_end1,$mem_free1_avg2);
  push @stats_avg,$stat_avg;
  $stat_avg = join(',',$sys,'mem_used',$date_beg1,$date_end1,$mem_used1_avg2);
  push @stats_avg,$stat_avg;
  create_stats_csv($diravg,$sys,'avg',$date_beg2,$date_end2,$rev,\@stats_avg);
}

###################################
# create graph files              #
###################################
if ($opt_g)
{
  ###################################
  # Create directory and graphs     #
  ###################################
  $dirgrh = join('_',$dirgrh,$sys,$yyyymmdd);
  mkdir "$dirgrh",0777;

  ###################################
  # Create graph subtitle           #
  ###################################
  if ($date_end)
  {
    $date_all = join(' thru ',$date_beg,$date_end);
  }
  else
  {
    $date_all = $date_beg;
  }
  $sub_title = join(' ',ucfirst($sys),$date_all);
  if ($opt_w) {$sub_title = join (' ',$sub_title,'(M-F)');}

  ###################################
  # % CPU Used                      #
  ###################################
  if ($cpu1_avg)
  {
    ($att_ref) = graph1('Avg Percent CPU Busy',
                        $sub_title,
                        'Hour',
                        'Avg Percent CPU Busy',
                        $scale_cpu1,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu__BusyTotal_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$cpu1_avg);

    ($att_ref) = graph1('Peak Percent CPU Busy',
                        $sub_title,
                        'Hour',
                        'Peak Percent CPU Busy',
                        $scale_cpu1,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu__BusyTotal_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$cpu1_max);
  }

  ###################################
  # Physical CPUs Used              #
  ###################################
  if ($cpu2_avg or $lpar1_avg)
  {
    ###################################
    # Use LPAR Row If Exist           #
    ###################################
    if (!$lpar1_avg)
    {
      $stat_avg = $cpu2_avg;
      $stat_max = $cpu2_max;
    }
    else
    {
      $stat_avg = $lpar1_avg;      
      $stat_max = $lpar1_max;      
    }
    #######################
    # Average             #
    #######################
    ($y_max) = set_graph_scale($scale_cpu2,$stat_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$stat_avg);}
    ($att_ref) = graph1('Avg Physical CPUs Used',
                        $sub_title,
                        'Hour',
                        'Avg Physical CPUs Used',
                        $y_max,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu__PhysUsed_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$stat_avg);
    #######################
    # Peak                #
    #######################
    ($y_max) = set_graph_scale($scale_cpu2,$stat_max);
    ($att_ref) = graph1('Peak Physical CPUs Used',
                        $sub_title,
                        'Hour',
                        'Peak Physical CPUs Used',
                        $y_max,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu__PhysUsed_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$stat_max);
  }

  ###################################
  # MyPool Physical CPUs Used - Avg #
  ###################################
  if ($pools2_avg)
  {
    ($y_max) = set_graph_scale($scale_pools2,$pools2_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$pools2_avg);}
    ($att_ref) = graph1('Avg MyPool Physical CPUs Used',
                        $sub_title,
                        'Hour',
                        'Avg MyPool Physical CPUs Used',
                        $y_max,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu_MyPoolUsed_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pools2_avg);
  }
  ###################################
  # MyPool Physical CPUs Used - Max #
  ###################################
  if ($pools2_max)
  {
    ($y_max) = set_graph_scale($scale_pools2,$pools2_max);
    ($att_ref) = graph1('Peak MyPool Physical CPUs Used',
                        $sub_title,
                        'Hour',
                        'Peak MyPool Physical CPUs Used',
                        $y_max,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu_MyPoolUsed_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pools2_max);
  }

  ###################################
  # Shared Physical CPUs Used - Avg #
  ###################################
  if ($pools4_avg)
  {
    ($y_max) = set_graph_scale($scale_pools4,$pools4_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$pools4_avg);}
    ($att_ref) = graph1('Avg Shared Physical CPUs Used',
                        $sub_title,
                        'Hour',
                        'Avg Shared Physical CPUs Used',
                        $y_max,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu_SharedUsed_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pools4_avg);
  }
  ###################################
  # Shared Physical CPUs Used - Max #
  ###################################
  if ($pools4_max)
  {
    ($y_max) = set_graph_scale($scale_pools4,$pools4_max);
    ($att_ref) = graph1('Peak Shared Physical CPUs Used',
                        $sub_title,
                        'Hour',
                        'Peak Shared Physical CPUs Used',
                        $y_max,
                        'cadetblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'cpu_SharedUsed_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pools4_max);
  }

  ################################
  # mem_free1_avg                #
  ################################
  if ($mem_free1_avg)
  {
    ($y_max) = set_graph_scale($scale_mem_free1,$mem_free1_avg);
    ($att_ref) = graph1('Avg Free Real Memory (MB)',
                        $sub_title,
                        'Hour',
                        'Avg Free Real Memory (MB)',
                        $y_max,
                        'pink',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'mem_free1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$mem_free1_avg);
  }

  ################################
  # mem_free1_min                #
  ################################
  if ($mem_free1_min)
  {
    ($y_max) = set_graph_scale($scale_mem_free1,$mem_free1_avg);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$mem_free1_min);}
    ($att_ref) = graph1('Minimum Free Real Memory (MB)',
                        $sub_title,
                        'Hour',
                        'Minimum Free Real Memory (MB)',
                        $y_max,
                        'pink',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'mem_free1_min',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$mem_free1_min);
  }

  ################################
  # mem_used1_avg                #
  ################################
  if ($mem_used1_avg)
  {
    ($y_max) = set_graph_scale($scale_mem_used1,$mem_used1_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$mem_used1_avg);}
    ($att_ref) = graph1('Avg Used Real Memory (MB)',
                        $sub_title,
                        'Hour',
                        'Avg Used Real Memory (MB)',
                        $y_max,
                        'pink',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'mem_used1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$mem_used1_avg);
  }

  ################################
  # mem_used1_max                #
  ################################
  if ($mem_used1_max)
  {
    ($y_max) = set_graph_scale($scale_mem_used1,$mem_used1_max);
    ($att_ref) = graph1('Maximum Used Real Memory (MB)',
                        $sub_title,
                        'Hour',
                        'Maximum Used Real Memory (MB)',
                        $y_max,
                        'pink',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'mem_used1_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$mem_used1_max);
  }

  ###########################
  # proc_process1_avg       #
  ###########################
  if ($proc_process1_avg)
  {
    ($y_max) = set_graph_scale($scale_proc1,$proc_process1_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$proc_process1_avg);}
    ($att_ref) = graph1('Avg Process Switches/Sec/1000',
                        $sub_title,
                        'Hour',
                        'Avg Process Switches/Sec/1000',
                        $y_max,
                        'greenyellow',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'proc_process1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$proc_process1_avg);
  }

  ###########################
  # proc_process1_max       #
  ###########################
  if ($proc_process1_max)
  {
    ($y_max) = set_graph_scale($scale_proc1,$proc_process1_max);
    ($att_ref) = graph1('Peak Process Switches/Sec/1000',
                        $sub_title,
                        'Hour',
                        'Peak Process Switches/Sec/1000',
                        $y_max,
                        'greenyellow',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'proc_process1_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$proc_process1_max);
  }

  ###########################
  # proc_queue1_avg         #
  ###########################
  if ($proc_queue1_avg)
  {
    ($y_max) = set_graph_scale($scale_proc2,$proc_queue1_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$proc_queue1_avg);}
    ($att_ref) = graph1('Avg Processes On Run Queue',
                        $sub_title,
                        'Hour',
                        'Avg Processes On Run Queue',
                        $y_max,
                        'copper',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'proc_queue1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$proc_queue1_avg);
  }

  ###########################
  # proc_queue1_max         #
  ###########################
  if ($proc_queue1_max)
  {
    ($y_max) = set_graph_scale($scale_proc2,$proc_queue1_max);
    ($att_ref) = graph1('Peak Processes On Run Queue',
                        $sub_title,
                        'Hour',
                        'Peak Processes On Run Queue',
                        $y_max,
                        'copper',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'proc_queue1_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$proc_queue1_max);
  }

  ###########################
  # disk_read1_avg          #
  ###########################
  if ($disk_read1_avg)
  {
    ($y_max) = set_graph_scale($scale_disk1,$disk_read1_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$disk_read1_avg);}
    ($att_ref) = graph1('Avg Disk Reads (KB/Sec)',
                        $sub_title,
                        'Hour',
                        'Avg Disk Reads (KB/Sec)',
                        $y_max,
                        'orange',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'disk_read1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$disk_read1_avg);
  }

  ###########################
  # disk_read1_max          #
  ###########################
  if ($disk_read1_max)
  {
    ($y_max) = set_graph_scale($scale_disk1,$disk_read1_max);
    ($att_ref) = graph1('Peak Disk Reads (KB/Sec)',
                        $sub_title,
                        'Hour',
                        'Peak Disk Reads (KB/Sec)',
                        $y_max,
                        'orange',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'disk_read1_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$disk_read1_max);
  }

  ###########################
  # disk_write1_avg         #
  ###########################
  if ($disk_write1_avg)
  {
    ($y_max) = set_graph_scale($scale_disk2,$disk_write1_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$disk_write1_avg);}
    ($att_ref) = graph1('Avg Disk Writes (KB/Sec)',
                        $sub_title,
                        'Hour',
                        'Avg Disk Writes (KB/Sec)',
                        $y_max,
                        'orange',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'disk_write1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$disk_write1_avg);
  }

  ###########################
  # disk_write1_max         #
  ###########################
  if ($disk_write1_max)
  {
    ($y_max) = set_graph_scale($scale_disk2,$disk_write1_max);
    ($att_ref) = graph1('Peak Disk Writes (KB/Sec)',
                        $sub_title,
                        'Hour',
                        'Peak Disk Writes (KB/Sec)',
                        $y_max,
                        'orange',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'disk_write1_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$disk_write1_max);
  }

  ###########################
  # pkt_rcv1_avg            #
  ###########################
  if ($pkt_rcv1_avg)
  {
    ($y_max) = set_graph_scale($scale_pkt1,$pkt_rcv1_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$pkt_rcv1_avg);}
    ($att_ref) = graph1('Avg Packets Rcv/Sec',
                        $sub_title,
                        'Hour',
                        'Avg Packets Rcv/Sec',
                        $y_max,
                        'skyblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'pkt_rcv1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pkt_rcv1_avg);
  }

  ###########################
  # pkt_rcv1_max            #
  ###########################
  if ($pkt_rcv1_max)
  {
    ($y_max) = set_graph_scale($scale_pkt1,$pkt_rcv1_max);
    ($att_ref) = graph1('Peak Packets Rcv/Sec',
                        $sub_title,
                        'Hour',
                        'Peak Packets Rcv/Sec',
                        $y_max,
                        'skyblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'pkt_rcv1_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pkt_rcv1_max);
  }

  ###########################
  # pkt_xmit1_avg           #
  ###########################
  if ($pkt_xmit1_avg)
  {
    ($y_max) = set_graph_scale($scale_pkt2,$pkt_xmit1_max);
    if ($opt_m) {($y_max) = set_graph_scale($scale_cpu2,$pkt_xmit1_avg);}
    ($att_ref) = graph1('Avg Packets Sent/Sec',
                        $sub_title,
                        'Hour',
                        'Avg Packets Sent/Sec',
                        $y_max,
                        'skyblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'pkt_xmit1_avg',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pkt_xmit1_avg);
  }

  ###########################
  # pkt_xmit1_max           #
  ###########################
  if ($pkt_xmit1_max)
  {
    ($y_max) = set_graph_scale($scale_pkt2,$pkt_xmit1_max);
    ($att_ref) = graph1('Peak Packets Sent/Sec',
                        $sub_title,
                        'Hour',
                        'Peak Packets Sent/Sec',
                        $y_max,
                        'skyblue',
                        undef,
                        $color_switch);
    $outgraph = join ('_',$sys,'pkt_xmit1_max',$yyyymmdd,$rev);
    graph2("$dirgrh/$outgraph.png",$att_ref,$pkt_xmit1_max);
  }
}



sub
initialize_variables
{
  ###################################
  # Initialize lists and hashes     #
  ###################################
  undef @headers,undef @samples;
  undef @cpu_list,undef @lpar_list,undef @pools_list;
  undef @mem_list,undef @proc_list;
  undef @diskr_list,undef @diskw_list,undef @packet_list;
  undef %time;
  undef %cpu,undef %lpar;
  undef %mem,undef %proc;
  undef %diskr,undef %diskw,undef %packet;

  return;
}



sub
day_of_week 
{
  my ($m,$d,$y) = @_;

  my ($wday);

  my %month=(1,0,2,3,3,2,4,5,5,0,6,3,7,5,8,1,9,4,10,6,11,2,12,4,);
  my %weekday=(0,'SUN',1,'MON',2,'TUE',3,'WED',4,'THU',5,'FRI',6,'SAT',);

  ########################################################################
  # Compute the day of week for any date                                 #
  # Author: John Von Essen                                               #
  # Location: http://search.cpan.org/~essenz/Date-Day-1.04/Day.pm#___top #
  ########################################################################

  ########################################
  # Check for input errors               #
  ########################################
  if($m !~ /[\d]{1,2}/ || $m > 12  || $m < 1 ){ return "ERR"; }
  if($d !~ /[\d]{1,2}/ || $d > 31  || $d < 1 ){ return "ERR"; }
  if($y !~ /[\d]+/ || $y < 1 ){ return "ERR"; }

  ################################
  # Compute the day of week      #
  ################################
  if($m == 1){ $y--; }
  if($m == 2){ $y--; }
  $m = int($m);
  $d = int($d);
  $y = int($y);
  $wday = (($d+$month{$m}+$y+(int($y/4))-(int($y/100))+(int($y/400)))%7);

  return $weekday{$wday};
}



sub
create_time_stamp_row
{
  my ($sample,$time_ref,$resource_ref) = @_;

  my ($val);

  ################################
  # If sample to process         #
  ################################
  if ($resource_ref->{$sample})
  {
    $val = join ('|',$time_ref->{$sample},$resource_ref->{$sample});
  }

  return($val);
}



sub
compute_stats
{
  my ($type,$samples_ref) = @_;

  my ($val);
  my (@data_list);
  my ($data_val);
  my ($day_val);
  my ($timestamp);
  my ($time_hour);
  my ($time_hour_save);
  my ($day_hour);
  my (@mean_vals);
  my ($i);

  my ($n)=0;
  my ($mean_val)=0;

  ################################
  # If samples to process        #
  ################################
  if (@$samples_ref)
  {
    ################################
    # Initialize Variables         #
    ################################
    $time_hour_save = substr($samples_ref->[0],0,10);
    $day_val = substr($time_hour_save,0,8);
    for ($i=0;$i<24;$i++)
    {
      $mean_vals[$i] = ' '; 
    }

    ################################
    # For each sample              #
    ################################
    foreach $val (@$samples_ref)
    {
      ################################
      # Extract needed data          #
      ################################
      ($timestamp,$data_val) = get_usage_data($type,$val);
 
      #######################
      # If No Data Returned #
      #######################
      if (!$data_val)
      {
        next;
      }

      ################################
      # Hourly statistics            #
      ################################
      $time_hour = substr($timestamp,0,10);
      if ($time_hour ne $time_hour_save)
      {
        $mean_val = sprintf($format,$mean_val);
        $day_hour = substr($time_hour_save,8,10);	
	$mean_vals[$day_hour] = $mean_val;
        $n=1;
        $mean_val = $data_val / $n  + (($n - 1) * $mean_val) / $n;
        $time_hour_save = $time_hour;
      }

      ################################
      # Recursively compute the mean #
      ################################
      else
      {
        $n++;
        $mean_val = $data_val / $n  + (($n - 1) * $mean_val) / $n;
      }
    }

    ################################
    # Last hour statistics         #
    ################################
    $mean_val = sprintf($format,$mean_val);
    $day_hour = substr($time_hour_save,8,10);	
    $mean_vals[$day_hour] = $mean_val;

    ################################
    # Construct day_val            #
    ################################
    $day_val = join(',',$day_val,@mean_vals);
  }

  return($day_val);
}



sub
get_usage_data
{
  my ($data_type,$row_val) = @_;

  my ($time_val);
  my (@data_list);
  my ($data_item);

  ################################
  # Split the record             #
  ################################
  ($time_val,@data_list) = split('\|',$row_val);

  ################################
  # % CPU Used                   #
  ################################
  if ($data_type eq 'CPU_ALL1')
  {
    ($data_item) = 100-$data_list[$cpu1_index];
    if ($data_item > $max_stats{CPU_ALL1}) {undef $data_item;}
  }

  ################################
  # Physical CPUs Used           #
  ################################
  if ($data_type eq 'CPU_ALL2')
  {
    ($data_item) = $data_list[$cpu2_index];
    if ($data_item > $max_stats{CPU_ALL2}) {undef $data_item;}
  }

  ################################
  # Return needed LPAR1 data     #
  ################################
  if ($data_type eq 'LPAR1')
  {
    ($data_item) = $data_list[$lpar1_index];
    if ($data_item > $max_stats{LPAR1}) {undef $data_item;}
  }

  ################################
  # Return needed LPAR2 data     #
  ################################
  if ($data_type eq 'LPAR2')
  {
    ($data_item) = $data_list[$lpar2_index];
    if ($data_item > $max_stats{LPAR2}) {undef $data_item;}
  }

  ################################
  # Return needed POOLS1 data    #
  ################################
  if ($data_type eq 'POOLS1')
  {
    ($data_item) = $data_list[$pools1_index];
    if ($data_item > $max_stats{POOLS1}) {undef $data_item;}
  }

  ################################
  # Return needed POOLS2 data    #
  ################################
  if ($data_type eq 'POOLS2')
  {
    ($data_item) = $data_list[$pools2_index];
    if ($data_item > $max_stats{POOLS2}) {undef $data_item;}
  }

  ################################
  # Return needed POOLS3 data    #
  ################################
  if ($data_type eq 'POOLS3')
  {
    ($data_item) = $data_list[$pools3_index];
    if ($data_item > $max_stats{POOLS3}) {undef $data_item;}
  }

  ################################
  # Return needed POOLS4 data    #
  ################################
  if ($data_type eq 'POOLS4')
  {
    ($data_item) = $data_list[$pools4_index];
    if ($data_item > $max_stats{POOLS4}) {undef $data_item;}
  }

  #####################################
  # Return needed MEM_FREE1 data      #
  #####################################
  if ($data_type eq 'MEM_FREE1')
  {
    ($data_item) = $data_list[$mem_free1_index];
    if ($data_item > $max_stats{MEM_FREE1}) {undef $data_item;}
  }

  #####################################
  # Return needed MEM_USED1 data      #
  #####################################
  if ($data_type eq 'MEM_USED1')
  {
    ($data_item) = $data_list[$mem_total1_index] - $data_list[$mem_free1_index];
    if ($data_item < 0 or $data_item > $max_stats{MEM_USED1}){undef $data_item;}
  }

  ####################################
  # Return needed PROC_PROCESS1 data #
  ####################################
  if ($data_type eq 'PROC_PROCESS1')
  {
    ($data_item) = $data_list[$proc_process_index]/1000;
    if ($data_item > $max_stats{PROC_PROCESS1}) {undef $data_item;}
  }

  ####################################
  # Return needed PROC_QUEUE1 data   #
  ####################################
  if ($data_type eq 'PROC_QUEUE1')
  {
    ($data_item) = $data_list[$proc_queue_index];
    if ($data_item > $max_stats{PROC_QUEUE1}) {undef $data_item;}
  }

  #################################
  # Return needed DISK_READ1 data #
  #################################
  if ($data_type eq 'DISK_READ1')
  {
    ($data_item) = compute_row_total(\@data_list);
    if ($data_item > $max_stats{DISK_READ1}) {undef $data_item;}
  }

  ##################################
  # Return needed DISK_WRITE1 data #
  ##################################
  if ($data_type eq 'DISK_WRITE1')
  {
    ($data_item) = compute_row_total(\@data_list);
    if ($data_item > $max_stats{DISK_WRITE1}) {undef $data_item;}
  }

  ################################
  # Return needed PKT_RCV1 data  #
  ################################
  if ($data_type eq 'PKT_RCV1')
  {
    ($data_item) = compute_split_row('FRONT',\@data_list);
    if ($data_item > $max_stats{PKT_RCV1}) {undef $data_item;}
  }

  ################################
  # Return needed PKT_XMIT1 data #
  ################################
  if ($data_type eq 'PKT_XMIT1')
  {
    ($data_item) = compute_split_row('BACK',\@data_list);
    if ($data_item > $max_stats{PKT_XMIT1}) {undef $data_item;}
  }

  return ($time_val,$data_item);
}


sub
compute_row_total
{
  my ($data_ref) = @_;

  my ($i);
  my ($data_total)=0.0;

  ##########################
  # Compute total          #
  ##########################
  for ($i=1;$i<@$data_ref;$i++)
  {
    $data_total += $data_ref->[$i];
  }

  return ($data_total);
}


sub
compute_split_row
{
  my ($type,$data_ref) = @_;

  my ($total);
  my ($start);
  my ($end);
  my ($i);

  my ($data_total)=0;

  ##########################
  # Compute total          #
  ##########################
  $total = @$data_ref;

  ########################################
  # Compute start and end for front half #
  ########################################
  if ($type eq 'FRONT')
  {
    $start = 1;
    $end = int(($total-1)/2);
  }
  #######################################
  # Compute start and end for back half #
  #######################################
  if ($type eq 'BACK')
  {
    $start = int(($total-1)/2)+1;
    $end = $total-1;
  }

  ##########################
  # Compute second half    #
  ##########################
  for ($i=$start;$i<=$end;$i++)
  {
    $data_total += $data_ref->[$i];
  }
    
  return ($data_total);
}



sub
error
{
  my ($max_data,$data_ref) = @_;

  my ($val);
  my ($data_error);

  ##########################
  # Check For Error        #
  ##########################
  foreach $val (@$data_ref)
  {
    if ($val and $val > $max_data)
    {
      $data_error = 1;
    }
  }
    
  return($data_error);
}



sub
write_errors
{
  my ($dir,$name,$resource,$year_month,$rev_val,$data_errors_ref) = @_;

  my ($errfile);
  my ($row);

  ################################
  # Open error file              #
  ################################
  $errfile = join('_',$name,$resource,$year_month,$rev_val);
  $errfile = join('.',$errfile,"txt");
  open ERRFILE, ">$dir/$errfile";

  ################################
  # Process each row             #
  ################################
  foreach $row (@$data_errors_ref)
  {
    print ERRFILE "$row\n";
  }
  close ERRFILE;

  return;
}



sub
print_headers
{
  my ($name,$headers_ref) = @_;

  my ($val);

  ##########################
  # Print header           #
  ##########################
  print "\n$name\n";
  foreach $val (@$headers_ref)
  {
    print "$val\n";
  }
    
  return;
}



sub
print_data_rows
{
  my ($data_list_ref) = @_;

  my ($sample_val);

  ###################################
  # Print data rows                 #
  ###################################
  foreach $sample_val (@$data_list_ref)
  {
    print "$sample_val\n";
  }

  return;
}



sub
create_csv
{
  my ($dir,$name,$resource,$year_month,$rev_val,$stats_ref) = @_;

  my ($time_val);
  my ($outfile);
  my (@stats_list);
  my ($year);
  my ($month);
  my ($day);
  my ($stats);
  my ($stats_out);

  ################################
  # If stats to process          #
  ################################
  if (@$stats_ref)
  {
    ################################
    # Open output file             #
    ################################
    $outfile = join('_',$name,$resource,$year_month,$rev_val);
    $outfile = join('.',$outfile,"csv");
    open OUTFILE, ">$dir/$outfile";

    ################################
    # Process each row             #
    ################################
    foreach $stats (@$stats_ref)
    {
      ###################################
      # Format stat_out row             #
      ###################################
      ($time_val,@stats_list) = split('\,',$stats);

      ###################################
      # Format stat_out row - if date   #
      ###################################
      if ($time_val =~ /\d+/)
      {
        $year = substr($time_val,0,4);
        $month = substr($time_val,4,2);
        $day = substr($time_val,6,2);
        $stats_out = join ('/',$month,$day,$year);
        $stats_out = join (',',$stats_out,@stats_list);
      }
      else
      {
        $stats_out = join (',',$time_val,@stats_list);
      }

      ###################################
      # Write statistics to file        #
      ###################################
      print OUTFILE "$stats_out\n";
    }
    close OUTFILE;
  }

  return;
}



sub
create_stats_csv
{
  my ($dir,$name,$stat_type,$date1,$date2,$rev_val,$stats2_ref) = @_;

  my ($outfile);
  my ($stat);

  ################################
  # If stats to process          #
  ################################
  if (@$stats2_ref)
  {
    ################################
    # Open output file             #
    ################################
    $outfile = join('_',$name,$stat_type,$date1,$date2,$rev_val);
    $outfile = join('.',$outfile,"csv");
    open OUTFILE, ">$dir/$outfile";

    ################################
    # Write statistics to file     #
    ################################
    foreach $stat (@$stats2_ref)
    {
      print OUTFILE "$stat\n";
    }
    close OUTFILE;
  }

  return;
}



sub
summary_stats
{
  my ($stats_ref) = @_;

  my ($time_val);
  my (@stats_list);
  my ($stats);
  my ($n_val);
  my ($mean_val);
  my ($max_val);
  my ($min_val);
  my (@n);
  my (@mean);
  my (@max);
  my (@min);
  my ($mean_vals);
  my ($mean2_vals);
  my ($max_vals);
  my ($max2_vals);
  my ($min_vals);
  my ($min2_vals);
  my ($hour);
  my ($i);

  my ($min_init)=9999999;

  ################################
  # Initialize hour of day stats #
  ################################
  for ($i=0;$i<24;$i++)
  {
    $n[$i] = 0; 
    $mean[$i] = 0; 
    $max[$i] = 0; 
    $min[$i] = $min_init; 
  }

  ################################
  # If stats to process          #
  ################################
  if (@$stats_ref)
  {
    ################################
    # Process each row             #
    ################################
    foreach $stats (@$stats_ref)
    {
      ###################################
      # Format stat_out row             #
      ###################################
      ($time_val,@stats_list) = split('\,',$stats);

      ###################################
      # Update stats - mean and max     #
      ###################################
      for ($i=0;$i<24;$i++)
      {
        if ($stats_list[$i] eq ' ')
       	{
          next;
        }
        else
        {
          ($n_val,
           $mean_val,
           $max_val,
           $min_val) = update_stats($stats_list[$i],
                                    $n[$i],
                                    $mean[$i],
                                    $max[$i],
                                    $min[$i]);
        }
        ###################################
        # Save stats - mean and max       #
        ###################################
        $n[$i] = $n_val;
        $mean[$i] = $mean_val;
        $max[$i] = $max_val;
        $min[$i] = $min_val;
      }
    }
    ################################
    # Process each row             #
    ################################
    if ($min[0] == $min_init){$min[0] = 0;}
    $hour = sprintf('%04d','0');
    $mean[0] = sprintf($format,$mean[0]);
    $mean_vals = join '|',$hour,$mean[0];
    $mean2_vals = join ',','avg',$mean[0];
    $max[0] = sprintf($format,$max[0]);
    $max_vals = join '|',$hour,$max[0];
    $max2_vals = join ',','max',$max[0];
    $min[0] = sprintf($format,$min[0]);
    $min_vals = join '|',$hour,$min[0];
    $min2_vals = join ',','min',$min[0];
    for ($i=1;$i<24;$i++)
    {
      if ($min[$i] == $min_init){$min[$i] = 0;}
      $hour = sprintf('%04d',$i*100);
      $mean[$i] = sprintf($format,$mean[$i]);
      $mean_val = join '|',$hour,$mean[$i];
      $mean_vals = join ',',$mean_vals,$mean_val;
      $mean2_vals = join ',',$mean2_vals,$mean[$i];
      $max[$i] = sprintf($format,$max[$i]);
      $max_val = join '|',$hour,$max[$i];
      $max_vals = join ',',$max_vals,$max_val;
      $max2_vals = join ',',$max2_vals,$max[$i];
      $min[$i] = sprintf($format,$min[$i]);
      $min_val = join '|',$hour,$min[$i];
      $min_vals = join ',',$min_vals,$min_val;
      $min2_vals = join ',',$min2_vals,$min[$i];
    }
  }

  return($mean_vals,$mean2_vals,
         $max_vals,$max2_vals,
         $min_vals,$min2_vals);
}



sub
update_stats
{
  my ($data_val,$n,$mean_val,$max_val,$min_val) = @_;

  ##############################
  # Compute the mean           #
  ##############################
  $n++;
  $mean_val = $data_val / $n + (($n - 1) * $mean_val) / $n;

  ##############################
  # Compute the max            #
  ##############################
  if ($data_val > $max_val)
  {
    $max_val = $data_val; 
  }

  ##############################
  # Compute the min            #
  ##############################
  if ($data_val < $min_val)
  {
    $min_val = $data_val; 
  }

  return($n,$mean_val,$max_val,$min_val);
}



sub
create_infile_list
{
  my ($path_input,$server_name) = @_;

  my ($file);
  my ($infile_val);
  my (@all_files);
  my (@infile_list);
  my ($infile_list_sorted);

  ##############################
  # Get all file names         #
  ##############################
  opendir(DIR,$path_input);
  @all_files = readdir(DIR);
  closedir(DIR);

  ##############################
  # Create infile list         #
  ##############################
  foreach $file (@all_files)
  {
    ($infile_val) = split('\.',$file);
    if ($infile_val eq $server_name)
    {
      push @infile_list,$file;
    }
  }

  ################################
  # Sort infile list             #
  ################################
  ($infile_list_sorted) = sort_infile_list(\@infile_list);

  return($infile_list_sorted);
}



sub
sort_infile_list
{
  my ($infile_list_ref) = @_;

  my ($infile_name);
  my (@infile_name_parts);
  my ($infile_date);
  my ($infile_pipe);
  my ($infile_year);
  my ($infile_month);
  my ($infile_day);
  my (@infiles_pipe);
  my (@infiles_sorted);

  ################################
  # Process each file name       #
  ################################
  foreach $infile_name (@$infile_list_ref)
  {
    (@infile_name_parts) = split('\.',$infile_name);
    $infile_date = $infile_name_parts[@infile_name_parts-1];
    $infile_year = substr($infile_date,4,8);
    $infile_month = substr($infile_date,0,2);
    $infile_day = substr($infile_date,2,2);
    ($infile_date) = sprintf('%04d%02d%02d',$infile_year,
                                            $infile_month,
                                            $infile_day);
    $infile_pipe = join ('|',$infile_date,$infile_name);
    push @infiles_pipe,$infile_pipe;
  }

  ################################
  # Sort in file_date order      #
  ################################
  @infiles_pipe = sort @infiles_pipe;

  ################################
  # Strip off file_date          #
  ################################
  foreach $infile_pipe (@infiles_pipe)
  {
    (undef,$infile_name) = split('\|',$infile_pipe);
    push @infiles_sorted,$infile_name;
  }

  return(\@infiles_sorted);
}



sub
set_graph_scale
{
  my ($default_data_val,$graph_data_row) = @_;

  my (@graph_data);
  my ($graph_value);
  my (@values);
  my ($value);
  my ($max_data_val);

  ###########################
  # Create graph data list  #
  ###########################
  (@graph_data) = split(',',$graph_data_row);
  foreach $graph_value (@graph_data)
  {
    (undef,$value) = split('\|',$graph_value);
    $value = sprintf('%012.3f',$value);
    push @values,$value;
  }

  ###################################
  # Sort the list                   #
  ###################################
  @values = reverse sort @values;

  ###################################
  # Compute max value               #
  ###################################
  $max_data_val = int($values[0]+.99999);

  ###################################
  # Check max against default       #
  ###################################
  if ($default_data_val > $max_data_val)
  {
    $max_data_val = $default_data_val;
  }

  return($max_data_val);
}



sub
graph1
{
  my ($title,$subtitle,$legend,
      $y_axis_label,$max_value,
      $bar_color,$back_color,$switch_color) = @_;

  my ($max_value_int);  
  my ($y_axis_inc);  
  my (@y_axis_list);
  my ($y_axis_scale);
  my ($y_axis_max);
  my ($i);
  my ($temp);
  my ($y_axis_val);  

  my ($y_axis_min)=0;

  ##############################
  # Initialize y_axis_val      #
  ##############################
  $y_axis_val = $y_axis_min;  

  ##############################
  # y_axis scale < 10          #
  ##############################
  if ($max_value < 10)
  {
    $max_value_int = int(($max_value-$y_axis_min)+.999999);
    $y_axis_inc = $max_value_int/10;
  }
  ##############################
  # y_axis scale >= 10         #
  ##############################
  else
  {
    $y_axis_inc = int(($max_value-$y_axis_min)/10+.999999);
  }
  ##############################
  # Create y_axis scale values #
  ##############################
  for ($i=0;$i<10;$i++)
  {
    $y_axis_val += $y_axis_inc;
    push @y_axis_list,$y_axis_val;
  }
  ###################################
  # Max value For y_axis scale < 10 #
  ###################################
  if ($max_value < 10)
  {
    $y_axis_max = $max_value_int;
  }
  ####################################
  # Max value For y_axis scale >= 10 #
  ####################################
  else
  {
    $y_axis_max = $y_axis_val;
  }
  ####################################
  # Create y_axis scale row          #
  ####################################
  $y_axis_scale = join ',',@y_axis_list;

  #########################################
  # Check if switch color                 #
  #########################################
  if ($switch_color)
  {
    $temp = $bar_color;
    $bar_color = $back_color;
    $back_color = $temp;
  }


  #########################################
  # Create attribute list                 #
  #########################################
  my %attribute =
     (title        => $title,
      subtitle     => $subtitle,
      keys_label   => $legend,
      values_label => $y_axis_label,
      value_min    => $y_axis_min,
      value_max    => $y_axis_max,
      value_labels => $y_axis_scale,
      color_list   => $bar_color,
      bgcolor      => $back_color);

  return (\%attribute);
}



sub
graph2
{
  my ($outfile,$attribute,$graph_data_row) = @_;

  my (@graph_data);
  my ($graph_value);
  my ($graph);
  my ($value);
  my ($label);

  ####################################
  # Create instance of  Graph object #
  ####################################
  $graph = new Graph;

  ###########################
  # Create graph data list  #
  ###########################
  (@graph_data) = split(',',$graph_data_row);
  foreach $graph_value (@graph_data)
  {
    ($label,$value) = split('\|',$graph_value);
    $graph->data($value,$label);
  }

  ###########################
  # Set up graph attributes #
  ###########################
  $graph->title($attribute->{title});
  $graph->subtitle($attribute->{subtitle});
  $graph->keys_label($attribute->{keys_label});
  $graph->values_label($attribute->{values_label});
  $graph->value_min($attribute->{value_min});
  $graph->value_max($attribute->{value_max});
  $graph->value_labels($attribute->{value_labels});
  $graph->color_list($attribute->{color_list});
  $graph->bgcolor($attribute->{bgcolor});
  $graph->bar_shadow_depth(3);
  $graph->bar_shadow_color("black");

  ############################
  # Create graph output file #
  ############################
  $graph->output("$outfile");

  return(0);
}
