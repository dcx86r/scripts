#!/usr/bin/perl

# Simple Common Log Format Filter
# Parses nginx access logs
# Core dependencies only
#
# Usage:
# logparse.pl -d <path/to/logs>
# optional '-j' flag outputs JSON
#
# Copyright (c) 2021 dcx86r
# License: MIT

use v5.10;
use strict;
use warnings;
use Getopt::Std;
use File::stat;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Term::ANSIColor;
use JSON;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub parse_log {
	my $linesref = shift;
	my @label = ( 
		"host",
		"ident",
		"authuser",
		"time",
		"request",
		"status",
		"bytes" 
	);
	my @parsed;

	foreach (@{$linesref}) {
		my @fragment;
		chomp;
		my $m1 = index($_, '[');
		my $m2 = index($_, ']');

# host, ident, authuser		
		push @fragment, split(/ /, substr($_, 0, $m1));
# time
		push @fragment, substr($_, ++$m1, (index($_, ']', $m1) - $m1));
# request
		push @fragment, [ split(/"/, substr($_, ++$m2)) ]->[1];
# status, bytes
		push @fragment, /\s(\d+)\s(\d+)\s/;

		push @parsed, { map { $label[$_] => $fragment[$_] } ( 0 .. $#label ) };

		undef @fragment;
	}
	return @parsed;
}

sub work_list {
	my $log_list = shift;
	my @file;
	
	for my $i (0 .. $#{$log_list}) {
		open(my $fh, "<", $log_list->[$i])
			|| die "Can't read $log_list->[$i]: $!\n";
	
		my @lines;
		unless (substr($log_list->[$i], -3) eq ".gz") {
			while(<$fh>) { unshift @lines, $_ }
		}
		else {
			my $z = IO::Uncompress::Gunzip->new($fh)
				|| die "Gunzip failed: $GunzipError\n";
			while(<$z>) { unshift @lines, $_ }
		}
		close($fh);
		push @file, parse_log(\@lines);
		undef @lines;
	}
	return @file;
}

sub main {
	@ARGV || die "Try './logparse.pl -d <path/to/logs>'\n";
	getopts('d:', \my %opts);
	defined $opts{'d:j'} || die "Missing path to logs using -d flag\n";
	my ($path, $type) = ($opts{'d'}, "access");
	(-e -d -x $path) || die "Can't access $path: $!\n";
	opendir( my $dir, $path ) || die "Can't open dir: $!\n";
	my %log_files;
	while ( my $file = readdir($dir) ) {
		next unless $file =~ m/^${type}/;
		my $saved = stat("$path/$file");
		$log_files{$saved->mtime} = "$path/$file";
	}
	my @sorted_list;
	for my $key ( sort {$b <=> $a} keys %log_files ) {
		push @sorted_list, $log_files{$key};
	}
	my @data = work_list(\@sorted_list);

	if (defined $opts{'j'}) {
		my $obj = JSON->new;
		print $obj->utf8->pretty->canonical->encode(\@data);
		return;
	}

	foreach (@data) { 
		print pack("A15",$_->{host}) . " - ";
		print $_->{status} <= 299 
			? colored(['bright_green'], $_->{status}) 
			: $_->{status} <= 499
				? colored(['bright_yellow'], $_->{status})
				: colored(['bright_red'], $_->{status});
		print " - " . $_->{time} . " - ";
		print $_->{request} . "\n";
	}
}

main();
