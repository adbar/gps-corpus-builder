#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.0 (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## BK subpart : Bundeskanzlerin (Chancellor)

# Function : Go through all the available archive pages to gather links.
# Use : without arguments.



use strict;
use warnings;
use LWP::Simple;
use open ':encoding(utf8)';


my (@url, $seite, $n, $q, $a, $link, @links, @temp, $j, %seen);


### Process all the archive pages of the Chancellor's website

for ($n=30; $n>0; $n--) {
	$q = "http://www.bundeskanzlerin.de/Webs/BK/De/Aktuell/Reden/reden.html" . "?gtp=74416_items%253D$n";
	push(@url, $q);
}


print "Number of pages: " . scalar (@url) . "\n";


### Extract the links

foreach $a (@url) {
	$seite = get $a;
	if ($seite) {
		@temp = split ("<a", $seite);
		foreach $j (@temp) {
			if ( $j =~ m/Content\/DE\/Rede\/[0-9]{4}\/[0-9]{2}\/.+?\.html/ ) {
				$link = "http:\/\/www.bundeskanzlerin.de\/" . $&;
				push (@links, $link);
			}
		}
	}
}

%seen = ();
@links = grep { ! $seen{ $_ }++ } @links;
print "Total links: " , scalar(@links) , "\n";


### Write the links that are not in the stoplist (e.g. speeches in English) to a file

my $stoplist = 'BK_stoplist';
my @stoplist;
if (-e $stoplist) {
	open( STOPLIST, "<", $stoplist ) || die "Can't open $stoplist: $!";
	@stoplist = <STOPLIST>;
	chomp (@stoplist);
	close (STOPLIST);
}

my $links = 'BK_list-all';
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
