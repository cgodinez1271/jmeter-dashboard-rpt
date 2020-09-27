#!/usr/bin/env perl -w

=head1 NAME

network_cap_anal_rev1.pl - time series data to capacity planning information

=head1 SYNOPSIS

network_cap_anal_rev1.pl

=head1 DESCRIPTION

This script converts time series data to capacity planning information

=head1 OPTIONS

 -h display help text
 -r rev number (default is 1)
 -s switch graph colors (bars and background)
 -w process weekday data (M-F)

=head1 EXAMPLES

 network_cap_anal_rev1.pl
 network_cap_anal_rev1.pl mm/dd/yyyy-mm/dd/yyyy
 network_cap_anal_rev1.pl -w mm/dd/yyyy-mm/dd/yyyy

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
use vars qw($opt_h $opt_r $opt_s $opt_w);

#############################
# Script variables          #
#############################
my($infile);
my($infile_list_ref);
my($route_name);
my($date_range);
my($date_from);
my($date_to);
my($row);
my(@error_rows);
my($error_string);

my($bw_in_ref); 
my(%bw_stats); 
my($bw_in_avg);
my($bw_in_max);
my($bw_out_ref); 
my($bw_out_avg);
my($bw_out_max);
my($dir_infile); 
my($dircsv); 
my($dirgrh); 
my($dirnode); 
my($direrr); 

my($yyyymmddhh);
my($yyyymmdd);
my($dow);
my($date_year);
my($date_month);
my($date_day);
my($sub_title);
my($outgraph);
my($graph_stat);

my(@headers);
my(%samples);
my($sample_val);
my($node);
my(@nodes);
my(%interface);
my($interface_val);
my($att_ref);
my($color_switch);

my(%graph_type)=('bw_in_avg'=>'Avg Incoming % Util',
                 'bw_in_max'=>'Peak Incoming % Util',
                 'bw_out_avg'=>'Avg Outgoing % Util',
                 'bw_out_max'=>'Peak Outgoing % Util');

my(%graph_color)=('bw_in_avg'=>'cadetblue',
                  'bw_in_max'=>'skyblue',
                  'bw_out_avg'=>'copper',
                  'bw_out_max'=>'orange');

##################################
# Script variables - initialized #
##################################
my($dirgrh1) = "CapGraph"; 
my($dircsv1) = "CapCsv"; 
my($dirnode1) = "NodeList"; 
my($direrr1) = "ErrorList"; 
my($rev) = 1; 
my(%max_util) = ('NET1'=>100,'NET2'=>110);
my($util_d) = 100;
my($date_beg)=99999999;
my($date_end)=0;

################################
# Check command line options   #
################################
getopts('hr:sw');

################################
# Display help text            #
################################
if ($opt_h)
{
  system ("perldoc",$0);
  exit 0;
}

################################
# Create input file list       #
################################
$infile_list_ref = create_infile_list('.','csv');
if (!@$infile_list_ref)
{
  print "Error - No input files\n";
  exit(0);
}

################################
# Check for ARGS               #
################################
if (@ARGV)
{
  $date_range = $ARGV[0];
}

