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

my %opts = (history => 'mallData.yaml');
my @opts = qw/history=s date=s stats verbose/;
GetOptions( \%opts, @opts ) or die 'something goes here';

#my $dateObj = Date::Tiny->new;

my %raw;
if (defined $opts{history} and -f $opts{history}) {
    %raw = LoadFile($opts{history})->%*;
} else {
    warn 'no historical data to load', "\n";
}

my $startCount = keys %raw;
if (-p STDIN) {
    my %stdinData = readPipe()->%*;
    for (keys %stdinData) {
	$raw{$_} = $stdinData{$_};
    }
}
#p %raw; die;
my %diffs = genDiffs(\%raw)->%*;

sub readPipe {
    my $date;
    my %rtn;
    while (<>) {
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
#		push $raw{$date->ymd}->@*, {steps => $steps, time => $val};
		push $rtn{$date}->@*, {steps => $steps, time => $val};
		$steps = undef;
	    } else {
		$steps = $val;
	    }
	}
    }
    return \%rtn;
}


#my @subKeys = (sort keys $stdinData{diffs}->%*)[0..5];
#my %subset = $stdinData{diffs}->%{@subKeys};
#p %subset;

if ($opts{stats}//0) {
    for my $row (genStats(\%diffs)) {
	say $row->{preview};
	if ($opts{verbose}//0) {
	    say join("\t", $_, $diffs{$_}->@{qw/steps time/}) for $row->{keys}->@*;
	}
	printf "average steps\t%s\n", $row->{stats}{steps};
	printf "average time\t%s\n", $row->{stats}{minutes};
	say '';
    }
}

if ($startCount < keys %raw) {
    DumpFile($opts{history}, \%raw);
}

sub stats ($data) { #AzA
    my @points = keys $data->%*;
    my $count = @points;
    my $steps = 0;
    my $min = 0;
    if ($count) {
	for (@points) {
	    $steps += $data->{$_}{steps};
	    my ($h, $m) = split /:/, $data->{$_}{time};
	    $min += 60*$h+$m;
	}
	$steps /= $count;
	$min /= $count;
    } else {
	warn 'no data to generate stats from', "\n";
    }
#   my $minutes = $min % 60;
#   my $hours = ($min - $minutes)/60;
    return {steps => $steps, minutes => $min};
} #ZaZ

sub genDiffs ($data) { #AzA
    my %diffs;
    for my $date (keys $data->%*) {
	my %start = $data->{$date}[0]->%*;
	my %stop  = $data->{$date}[-1]->%*;
	my ($hStart, $mStart) = split /:/, $start{time};
	my ($hStop, $mStop)   = split /:/, $stop{time};
	my $hDiff = $hStop - $hStart;
	my $mDiff = $mStop - $mStart;
	if ($mDiff < 0) {
	    $hDiff -= 1;
	    $mDiff += 60;
	}
	my $stepDiff = $stop{steps} - $start{steps};
	$diffs{$date} = { steps => $stepDiff, time => join(':', $hDiff, $mDiff)};
    }
    return \%diffs;
} #ZaZ

sub genStats ($data) { #AzA
    my @allKeys = sort keys $data->%*;
    my @stats;
    if ($opts{date}//0) {
	my $cut = $opts{date} =~ s/\D//gr;
	$cut =~ s/(\d\d\d\d)(\d\d)(\d\d)/$1-$2-$3/;

	my @before = grep {($_ cmp $cut) < 0} @allKeys;
	my $dataSliced = {$data->%{@before}};
	push @stats, {preview => "before $opts{date}", keys => \@before, stats => stats($dataSliced)};

	my @after =  grep {($_ cmp $cut ) >= 0} keys $data->%*;
	$dataSliced = {$data->%{@after}};
	push @stats, {preview => "after $opts{date}", keys => \@after, stats => stats($dataSliced)};

    } else {
	@stats = {preview => "all", keys => \@allKeys, stats => stats($data)};
    }
    return @stats;
} #ZaZ

__END__
things to work on:
    export current spreadsheet data and pull in as historical data.

    add write support to generate historical.yaml file.

    what stats can we compute
	average steps per roundtrip?
	steps per half?
	steps per visit?
	time per visit?

    look into using 'sheets' to enter the data.  practice before next walk!
