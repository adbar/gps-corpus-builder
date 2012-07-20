#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## BP subpart : Bundespräsidenten (Presidents)

# Function : Go through all the available archive pages to gather links.
# Use : without arguments.



use strict;
use warnings;
use LWP::Simple;
use List::MoreUtils qw(uniq);


my ($url, @url, $seite, $n, $q, $a, $link, @links, @temp, $line, @unique, $j);


### Process all the archive pages president by president

# Weizsäcker
for ($n=3; $n>0; $n--) {
	$q = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Richard-von-Weizsaecker/Reden/reden-node.html" . "?gtp=1892618_Dokumente%253D$n";
	push(@url, $q);
}


# Herzog
for ($n=8; $n>0; $n--) {
	$q = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Roman-Herzog/Reden/reden-node.html" . "?gtp=1892654_Dokumente%253D$n";
	push(@url, $q);
}


# Rau
for ($n=30; $n>0; $n--) {
	$q = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Johannes-Rau/Reden/reden-node.html" . "?gtp=1892758_Dokumente%253D$n";
	push(@url, $q);
}


# Koehler
for ($n=28; $n>0; $n--) {
	$q = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Horst-Koehler/Reden/reden-node.html" . "?gtp=1892794_Dokumente%253D$n";
	push(@url, $q);
}


# Wulff
for ($n=22; $n>0; $n--) {
	$q = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Christian-Wulff/Reden-und-Interviews/Reden/reden-node.html" . "?gtp=2747996_Dokumente%253D$n";
	push(@url, $q);
}


# Gauck
for ($n=15; $n>0; $n--) {
	$q = "http://www.bundespraesident.de/DE/Bundespraesident-Joachim-Gauck/Reden-und-Interviews/Reden/reden-node.html" . "?gtp=1891762_Dokumente%253D$n";
	push(@url, $q);
}


print "Number of pages: " . scalar (@url) . "\n";


### Extract the links

foreach $a (@url) {
$seite = get $a;

if ($seite) {
@temp = split ("<a", $seite);
foreach $j (@temp) {
if ( $j =~ m/SharedDocs.+?\/Reden\/[0-9]{4}\/[0-9]{2}.+?\.html/ ) {
	$link = "http://www.bundespraesident.de/" . $&;
	push (@links, $link);
	}
}
}
}

@unique = uniq @links;
print "Total links: " , scalar(@unique) , "\n";


### Write the links that are not in the stoplist (speeches in English) to a file

my $stoplist = 'BP_stoplist';
open( STOPLIST, "<", $stoplist ) || die "Can't open $stoplist: $!";
my @stoplist = <STOPLIST>;
chomp (@stoplist);
close (STOPLIST);

my $links = 'BP_list-all';
open( LINKS, ">", $links ) || die "Can't open $links: $!";
$a = 0;
foreach $n (@unique) {
	unless ($n ~~ @stoplist) {
		print LINKS "$n\n";
		$a++;
	}
}

print "Number of links written: " , $a , "\n";

close (LINKS);