################################
# If date_range set            #
################################
if ($date_range)
{
  ($date_from,$date_to,
   $date_beg,$date_end) = date_range_info($date_range);
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

################################
# Print heading                #
################################
if ($date_range)
{
  print "\nNetwork Capacity Analysis: ($date_range)\n";
}
else
{
  print "\nNetwork Capacity Analysis:\n";
}
print   "----------------------------\n";

################################
# Process input file list      #
################################
foreach $infile (@$infile_list_ref)
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

    ########################################
    # Not data row                         #
    ########################################
    if ($_ !~ /^"/)
    {
      next;
    }
    ########################################
    # Process timestamp info               #
    ########################################
    ($yyyymmddhh,$dow) = time_stamp_info($_);

    ########################################
    # Incorrect timestamp                  #
    ########################################
    if (!$yyyymmddhh)
    {
      next;
    }
    ########################################
    # Check if process only weekdays (M-F) #
    ########################################
    if ($opt_w)
    {
      if ($dow eq 'SAT' or 
          $dow eq 'SUN' or
          $dow eq 'ERR')
      {
        next;
      }
    }

    ########################################
    # Compute yyyymmdd                     #
    ########################################
    ($yyyymmdd) = date_stamp_info($yyyymmddhh);

    ########################################
    # Process date_range                   #
    ########################################
    if ($date_from and $date_to)
    {
      if ($yyyymmdd >= $date_beg and
          $yyyymmdd <= $date_end)
      {
        ########################################
        # Process row of data                  #
        ########################################
        ($node,$interface_val,$sample_val) = create_sample_row($yyyymmddhh,$_);
        if ($sample_val)
        {
          if (!$interface{$node})
          {
            $interface{$node} = $interface_val;
          }
          push @{$samples{$node}},$sample_val;
        }
        else
        {
          $error_string = join(',',"ERROR:Input_Row",$_);
          push @error_rows,$error_string;   
        }
      }
      else
      {
        next;
      }
    }
    ########################################
    # Process all dates in file            #
    ########################################
    else
    {
      ########################################
      # Update date_beg and date_end         #
      ########################################
      if ($yyyymmdd < $date_beg)
      {
        $date_beg = $yyyymmdd;
      }
      if ($yyyymmdd > $date_end)
      {
        $date_end = $yyyymmdd;
      }

      ########################################
      # Process row of data                  #
      ########################################
      ($node,$interface_val,$sample_val) = create_sample_row($yyyymmddhh,$_);
      if ($sample_val)
      {
        if (!$interface{$node})
        {
          $interface{$node} = $interface_val;
        }
        push @{$samples{$node}},$sample_val;
      }
      else
      {
        $error_string = join(',',"ERROR:No Sample Value",$_);
         push @error_rows,$error_string;   
      }
    }
  } 
  close INFILE;

  ##################################
  # Create output file directories #
  ##################################
  if (%samples)
  {
    ($dir_infile) = split ('\.',$infile);
    mkdir $dir_infile,0777;
  }

  ########################################
  # Set date_range if not set by args    #
  ########################################
  if (!$date_from or !$date_to)
  {
    (undef,$date_year,$date_month,$date_day) = date_stamp_info($date_beg);
    $date_from = join ('/',$date_month,$date_day,$date_year);
    (undef,$date_year,$date_month,$date_day) = date_stamp_info($date_end);
    $date_to = join ('/',$date_month,$date_day,$date_year);
  }

  ###################################
  # Process each network element    #
  ###################################
  foreach $node (sort keys %samples)
  {
    ######################################
    # Create node list                   #
    ######################################
    push @nodes,$node;

    ######################################
    # Create bw_in and bw_out statistics #
    ######################################
    ($bw_in_ref,
     $bw_out_ref) = compute_stats($node,
                                  sort \@{$samples{$node}});

    ###################################
    # Create summary statistics       #
    ###################################
    ($bw_stats{'bw_in_avg'},
     $bw_stats{'bw_in_max'}) = summary_stats($bw_in_ref);
    ($bw_stats{'bw_out_avg'},
     $bw_stats{'bw_out_max'}) = summary_stats($bw_out_ref);

    ###################################
    # Create csv directory            #
    ###################################
    if (!$dircsv)
    {
      $dircsv = join '/',$dir_infile,$dircsv1;
      mkdir $dircsv,0777;
    }

    ###################################
    # Create csv files                #
    ###################################
    create_csv($dircsv,$node,$rev,
               $bw_in_ref,$bw_out_ref);

    ###################################
    # Create directory and graphs     #
    ###################################
    if (!$dirgrh)
    {
      $dirgrh = join '/',$dir_infile,$dirgrh1;
      mkdir $dirgrh,0777;
    }

    ###################################
    # Graph subtitle                  #
    ###################################
    $sub_title = join ('-',$date_from,$date_to);
    $sub_title = join (' -> ',substr($interface{$node},0,65),$sub_title);
    if ($opt_w) {$sub_title = join (' ',$sub_title,'(M-F)');}

    ###########################
    # Create graphs           #
    ###########################
    foreach $graph_stat (sort keys %graph_type)
    {
      if ($bw_stats{$graph_stat})
      {
        ($att_ref) = get_graph_attributes(
                    "$graph_type{$graph_stat} -> $node",
                    "$sub_title",
                    'Hour',
                    "$graph_type{$graph_stat}",
                    $util_d,
                    "$graph_color{$graph_stat}",
                    undef,
                    $color_switch);
        $outgraph = join ('_',$node,$graph_stat,$rev);
        create_graph_file_png("$dirgrh/$outgraph.png",
                              $att_ref,
                              $bw_stats{$graph_stat});
      }
    }
  }
  ###################################
  # Create node list file           #
  ###################################
  if (@nodes)
  {
    $dirnode = join '/',$dir_infile,$dirnode1;
    create_output_file($dirnode,'nodelist.csv',\@nodes);
  }

  ###################################
  # Create node list file           #
  ###################################
  if (@error_rows)
  {
    $direrr = join '/',$dir_infile,$direrr1;
    create_output_file($direrr,'errors.csv',\@error_rows);
  }

  ###################################
  # Initialize Variables            #
  ###################################
  undef %samples;
  undef $dircsv;
  undef $dirgrh;
  undef %samples;
  undef @nodes;
  undef @error_rows;
}


