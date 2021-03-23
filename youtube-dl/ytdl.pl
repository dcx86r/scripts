#!/usr/bin/perl

# youtube-dl + mpv helper script
# for selecting download quality
#
# Copyright (c) 2021 dcx86r
# License: MIT 

use strict;
use warnings;
use feature qw(say);
use IO::Prompter; # CPAN module 

# prompts for URL and discards any extra params
my $url = [ split(/&/, prompt("Enter URL: ", -in=>*STDIN)) ]->[0];

# queries URL for available formats
open(my $optlist, "-|", "youtube-dl --list-formats $url")
	|| die "Can't run youtube-dl: $!\n";

# prepares returned data for printing and prompt output
my @rows = <$optlist>;
my $yank = 0;
foreach (@rows) {
	chomp;
	$yank++ unless $_ =~ m/^\d/a;
}
for (1..$yank) { 
	my $row = shift(@rows); 
	say $row unless $row =~ m/^format/ 
}

# prompts user to select desired video format
my $selection = prompt(-in=>*STDIN, -number, -menu=>\@rows, ">");
$selection = [ split(/\s/, $selection) ]->[0];

# launches mpv with selected format
my @args = ("mpv", "--input-ipc-server=/tmp/mpvsocket", "--ytdl", "--ytdl-format=$selection", $url);
exec { $args[0] } @args;
