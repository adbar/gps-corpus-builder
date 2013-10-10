#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.1 (http://code.google.com/p/gps-corpus-builder/).
###	Copyright (C) Adrien Barbaresi, 2013.
###	This is open source software, freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## BP subpart: Bundespräsidenten (Presidents)

# Function: Go through all the available archive pages to gather links.
# Use: without arguments.

## TODO:
# sitemaps are an option:
# http://www.bundespraesident.de/_config/XML-Sitemap/Sitemapindex.xml



use strict;
use warnings;
use LWP::UserAgent;
use open ':encoding(utf8)';


## init
my (@urls, $query, @links);
my $agent = "GPS-corpus-builder/1.1 +https://code.google.com/p/gps-corpus-builder/";

my $lwp_ua = LWP::UserAgent->new;
$lwp_ua->agent($agent);
$lwp_ua->timeout(12);


## load stoplist
my $stoplist = "Bundespraesidenten_stoplist";
open( STOPLIST, "<", $stoplist ) or die "Can't open $stoplist: $!";
my @stoplist = <STOPLIST>;
chomp (@stoplist);
close (STOPLIST);


### Process all the archive pages president by president


# Weizsäcker
for (my $n=4; $n>0; $n--) {
    $query = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Richard-von-Weizsaecker/Reden/reden-node.html?gtp=1892618_Dokumente%253D$n";
    push(@urls, $query);
}


# Herzog
for (my $n=10; $n>0; $n--) {
    $query = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Roman-Herzog/Reden/reden-node.html?gtp=1892654_Dokumente%253D$n";
    push(@urls, $query);
}


# Rau
for (my $n=31; $n>0; $n--) {
    $query = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Johannes-Rau/Reden/reden-node.html?gtp=1892758_Dokumente%253D$n";
    push(@urls, $query);
}


# Koehler
for (my $n=30; $n>0; $n--) {
    $query = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Horst-Koehler/Reden/reden-node.html?gtp=1892794_Dokumente%253D$n";
    push(@urls, $query);
}


# Wulff
for (my $n=23; $n>0; $n--) {
    $query = "http://www.bundespraesident.de/DE/Die-Bundespraesidenten/Christian-Wulff/Reden-und-Interviews/Reden/reden-node.html?gtp=2747996_Dokumente%253D$n";
    push(@urls, $query);
}


# Gauck
for (my $n=20; $n>0; $n--) {
    $query = "http://www.bundespraesident.de/DE/Bundespraesident-Joachim-Gauck/Reden-und-Interviews/Reden/reden-node.html?gtp=1891762_Dokumente%253D$n";
    push(@urls, $query);
}


print "Number of pages: " . scalar (@urls) . "\n";


### Extract the links

foreach my $url (@urls) {
    my $response = $lwp_ua->get($url);
    if ($response->is_success) {
        my $seite = $response->decoded_content;
        # prevent analysis of error pages
        if ($seite !~ m/<title>Errorpage<\/title>/) {
            my @temp = split ("<a", $seite);
            foreach my $j (@temp) {
                if ( $j =~ m/SharedDocs.+?\/Reden\/[0-9]{4}\/[0-9]{2}.+?\.html/ ) {
                    push (@links, "http://www.bundespraesident.de/" . $&);
                }
            }
        }
        else {
            print "Problem in query: error page fetched\n";
        }
    }
    else {
        print "Could not fetch URL: $url\n";
    }
    # sleep (important)
    sleep(10);
}

my %seen = ();
@links = grep { ! $seen{ $_ }++ } @links;
print "Total links: " , scalar(@links) , "\n";


### Write the links that are not in the stoplist (speeches in English) to a file

my $links = 'Bundespraesidenten_list-all';
open( LINKS, ">", $links ) || die "Can't open $links: $!";
$a = 0;
foreach my $n (@links) {
    unless ($n ~~ @stoplist) {
        print LINKS "$n\n";
        $a++;
    }
}

print "Number of links written: " , $a , "\n";

close (LINKS);