sub
create_infile_list
{
  my ($path_input,$file_ext) = @_;

  my ($file);
  my (@all_files);
  my (@infile_list);
  my (@ext_list);

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
    (@ext_list) = split('\.',$file);
    if ($ext_list[@ext_list-1] and $ext_list[@ext_list-1] eq $file_ext)
    {
      push @infile_list,$file;
    }
  }

  return(\@infile_list);
}



sub
date_range_info
{
  my ($date_range1) = @_;

  my ($date_from1);
  my ($date_to1);
  my ($date_beg1);
  my ($date_end1);
  my ($date_range_error1);
  my ($yyyy1);
  my ($mm1);
  my ($dd1);

  ###################################
  # Get date_from1 and date_to1     #
  ###################################
  ($date_from1,$date_to1) = split('-',$date_range1);

  ###################################
  # Get date_beg1                   #
  ###################################
  ($mm1,$dd1,$yyyy1) = split('\/',$date_from1);
  if ($yyyy1 and $mm1 and $dd1)
  {
    ($date_beg1) = join('',sprintf('%04d',$yyyy1),
                           sprintf('%02d',$mm1),
                           sprintf('%02d',$dd1));
  }
  ###################################
  # Get date_end1                   #
  ###################################
  ($mm1,$dd1,$yyyy1) = split('\/',$date_to1);
  if ($yyyy1 and $mm1 and $dd1)
  {
    ($date_end1) = join('',sprintf('%04d',$yyyy1),
                           sprintf('%02d',$mm1),
                           sprintf('%02d',$dd1));
  }

  ###########################################
  # Check length of date_beg1 and date_end1 # 
  ###########################################
  if (!$date_beg1 or
      !$date_end1 or
      length($date_beg1)!=8 or
      length($date_end1)!=8)
  {
    $date_range_error1 = join(',',"ERROR:Date_Range",$date_beg1,$date_end1);
    push @error_rows,$date_range_error1;   
    undef $date_beg1;
    undef $date_end1;
  }

  return($date_from1,$date_to1,$date_beg1,$date_end1);
}



sub
time_stamp_info
{
  my ($sample_row) = @_;

  my ($tstamp1);
  my ($date1);
  my ($tod1);
  my ($tod2);
  my ($yyyy1);
  my ($mm1);
  my ($dd1);
  my ($hh1);
  my ($yyyymmddhh1);
  my ($dow1);

  my(%hh1_hash) = ('12:00 AM'=>'00','01:00 AM'=>'01','02:00 AM'=>'02',
                   '03:00 AM'=>'03','04:00 AM'=>'04','05:00 AM'=>'05',
                   '06:00 AM'=>'06','07:00 AM'=>'07','08:00 AM'=>'08',
                   '09:00 AM'=>'09','10:00 AM'=>'10','11:00 AM'=>'11',
                   '12:00 PM'=>'12','01:00 PM'=>'13','02:00 PM'=>'14',
                   '03:00 PM'=>'15','04:00 PM'=>'16','05:00 PM'=>'17',
                   '06:00 PM'=>'18','07:00 PM'=>'19','08:00 PM'=>'20',
                   '09:00 PM'=>'21','10:00 PM'=>'22','11:00 PM'=>'23');

  my(%mm1_hash) = ('JAN'=>'01','FEB'=>'02','MAR'=>'03',
                   'APR'=>'04','MAY'=>'05','JUN'=>'06',
                   'JUL'=>'07','AUG'=>'08','SEP'=>'09',
                   'OCT'=>'10','NOV'=>'11','DEC'=>'12');

  ###################################
  # Get yyyymmddhh and dow          # 
  ###################################
  ($tstamp1) = split(',',$sample_row);
  (undef,$tstamp1) = split('"',$tstamp1);
  ($date1,$tod1,$tod2) = split(/\s+/,$tstamp1);
  ($tod1) = join(' ',$tod1,$tod2);
  ($hh1) = $hh1_hash{$tod1};
  ($dd1,$mm1,$yyyy1) = split('-',$date1);
  ($yyyy1) = $yyyy1+2000;
  $mm1 = $mm1_hash{uc($mm1)};
  if ($yyyy1 and $mm1 and $dd1 and $hh1)
  {
    ($yyyymmddhh1) = join('',$yyyy1,$mm1,$dd1,$hh1);
  }

  ###################################
  # Check length of yyyymmddhh      # 
  ###################################
  if ($yyyymmddhh1 and length($yyyymmddhh1) == 10)
  {
    ($dow1) = day_of_week($mm1,$dd1,$yyyy1);
  }
  else
  {
    push @error_rows,$sample_row;   
    undef $yyyymmddhh1;
  }

  return($yyyymmddhh1,$dow1);
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

  return($weekday{$wday});
}


