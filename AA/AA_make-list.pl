#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## AA subpart : Auswärtiges Amt (Ministry of Foreign Affairs)

# Function : Go through all the available archive pages to gather links.
# Use : without arguments.



use strict;
use warnings;
use LWP::Simple;
use open ':encoding(utf8)';
use utf8;

my ($url, @url, $seite, $n, $q, $a, $link, @links, @temp, @done, $line, %seen, $j, $b);

### Process all the archive pages year by year

#2006
for ($n=4; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2006_ArchivReden_node.html?gtp=588814_unnamed%253D$n";
	push(@url, $q);
}

#2007
for ($n=7; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2007_ArchivReden_node.html?gtp=594928_unnamed%253D4%2526594926_unnamed%253D$n";
	push(@url, $q);
}

#2008
for ($n=7; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2008_ArchivReden_node.html?gtp=594936_unnamed%253D$n";
	push(@url, $q);
}

#2009
for ($n=5; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2009_ArchivReden_node.html?gtp=594946_unnamed%253D$n";
	push(@url, $q);
}

#2010
for ($n=5; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2010_ArchivReden_node.html?gtp=594956_unnamed%253D$n";
	push(@url, $q);
}

#2011
for ($n=7; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2011_ArchivReden_node.html?gtp=605382_unnamed%253D$n";
	push(@url, $q);
}

#2012
for ($n=30; $n>0; $n--) {
	$q = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/ArchivReden_node.html" . "?gtp=532008_unnamed%253D$n";
	push(@url, $q);
}


print "Number of pages: " . scalar (@url) . "\n";


### Extract the links

foreach $a (@url) {
$seite = get $a;

@temp = split ("<a", $seite);
foreach $j (@temp) {
if ( $j =~ m/(Reden\/[0-9]{4}\/[0-9]{6}.+?\.html)/ ) {
	$link = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/" . $1;
	push (@links, $link);
	}
}
}

%seen = ();
@links = grep { ! $seen{ $_ }++ } @links;
print "Total links: " , scalar(@links) , "\n";


### Write the links that are not in the stoplist (speeches in English) to a file

my $stoplist = 'AA_stoplist';
open( INPUT, "<", $stoplist ) || die "Can't open $stoplist: $!";
my @stoplist = <INPUT>;
chomp (@stoplist);
close (INPUT);

my $links = 'AA_list-all';
open( LINKS, ">", $links ) || die "Can't open $links: $!";
$a = 0;
foreach $n (@links) {
	unless ($n ~~ @stoplist) {
		print LINKS "$n\n";
		$a++;
	}
}

print "Number of links written: " , $a , "\n";

close (LINKS);
