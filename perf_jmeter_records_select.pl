#!/usr/bin/env perl -w

=head1 NAME

perf_jmeter_records_select.pl

=head1 SYNOPSIS

perf_jmeter_records_select.pl before_duration

=head1 DESCRIPTION

This script selects jmeter csv output records

=head1 ARGS
before - data excluded from beginning of input file (seconds)
duration - data range to be analyzed (seconds) 

=head1 OPTIONS

 -a add web page response time to timestamp
 -b subtract web page response time from timestamp
 -h display help text
 -l put output file in home directory (default is select)

=head1 EXAMPLES

 perf_jmeter_records_select.pl 120_2400
 perf_jmeter_records_select.pl -l 120_2400

=cut

##########################################################################
# Perl Script:                                                           #
# Purpose: selects jmeter csv output records                             #
# Author:  James F Brady                                                 #
# Release: Version 3.0.0                                                 #
# Copyright © 2003 - 2016 James F. Brady                                 #
##########################################################################
require 5.004;
use strict;
#use lib "$ENV{WEB_GEN_TOOLKIT}";
use lib '/Users/carlos/bin';
use Getopt::Std;
use vars qw($opt_a $opt_b $opt_h $opt_l);

my ($infile);
my ($infile1);
my ($infile_list_ref);
my ($row_count);
my (@row_parts);
my (@records_out);
my ($record_out);
my (@error_list);
my ($out_file);
my ($tstamp_init);
my ($tstamp_beg);
my ($tstamp_end);
my ($tstamp_new);
my ($tstamp);
my ($response_ms);

my ($arg)='All';
my ($t_before)=0;
my ($t_duration)=999999999;
my ($outdir_rpt)='select';
my ($outdir_error)='errors';

################################
# Check command line options   #
################################
getopts('abhl');

################################
# Display help text            #
################################
if ($opt_h)
{
  system ("perldoc",$0);
  exit 0;
}

################################
# Get Arguments                #
################################
if (@ARGV eq 1)
{
  $arg = shift @ARGV;
  ($t_before,$t_duration) = split ('\_',$arg);
}

#####################################
# Put output file in home directory #
#####################################
if ($opt_l)
{
  $outdir_rpt = '.';
}

###########################
# Create input file list  #
###########################
$infile_list_ref = create_infile_list();
if (!@$infile_list_ref)
{
  print "Error - No input files\n";
  exit(0);
}

################################
# Print Heading                #
################################
print "\n############################\n";
print "\n# JMeter Records Selection #\n";
print "\n############################\n";
print "  Before(sec) = $t_before\n";
print "  Duration(sec) = $t_duration\n\n";

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

  ################################
  # Initialize row_count         #
  ################################
  $row_count=0;
 
  ######################################
  # Print name of file being processed #
  ######################################
  print "Records Selected For ($infile)\n";

  ################################
  # Read input file              #
  ################################
  while (<INFILE>)
  {
    chomp $_;
    $row_count++;
    $row_count = sprintf('%07d',$row_count);

    ######################################
    # Split the row into parts           #
    ######################################
    ($tstamp,$response_ms,@row_parts) = split ('\,',$_);
    if (@row_parts < 8)
    {
      push @error_list,join ',',$row_count,$_;
      next;
    }

    ##############################################
    # Check for bad record                       #
    ##############################################
    if (bad_record($tstamp,$response_ms))
    {
      push @error_list,join ',',$row_count,$_;
      next;
    }

    ######################################
    # Set Time Interval                  #
    ######################################
    if (!$tstamp_init)
    {
      $tstamp_init = $tstamp;
      $tstamp_beg = $tstamp_init + int($t_before*1000);
      $tstamp_end = $tstamp_beg + int($t_duration*1000);
    }

    ######################################
    # Time Interval - No match           #
    ######################################
    if( $tstamp lt $tstamp_beg or
        $tstamp gt $tstamp_end)
    {
      next;
    }

    ###################################################
    # opt_a Add web page response time to timestamp   #
    ###################################################
    if ($opt_a)
    {
      $tstamp_new = $tstamp + $response_ms;
    }
    ######################################################
    # opt_b Subtract web page response time to timestamp #
    ######################################################
    elsif ($opt_b)
    {
      $tstamp_new = $tstamp - $response_ms;
    }
    ######################################
    # no change                          #
    ######################################
    else
    {
      $tstamp_new = $tstamp;
    }
    ######################################
    # Put record on out list             #
    ######################################
    $record_out = join ',',$tstamp_new,$response_ms,@row_parts;
    push @records_out,$record_out;
  }
  close INFILE;
    
  ################################
  # create record list           #
  ################################
  if (@records_out)
  {
    ($infile1) = split('\.',$infile);
    $out_file = join '_',$infile1,$arg;
    $out_file = join '.',$out_file,'csv';
    create_output_file($outdir_rpt,$out_file,\@records_out);
  }

  ################################
  # Create error file            #
  ################################
  if (@error_list)
  {
    $out_file = join '_','error',$infile;
    create_output_file($outdir_error,$out_file,\@error_list);
  }

  ###############
  # Reset lists #
  ###############
  undef $row_count;
  undef $tstamp_init;
  undef @records_out;
  undef @error_list;
}



sub
bad_record
{
  my ($tstamp_val,$response_ms_val) = @_;

  my ($bad);

  ##############################
  # Check tstamp size          #
  ##############################
  if (length($tstamp_val) ne 13 or
     $response_ms_val =~ /\D/)
  {
    $bad=1;
  }

  return($bad);
}



sub
create_infile_list
{
  my ($file);
  my ($infile_name);
  my ($infile_ext);
  my (@all_files);
  my (@infile_list);

  ##############################
  # Get all file names         #
  ##############################
  opendir(DIR,'.');
  @all_files = readdir(DIR);
  closedir(DIR);

  ##############################
  # Create infile list         #
  ##############################
  foreach $file (@all_files)
  {
    ($infile_name,$infile_ext) = split('\.',$file);
    if ($infile_ext)
    {
      if ($infile_ext eq 'csv')
      {
        push @infile_list,$file;
      }
    }
  }

  ################################
  # Sort infile list             #
  ################################
  @infile_list = sort @infile_list;

  return(\@infile_list);
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
  foreach $list_val (sort @$list_ref)
  {
    print OUTFILE "$list_val\n";
  }
  close OUTFILE;

  return(0);
}