sub
date_stamp_info
{
  my ($yyyymmddhh1) = @_;

  my ($yyyymmdd1);
  my ($yyyy1);
  my ($mm1);
  my ($dd1);
  my ($hh1);

  ###################################
  # Get date_stamp_info             # 
  ###################################
  if ($yyyymmddhh1 and 
      (length($yyyymmddhh1) == 10 or
       length($yyyymmddhh1) == 8))
  {
    ($yyyymmdd1) = substr($yyyymmddhh1,0,8);
    ($yyyy1) = substr($yyyymmddhh1,0,4);
    ($mm1) = substr($yyyymmddhh1,4,2);
    ($dd1) = substr($yyyymmddhh1,6,2);
    ($hh1) = substr($yyyymmddhh1,8,2);
  }

  return($yyyymmdd1,$yyyy1,$mm1,$dd1,$hh1);
}



sub
create_sample_row
{
  my ($yyyymmddhh1,$sample1) = @_;

  my ($tstamp1);
  my ($node1);
  my ($node2);
  my ($interface1);
  my (@interface_list1);
  my ($recv1);
  my ($xmit1);
  my (@slash_to_dash1);
  my (@colon_to_underscore1);
  my ($sample_val1);

  ###################################
  # Split the sample                # 
  ###################################
  (undef,$node1,$interface1,$recv1,$xmit1) = split(',',$sample1);

  ###############################################
  # Remove node1 from . on - e.g., .doit.nv.gov #
  ###############################################
  ($node1) = split('\.',$node1);

  ###############################################
  # Remove " " from interface1, recv, and xmit1 #
  ###############################################
  (undef,$interface1) = split('"',$interface1);
  (undef,$recv1) = split('"',$recv1);
  (undef,$xmit1) = split('"',$xmit1);

  #######################################
  # If all variables set                #
  #######################################
  if ($node1 and $interface1 and $recv1 and $xmit1)
  {
    #######################################
    # interface1 - split on white space   #
    #######################################
    (@interface_list1) = split(/\s+/,$interface1);

    ###############################
    # node1 - Add node2 to node1  #
    ###############################
    ($node2) = shift @interface_list1;
    ($node1) = join('-',$node1,$node2);

    ###################################
    # node1 - change / to - &  : to _ #
    ###################################
    (@slash_to_dash1) = split('\/',$node1);
    ($node1) = join('-',@slash_to_dash1);
    (@colon_to_underscore1) = split('\:',$node1);
    ($node1) = join('_',@colon_to_underscore1);

    #########################################
    # interface1 - join parts with _        #
    #########################################
    if (@interface_list1)
    {
      ($interface1) = join('_',@interface_list1);
    }
    else
    {
      $interface1 = "no interface specified";
    }
    if ($interface1 =~ /^._/ and length($interface1) > 2)
    {
      $interface1 = substr($interface1,2);
    }

    #######################################
    # Extract numeric recv                #
    #######################################
    ($recv1) = split(/\s+/,$recv1);

    #######################################
    # Extract numeric xmit                #
    #######################################
    ($xmit1) = split(/\s+/,$xmit1);

    #######################################
    # Create sample_val                   #
    #######################################
    ($sample_val1) = join(',',$yyyymmddhh1,$recv1,$xmit1);
  }

  return($node1,$interface1,$sample_val1);
}



