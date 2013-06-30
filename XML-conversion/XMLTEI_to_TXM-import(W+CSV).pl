#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.0 (http://code.google.com/p/gps-corpus-builder/).
###	Copyright (C) Adrien Barbaresi, 2013.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).


# Function : process the XML TEI corpus file, cut the documents and metadata and save them in a subfolder in order to be able to import them in the textometry software TXM (http://textometrie.ens-lyon.fr/?lang=en).

# Use : without arguments. Expects a subfolder named Bundespräsidenten (or Bundesregierung).


use strict;
use warnings;
use utf8;


# INIT
my $text;
my $docnr = 1;
my $flag = 0;
my %metadata;

my $metadata = "Bundespräsidenten/metadata.csv"; # or my $metadata = "Bundesregierung/metadata.csv";
open (METADATA, ">", $metadata) or die "Can't open $metadata: $!";
# Metadata in German...
print METADATA '"id","titel","person","datum","ort","untertitel","url","anrede"' . "\n";


## READ THE INPUT FILE, CUT TEXTS OUT OF IT AND WRITE ON THE FLY

my $input = "Bundespraesident-v2_tagged_XMLTEI.xml"; # or my $input = "Bundesregierung-v2_tagged_XMLTEI.xml";
open (INPUT, "<", $input) or die "Can't open $input: $!";
while (<INPUT>) {
	next unless ( ($_ =~ m/<title type="main">/) || ($_ =~ m/<title type="excerpt">/) || ($_ =~ m/<author>/) || ($_ =~ m/<date>/) || ($_ =~ m/<placeName>/) || ($_ =~ m/<sourceDesc>/) || ($_ =~ m/<interp type="address">/) || ($_ =~ m/<text xml.+?>/) || ($_ =~ m/<p xml.+?>/) || ($_ =~ m/<s xml.+?>/) || ($_ =~ m/<w xml.+?>/) || ($_ !~ m/[<>]/) || ($_ =~ m/<\/w>/) || ($_ =~ m/<\/s>/) || ($_ =~ m/<\/p>/) || ($_ =~ m/<\/text>/) );

	# W-TEXT
	if ($_ =~ m/<w xml.+?type=(".*?")/) {
		if ($_ =~ m/<w xml.+?type=(".*?")>/) {
			$text .= "<w type=" . $1 . ">\n";
		}
		elsif ($_ =~ m/<w xml.+?type=(".*?") lemma=(".*?")>/) { 
			$text .= "<w type=" . $1 . " lemma=" . $2 . ">\n";
		}
	}
	elsif ($_ !~ m/[<>]/) {
		$text .= $_;
	}
	elsif ( ($_ =~ m/<\/w>/) || ($_ =~ m/<\/s>/) || ($_ =~ m/<\/p>/) ) {
		$text .= $_;
	}
	elsif ($_ =~ m/<s xml.+?>/) {
		$text .= "<s>\n";
	}
	elsif ($_ =~ m/<p xml.+?>/) {
		$text .= "<p>\n";
	}

	# METADATA + XML
	elsif ($_ =~ m/<title type="main">(.*?)<\/title>/) {
		$metadata{"titel"} = dexmlizeheader($1);
	}
	elsif ($_ =~ m/<author>(.*?)<\/author>/) {
		$metadata{"autor"} = $1;
	}
	elsif ($_ =~ m/<date>(.*?)<\/date>/) {
		$metadata{"datum"} = $1;
	}
	elsif ($_ =~ m/<placeName>(.*?)<\/placeName>/) {
		$metadata{"ort"} = $1;
	}
	elsif ($_ =~ m/<title type="excerpt">(.*?)<\/title>/) {
		$metadata{"untertitel"} = dexmlizeheader($1);
	}
	elsif ($_ =~ m/<interp type="address">(.*?)<\/interp>/) {
		#$flag = 1;
		$metadata{"anrede"} = dexmlizeheader($1);
	}
	elsif ($_ =~ m/<sourceDesc>(.*?)<\/sourceDesc>/) {
		#if ($flag == 0) {
		#	print METADATA "\",\"";
		#}
		#print METADATA $1 . "\"\n";
		$metadata{"quelle"} = $1;
	}
	elsif ($_ =~ m/<text xml.+?>/) {
		$text .= $_;
	}
	elsif ($_ =~ m/<\/text>/) {
		## PRINT AND CLEAR EVERYTHING
		# METADATA
		{ no warnings "uninitialized" ;
			print METADATA "\"BP_" . $docnr . "\",\"" . $metadata{"titel"} . "\",\"" . $metadata{"autor"} . "\",\"" . $metadata{"datum"} . "\",\"" . $metadata{"ort"} . "\",\"" . $metadata{"untertitel"} . "\",\"" . $metadata{"quelle"} . "\",\"" . $metadata{"anrede"} . "\"\n"; # or print METADATA "\"BK_" ...
		}
		# TEXT
		$text .= $_;
		$text = dexmlize($text);
		my $split = "Bundespräsidenten/BP_" . $docnr . ".xml"; # or my $split = "Bundesregierung/BK_" . $docnr . ".xml";
		open (SPLIT, ">", $split) or die "Can't open $split: $!";
		print SPLIT $text;
		close(SPLIT);
		$docnr++;
		$text = ();
		%metadata = ();
		#$flag = 0;
	}
}

close(INPUT);
close(METADATA);

print $docnr-1 . "\n";


### SUBROUTINES

sub dexmlizeheader {
	my $string = shift;
	$string =~ s/"/'/g;
	$string =~ s/&amp;quot;/'/g;
	$string =~ s/&quot;/'/g;
	$string =~ s/&rsquo;/'/g;
	$string =~ s/&apos;/'/g;
	$string =~ s/&amp;/&/g;
	return $string;
}

sub dexmlize {
	my $string = shift;
	unless ($string =~ m/type="\$\("/) {
		$string =~ s/&amp;quot;/"/g;
		$string =~ s/&quot;/"/g;
		$string =~ s/&rsquo;/"/g;
		$string =~ s/&apos;/'/g;
		$string =~ s/&amp;/&/g;
	}
	return $string;
}