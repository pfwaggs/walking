#!/usr/bin/perl

# normal junk #AzA
use warnings;
use strict;
use v5.22;
use experimental qw(postderef signatures smartmatch);

#use Getopt::Long qw( :config no_ignore_case auto_help );
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
use YAML::Tiny qw(LoadFile DumpFile);
use Data::Printer;
use Date::Tiny;

#ZaZ

my $file = shift;
my %data;
my $date = Date::Tiny->new;
for (path($file)->lines({chomp => 1})) {
    my ($junk, $val) = split /\s/, $_;
    if ($val =~ /\d-\d/) {
	$date=Date::Tiny->new(
	    year => $val =~ m/^(\d{4})-/,
	    month => $val =~ m/-(\d\d)-/,
	    day => $val =~ m/-(\d\d)$/
	);
     } else {
	push($data{$date->ymd}->@*, $val);
     }
}

for my $date (sort keys %data) {
    my @output = ();
    while ($data{$date}->@*) {
	my ($steps, $time) = $data{$date}->@[0,1];
	push @output, $time=~s/\./:/r, $steps;
    } continue {
	shift $data{$date}->@*;
	shift $data{$date}->@*;
    }
    say join(',',$date,@output);
}

#while (@data) {
#    my ($steps, $time) = @data[0,1];
#    push @output, $time=~s/\./:/r, $steps;
#} continue {
#    shift @data;
#    shift @data;
#}

#say join(',', $date, @output);