sub
compute_stats
{
  my ($node_val,$samples_ref) = @_;

  my ($yyyymmddhh1);
  my ($val);
  my ($day_val);
  my ($timestamp);
  my ($time_day);
  my ($time_day_save);
  my($date_val);
  my ($year);
  my ($month);
  my ($day);
  my ($hour);
  my ($year1);
  my ($month1);
  my ($day1);
  my (@bw_in);
  my (@bw_out);
  my (@bw_in_tmp);
  my (@bw_out_tmp);
  my ($bw_in_val);
  my ($bw_out_val);
  my ($bw_in_row);
  my ($bw_out_row);
  my ($i);
  my ($max);
  my ($used);

  ################################
  # If samples to process        #
  ################################
  if (@$samples_ref)
  {
    ################################
    # Initialize Variables         #
    ################################
    ($yyyymmddhh1) = split(',',$samples_ref->[0]);
    ($time_day_save,$year1,$month1,$day1) = date_stamp_info($yyyymmddhh1);
    $day_val = $time_day_save;
    for ($i=0;$i<24;$i++)
    {
      $bw_in_tmp[$i] = ' '; 
      $bw_out_tmp[$i] = ' '; 
    }

    ################################
    # For each sample              #
    ################################
    foreach $val (@$samples_ref)
    {
      ################################
      # Extract data                 #
      ################################
      ($timestamp,$bw_in_val,$bw_out_val) = get_usage_data($val);
      if (!$bw_in_val or !$bw_out_val)
      {
        $error_string = join(',',"ERROR:Base Data",$node_val,$val);
        push @error_rows,$error_string;   
        next;
      }
      ################################
      # Date Stamp Info              #
      ################################
      ($time_day,$year,$month,$day,$hour) = date_stamp_info($timestamp);

      ####################################
      # New day - save previous day data #
      ####################################
      if ($time_day ne $time_day_save)
      {
        ####################################################
        # Construct bw_in bw_out rows and put on lists     #
        ####################################################
        $date_val = join('/',$month1,$day1,$year1); 
        $bw_in_row = join(',',$date_val,@bw_in_tmp);
        $bw_out_row = join(',',$date_val,@bw_out_tmp);
        push @bw_in,$bw_in_row;
        push @bw_out,$bw_out_row;

        ##################################
        # Reset save values              #
        ##################################
        $time_day_save = $time_day;
        $year1 = $year;
        $month1 = $month;
        $day1 = $day;

        ##################################
        # Re-initialize single day row   #
        ##################################
        for ($i=0;$i<24;$i++)
        {
          $bw_in_tmp[$i] = ' '; 
          $bw_out_tmp[$i] = ' '; 
        }
      }

      ################################
      # Put data on single day list  #
      ################################
      $bw_in_tmp[$hour] = $bw_in_val;
      $bw_out_tmp[$hour] = $bw_out_val;
    }

    ################################
    # Last day - save data         #
    ################################
    $date_val = join('/',$month,$day,$year); 
    $bw_in_row = join(',',$date_val,@bw_in_tmp);
    $bw_out_row = join(',',$date_val,@bw_out_tmp);
    push @bw_in,$bw_in_row;
    push @bw_out,$bw_out_row;
  }

  return(\@bw_in,\@bw_out);
}



sub
get_usage_data
{
  my ($row_val) = @_;

  my ($time_val);
  my (@data_list);
  my ($data_item1);
  my ($data_item2);

  ################################
  # Split the record             #
  ################################
  ($time_val,@data_list) = split(',',$row_val);

  ################################
  # Return needed data           #
  ################################
  $data_item1 = $data_list[0];
  $data_item2 = $data_list[1];

  #############################################
  # Check if data out of range by 10% or more #
  #############################################
  if ($data_item1 > $max_util{NET1} and $data_item1 < $max_util{NET2})
  {
    $data_item1 = $max_util{NET1};
  }
  if ($data_item2 > $max_util{NET1} and $data_item2 < $max_util{NET2})
  {
    $data_item2 = $max_util{NET1};
  }
  if ($data_item1 < 0 or $data_item1 > $max_util{NET1}) {undef $data_item1;}
  if ($data_item2 < 0 or $data_item2 > $max_util{NET1}) {undef $data_item2;}

  return ($time_val,$data_item1,$data_item2);
}



