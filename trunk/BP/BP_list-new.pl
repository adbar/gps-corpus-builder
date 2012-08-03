#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.0 (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## BP subpart : Bundespräsidenten (Presidents)

# Function : find new links to crawl.
# Use : without arguments.



use strict;
use warnings;
use LWP::Simple;
use open ':encoding(utf8)';


my (@url, $seite, $n, $q, $a, $link, @links, @temp, $j, %seen, %liste);


### If it exists, read a list of already stored links

my $liste = 'BP_list-all';
open( LINKS, "<", $liste ) || die "Can't open $liste: $!";
while (<LINKS>) {
	chomp;
	$liste{$_}++;
	}
close (LINKS);


### Proceed all the recent archive pages (CMS hack) and extract the links

for ($n=30; $n>0; $n--) {
	$q = "http://www.bundespraesident.de/DE/Bundespraesident-Joachim-Gauck/Reden-und-Interviews/Reden/reden-node.html" . "?gtp=1891762_Dokumente%253D$n";
	push(@url, $q);
}

foreach $a (@url) {
$seite = get $a;

@temp = split ("<a", $seite);
foreach $j (@temp) {
if ( $j =~ m/SharedDocs.+?\/Reden\/[0-9]{4}\/[0-9]{2}.+?\.html/ ) {
	$link = "http://www.bundespraesident.de/" . $&;
	unless (exists $liste{$link}) {
	push (@links, $link);
	}
	}
}
}


### Write the links in a file

%seen = ();
@links = grep { ! $seen{ $_ }++ } @links;

my $links = 'BP_new-links';
open (LINKS, '>', $links) or die;

foreach $n (@links) {
print LINKS "$n\n";
}
close (LINKS);
