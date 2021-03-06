#!/usr/bin/perl -w

#
#    doc-features.pl - Generate module/library documentation
#    Copyright (c) 1999  Frodo Looijaard <frodol@dds.nl>
#    Copyright (c) 2002  Jean Delvare <khali@linux-fr.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

use strict;

# %prefix contains the SENSORS_*_PREFIX defines as found in lib/chips.h.
# It is generated by scan_chips_h(). It shouldn't have duplicated values.
# %arrayname contains the sensors_chip_features array as found in
# lib/chips.c. It is generated by scan_chips_c_1(). It may have duplicated
# values.
# %prefix and %arrayname are expected to have the same set of keys, and
# this is verified in scan_all().
#
# %sysctl contains the sysctl filenames as found in kernel/chips/*.c. It
# is generated by scan_kernel_chip, which is called on each file. It has
# (of course) duplicated values.
#
# %features contains the features for all chips as found in lib/chips.c.
# They are stored as arrays of references to hashes, each containing the
# following fields:
#   number: The preprocessor symbol for the number of this feature
#   name: The name of this feature
#   logical_mapping: The preprocessor symbol for the logical mapping
#                    feature
#   compute_mapping: The preprocessor symbol for the compute mapping
#                    feature
#   mode_read: 1 if the feature is readable, 0 if not
#   mode_write: 1 if the feature is writable, 0 if not
#   sysctl: Preprocessor name of the sysctl file
#   offset: Offset (in longs) within the sysctl file
#   magnitude: Magnitude of this feature
#
# %mapping contains the feature names. It is generated while parsing
# lib/chips.c and is later used to display the mappings.

use vars qw(%prefix %arrayname %sysctl %features %mapping);

