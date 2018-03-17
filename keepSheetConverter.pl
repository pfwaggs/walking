#!/usr/bin/perl

# normal junk #AzA
use warnings;
use strict;
use v5.22;
use experimental qw(postderef signatures smartmatch);

use Getopt::Long qw( :config no_ignore_case auto_help );
#my %opts;
#my @opts;
#my @commands;
#GetOptions( \%opts, @opts, @commands ) or die 'something goes here';
#use Pod::Usage;
#use File::Basename;
#use Cwd;
#use Term::ReadLine;
#use Term::UI;

use Path::Tiny;
use YAML::Tiny qw(LoadFile Load DumpFile Dump);
use Data::Printer;
use Date::Tiny;

#ZaZ

my %opts;
my @opts = qw/history=s date=s/;
GetOptions( \%opts, @opts ) or die 'something goes here';

#my $dateObj = Date::Tiny->new;

my $oldData = $opts{history};
my %historical;
if (defined $opts{history} and -f $opts{history}) {
    %historical = Load(path($opts{history})->lines({chomp => 1}))->%*;
} else {
    warn 'no historical data to load', "\n";
}

my $date;
my %stdinData;
while (<STDIN>) {
    chomp;
    s/\s//g;
    my ($junk, $val) = split /\W/, $_, 2;
    $val =~ s/-//g; # for historical dates that were yyyy-mm-dd
     if (length $val == 8) {
	 $date = Date::Tiny->new(
	     year => substr($val,0,4),
	     month => substr($val,4,2),
	     day => substr($val,6,2),
	 );
     } else {
	state $steps;
	if (defined $steps) {
	    $val =~ s/\W//;
	    $val = substr($val.'000', 0, 4);
	    $val =~ s/(\d\d)(\d\d)/$1:$2/;
	    push $stdinData{$date->ymd}{raw}->@*, {steps => $steps, time => $val};
	    $steps = undef;
	} else {
	    $steps = $val;
	}
     }
}
for my $date (keys %stdinData) {
    my %start = $stdinData{$date}{raw}->[0]->%*;
    my %stop  = $stdinData{$date}{raw}->[-1]->%*;
    my ($hStart, $mStart) = split /:/, $start{time};
    my ($hStop, $mStop)   = split /:/, $stop{time};
    my $hDiff = $hStop - $hStart;
    my $mDiff = $mStop - $mStart;
    if ($mDiff < 0) {
	$hDiff -= 1;
	$mDiff += 60;
    }
    my $stepDiff = $stop{steps} - $start{steps};
    $stdinData{$date}{diffs} = { steps => $stepDiff, time => join(':', $hDiff, $mDiff)};
}

for my $date (keys %stdinData) {
    say join("\t", $date, $stdinData{$date}{diffs}->@{qw/steps time/});
}

__END__
things to work on:
    add a date option so you can split data into 2 parts for review.
    how does before-date data later compare to after-date data? edge case
    of date being a key value we include that data in after-date computation

    export current spreadsheet data and pull in as historical data.

    add write support to generate historical.yaml file.

    do dates need to be sorted?

    what stats can we compute
	average steps per roundtrip?
	steps per half?
	steps per visit?
	time per visit?

    look into using 'sheets' to enter the data.  practice before next walk!