sub
summary_stats
{
  my ($stats_ref) = @_;

  my (@stats_list);
  my ($stats);
  my ($n_val);
  my ($mean_val);
  my ($max_val);
  my (@n);
  my (@mean);
  my (@max);
  my ($mean_vals);
  my ($max_vals);
  my ($hour);
  my ($i);

  my ($n_save)=0;
  my ($mean_save)=0;
  my ($max_save)=0;

  ################################
  # Initialize hour of day stats #
  ################################
  for ($i=0;$i<24;$i++)
  {
    $n[$i] = 0; 
    $mean[$i] = 0; 
    $max[$i] = 0; 
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
      (undef,@stats_list) = split('\,',$stats);

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
          ($n_val,$mean_val,$max_val) = update_stats($stats_list[$i],
                                                     $n[$i],
                                                     $mean[$i],
                                                     $max[$i]);
        }
        ###################################
        # Save stats - mean and max       #
        ###################################
        $n[$i] = $n_val;
        $mean[$i] = $mean_val;
        $max[$i] = $max_val;
      }
    }
    ################################
    # Process each row             #
    ################################
    $hour = sprintf('%04d','0');
    $mean[0] = sprintf('%.1f',$mean[0]);
    $mean_vals = join '|',$hour,$mean[0];
    $max[0] = sprintf('%.1f',$max[0]);
    $max_vals = join '|',$hour,$max[0];
    for ($i=1;$i<24;$i++)
    {
      $hour = sprintf('%04d',$i*100);
      $mean[$i] = sprintf('%.1f',$mean[$i]);
      $mean_val = join '|',$hour,$mean[$i];
      $mean_vals = join ',',$mean_vals,$mean_val;
      $max[$i] = sprintf('%.1f',$max[$i]);
      $max_val = join '|',$hour,$max[$i];
      $max_vals = join ',',$max_vals,$max_val;
    }
  }

  return($mean_vals,$max_vals);
}



sub
update_stats
{
  my ($data_val,$n,$mean_val,$max_val) = @_;

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

  return($n,$mean_val,$max_val);
}



sub
create_csv
{
  my ($dir,$name,$rev_val,
      $bw_in1_ref,$bw_out1_ref) = @_;

  my ($outfile);
  my ($stats);

  ################################
  # If stats to process          #
  ################################
  if (@$bw_in1_ref and @$bw_out1_ref)
  {
    ################################
    # Open output file             #
    ################################
    $name = substr($name,0,50);
    $outfile = join('_',$name,$rev_val);
    $outfile = join('.',$outfile,"csv");
    open OUTFILE, ">$dir/$outfile";

    ################################
    # Process each bw_in row       #
    ################################
    foreach $stats (@$bw_in1_ref)
    {
      ###################################
      # Write statistics to file        #
      ###################################
      print OUTFILE "$stats\n";
    }

    ################################
    # Print blank row              #
    ################################
    print OUTFILE "\n";

    ################################
    # Process each bw_out row      #
    ################################
    foreach $stats (@$bw_out1_ref)
    {
      ###################################
      # Write statistics to file        #
      ###################################
      print OUTFILE "$stats\n";
    }
    close OUTFILE;
  }

  return;
}



sub
get_graph_attributes
{
  my ($title,$subtitle,$legend,
      $y_axis_label,$max_value,
      $bar_color,$back_color,$switch_color) = @_;

  my ($y_axis_inc);  
  my (@y_axis_list);
  my ($y_axis_scale);
  my ($y_axis_max);
  my ($i);
  my ($temp);  

  my ($y_axis_min)=0;
  my ($y_axis_val)=0;  

  #########################################
  # Create y_axis scale                   #
  #########################################
  $y_axis_inc = int(($max_value-$y_axis_min)/10+.999999);
  for ($i=0;$i<10;$i++)
  {
    $y_axis_val += $y_axis_inc;
    push @y_axis_list,$y_axis_val;
  }
  $y_axis_max = $y_axis_val;
  $y_axis_scale = join ',',@y_axis_list;

  #########################################
  # Check if switch color                #
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
create_graph_file_png
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



sub
create_output_file
{
  my ($outdir,$outfile,$list_ref) = @_;

  my ($list_val);

  ################################################
  # Create output directory and open output file #
  ################################################
  if ($outdir)
  {
    mkdir $outdir,0777;
    open OUTFILE, ">$outdir/$outfile";
  }
  else
  {
    open OUTFILE, ">$outfile";
  }
  ##############################
  # Output list                #
  ##############################
  foreach $list_val (@$list_ref)
  {
    print OUTFILE "$list_val\n";
  }
  close OUTFILE;

  return(0);
}