# Scan chips.h to get all prefixes values.
# Store the results in %prefix.
# $_[0]: Path to chips.h
sub scan_chips_h
{
	my $chips_h = shift;
	
	open INPUTFILE, $chips_h
		or die "Can't open $chips_h";
	
	while (<INPUTFILE>)
	{
		if (m/^\s*#\s*define\s+(SENSORS_\w+_PREFIX)\s+"(\S+)"/)
		{
			die "Duplicate #define $1 in $chips_h"
				if defined $prefix{$1};
			$prefix{$1} = $2; 
		}
	}
  	
	close INPUTFILE;
}

# Scan chips.c to get the feature array names.
# Store the results in %arrayname.
# $_[0]: Path to chips.c
sub scan_chips_c_1
{
	my $chips_c = shift;
	open INPUTFILE, $chips_c
		or die "Can't open $chips_c";
	
	while (<INPUTFILE> !~ m/^\s*sensors_chip_features\s/) {}
	while (<INPUTFILE>)
	{
		last if m/^\s*\{\s*0/;
		if (m/^\s*\{\s*(SENSORS_\w+_PREFIX)\s*,\s*(\w+)\s*\}\s*,/)
		{
			die "Duplicate entry $1 in sensors_chip_features"
				if defined $arrayname{$1};
			$arrayname{$1} = $2;
		}
	}
	
	close INPUTFILE;
}

# Returns a list of tokens.
# Tokens are either '{', '}', ',', ';' or anything between them. Spaces on 
# each side of a token are removed; spaces inside a token are not.
# Used by scan_kernel_chip() and scan_chips_c_2().
# $_[0]: Line to tokenize
sub tokenize
{
	my $line = shift;
	
	my @res = ();
	$line =~ s/^\s*//;
	
	while (length $line)
	{
		last if $line =~ s/^\s*$//;
		$line =~ s/^([{};,])\s*//
			or $line =~ s/^([^{},;]+?)\s*([{},;\n])/$2/;
		die "Parse error"
			unless defined $1;
		push @res, $1;
	}
	
	return @res;
}

# Scan one chip file to get sysctl filenames.
# Store the results in %prefix.
# $_[0]: Kernel chip filename
sub scan_kernel_chip
{
	my $chip = shift;
	my $line;
	
	open INPUTFILE, $chip
		or die "Can't open $chip";
	
	while ($line = <INPUTFILE>)
	{
		next unless $line =~ m/^\s*static\s+ctl_table/;
		last if $line =~ m/;/; # Skip dynamic ctl_table
    	my @tokens = tokenize($line);
		
		while ($line = <INPUTFILE>)
		{
			push @tokens, tokenize($line);
			last if $line =~ m/;/;
		}
		
		while (shift @tokens ne '{') { die "Tokenization failed in $chip" unless @tokens }
		for (;;)
		{
			while (shift @tokens ne '{') { die "Tokenization failed in $chip" unless @tokens }
			my $val = shift @tokens;
			last if $val eq '0';
			die "Parse error: ',' expected after '$val' within $chip"
				if shift @tokens ne ',';
			my $name = shift @tokens;
			die "Parse error: invalid name '$name' within $chip"
				unless ($sysctl{$val}) = $name =~ m/^"(.+)"$/;
		}
	}
	
	close INPUTFILE;
}

# Scan chips.c to get the feature arrays.
# Store the results in %feature.
# $_[0]: Path to chips.c
sub scan_chips_c_2 
{
	my $chips_c = shift;
	my $line;
	
	open INPUTFILE, $chips_c or
		die "Can't open $chips_c";
	while (<INPUTFILE>)
	{
		next unless m/sensors_chip_feature\s+(\w+)\s*\[/;
		my $name = $1;

		my @tokens = ();
		while ($line = <INPUTFILE>)
		{
			push @tokens, tokenize($line);
			last if $line =~ m/;/;
		}

		$features{$name} = [];
		die "Parse error: '{' expected for $name" 
			if shift @tokens ne '{';
		for(;;)
		{
			my $new = {};
			while (shift @tokens ne '{') { die unless @tokens }
			$new->{number} = shift @tokens;
			last if $new->{number} eq '0';
			die "Parse error: ',' expected for $name"
				if shift @tokens ne ',';
			($new->{name}) = (shift @tokens) =~ m/^"(.*)"$/
				or die "Parse error: Bad name for $name";
			die "Parse error: ',' expected for $name"
				if shift @tokens ne ',';
			$new->{logical_mapping} = shift @tokens;
			die "Parse error: ',' expected for $name"
				if shift @tokens ne ',';
			$new->{compute_mapping} = shift @tokens;
			die "Parse error: ',' expected for $name"
				if shift @tokens ne ',';
			my $next = shift @tokens;
			$new->{mode_read} = ($next =~ m/_RW?$/);
			$new->{mode_write} = ($next =~ m/_R?W$/);
			die "Parse error: ',' expected for $name"
				if shift @tokens ne ',';
			$new->{sysctl} = shift @tokens;
			die "Parse error: ',' expected for $name"
				if shift @tokens ne ',';
			($new->{offset}) = (shift @tokens) =~ m/^VALUE\s*\(\s*(\d+)\s*\)/
				or die "Parse error: Bad offset for $name";
			die "Parse error: ',' expected for $name"
				if shift @tokens ne ',';
			$new->{magnitude} = shift @tokens;
			push @{$features{$name}}, $new;
			$mapping{$new->{number}} = $new->{name};
			while (shift @tokens ne '}') { die unless @tokens }
			die "Parse error: ',' expected after $name"
				if shift @tokens ne ',';
		}
	}
	
	close INPUTFILE;
}

# $_[0]: Base directory
sub scan_all
{
	my $basedir = shift;
	
	$basedir =~ s/\/*$//;
	
	# Generate %prefix
	scan_chips_h("$basedir/lib/chips.h");
	# Generate %arrayname
	scan_chips_c_1("$basedir/lib/chips.c");
	
	# Check that %prefix and %arrayname have the same set of keys
	foreach my $item (keys %prefix)
	{
		die "Missing array name for $item"
			unless defined $arrayname{$item};
	}
	foreach my $item (keys %arrayname)
	{
		die "Missing #define for $item"
			unless defined $prefix{$item};
	}
	
	#Generate ??
	scan_chips_c_2("$basedir/lib/chips.c");
	# Generate %sysctl
	foreach my $filename (glob "$basedir/kernel/chips/*.c")
	{
		scan_kernel_chip($filename);
	}
}

# $_[0]: Prefix
sub output_data
{
	my $index = shift;
	
	printf "Chip '\%s'\n", $prefix{$index};
	print "\n";
	
	printf "\%-21s \%-21s \%-21s \%5s \%5s\n", 'LABEL', 'LABEL CLASS',
		'COMPUTE CLASS', 'MODE', 'MAGN';
	foreach my $data (@{$features{$arrayname{$index}}})
	{
		print STDERR "Missing logical mapping for $data->{logical_mapping} (index = $index, name = $data->{name})\n"
			unless defined $mapping{$data->{logical_mapping}};
		print STDERR "Missing compute mapping for $data->{compute_mapping} (index = $index, name = $data->{name})\n"
			unless defined $mapping{$data->{compute_mapping}};
		
		printf "\%-21s \%-21s \%-21s \%4s    \%2d\n", $data->{name},
			$mapping{$data->{logical_mapping}} || '?',
			$mapping{$data->{compute_mapping}} || '?',
			($data->{mode_read}?'R':'-').($data->{mode_write}?'W':'-'),
			$data->{magnitude};
	}
	print "\n";
	
	printf "\%-21s \%-38s \%16s:\%1s\n", 'LABEL', 'FEATURE SYMBOL',
		'SYSCTL FILE', 'N';
	foreach my $data (@{$features{$arrayname{$index}}})
	{
		print STDERR "Missing sysctl for $data->{sysctl} (index = $index, name = $data->{name})\n"
			unless defined $sysctl{$data->{sysctl}};
		
		printf "\%-21s \%-38s \%16s:\%1d\n",$data->{name}, $data->{number},
			$sysctl{$data->{sysctl}} || '?', $data->{offset};
	}
	print "\n", "\n";
}

if (@ARGV < 1 or $ARGV[0] =~ m/^-/)
{
	print "Usage: $0 PATH [PREFIXES ...]\n",
		"  PATH is the path to the base directory of the lm_sensors tree.\n",
		"  PREFIXES are the chips that have to be output. If none are\n",
		"    specified, all chips are printed.\n";
	exit 0;
}

%prefix = %arrayname = %sysctl = %features = ();
%mapping = (SENSORS_NO_MAPPING => '-');

scan_all(shift @ARGV);

print "Chip Features\n", "-------------\n", "\n";

if (@ARGV)
{
	my %rprefix = reverse %prefix;
	foreach my $prefix (@ARGV)
	{
		if (exists $rprefix{$prefix})
		{
			output_data($rprefix{$prefix})
		}
		else
		{
			my $lines = 0;
			print "No chip named `$prefix' was found.\n",
				"Suggestions:\n";
			foreach my $k (sort keys %rprefix)
			{
				if (grep /$prefix/, $k)
				{
					print "  $k\n";
					$lines++;
				}
			}
			print "  (none)\n"
				unless $lines;
			print "\n";
		}
	}
}
else
{
	foreach my $item (sort keys %prefix)
	{
		output_data($item);
	}
}
