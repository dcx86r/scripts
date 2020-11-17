#!/usr/bin/perl

# mpv + youtube-dl helper script 

use strict;
use warnings;
use feature qw(say);
use IO::Prompter; # CPAN module 

# user provides target URL as ARGV
my $url = ($ARGV[0]) ? $ARGV[0] : die "No URL provided\n";

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
my @args = ("mpv", "--ytdl", "--ytdl-format=$selection", $url);
exec { $args[0] } @args;
