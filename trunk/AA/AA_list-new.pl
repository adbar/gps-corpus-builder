#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## AA subpart : Auswärtiges Amt (Ministry of Foreign Affairs)

# Function : find new links to crawl.
# Use : without arguments.



use strict;
use warnings;
use LWP::Simple;
use open ':encoding(utf8)';


my ($url, @url, $seite, $n, $q, $a, $link, @links, @temp, @done, $line, $j, %liste, %seen);


### If it exists, read a list of already stored links

my $liste = 'AA_list-all';
if (-e $liste) {
open (LINKS, '<', $liste) or die;
	while (<LINKS>) {
	chomp;
	$liste{$_}++;
	}
close (LINKS) or die;
}


### Proceed all the recent archive pages (CMS hack) and extract the links

for ($n=30; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/ArchivReden_node.html" . "?gtp=532008_unnamed%253D$n";
	push(@url, $q);
}

foreach $a (@url) {
$seite = get $a;

@temp = split ("<a", $seite);

foreach $j (@temp) {
if ( $j =~ m/(Reden\/[0-9]{4}\/[0-9]{6}.+?\.html)/ ) {
	$link = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/" . $1;
	unless (exists $liste{$link}) {
		push (@links, $link);
	}
	}
}
}

### Write the links in a file

%seen = ();
@links = grep { ! $seen{ $_ }++ } @links;

my $links = 'AA_new-links';
open (LINKS, '>', $links) or die;

foreach $n (@links) {
print LINKS "$n\n";
}
close (LINKS);
