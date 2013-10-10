#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.0 (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## BP subpart : Bundespräsidenten (Presidents)

# Function : Go through all the available archive pages to gather links.
# Use : without arguments.


use strict;
use warnings;
use LWP::UserAgent;
use open ':encoding(utf8)';


## init
my (@sitemaps, @urls, $seite);
my $lwp_ua = LWP::UserAgent->new;
$lwp_ua->agent("GPS-Corpus-Builder/1.1 +https://code.google.com/p/gps-corpus-builder/");
# $lwp_ua->agent("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:24.0) Gecko/20100101 Firefox/24.0");
$lwp_ua->timeout(12);


## load stoplist
my $stoplist = "Bundespraesidenten_stoplist";
open( STOPLIST, "<", $stoplist ) || die "Can't open $stoplist: $!";
my @stoplist = <STOPLIST>;
chomp (@stoplist);
close (STOPLIST);


### Load all the sitemaps
push (@sitemaps, "http://www.bundespraesident.de/_config/XML-Sitemap/Joachim-Gauck-Reden-Sitemap.xml");
push (@sitemaps, "http://www.bundespraesident.de/_config/XML-Sitemap/Roman-Herzog-Reden-Sitemap.xml");
push (@sitemaps, "http://www.bundespraesident.de/_config/XML-Sitemap/Horst-Koehler-Reden-Sitemap.xml");
push (@sitemaps, "http://www.bundespraesident.de/_config/XML-Sitemap/Johannes-Rau-Reden-Sitemap.xml");
push (@sitemaps, "http://www.bundespraesident.de/_config/XML-Sitemap/Richard-von-Weizsaecker-Reden-Sitemap.xml");
push (@sitemaps, "http://www.bundespraesident.de/_config/XML-Sitemap/Christian-Wulff-Reden-Sitemap.xml");
print "Number of pages: " . scalar (@sitemaps) . "\n";


### Extract the links

foreach my $sitemap (@sitemaps) {
    my $response = $lwp_ua->get($sitemap);
    if ($response->is_success) {
        $seite = $response->decoded_content;

        # prevent analysis of error pages
        if ($seite !~ m/<title>Errorpage<\/title>/) {
            # split the sitemap
            my @temp = split ("<loc>", $seite);
            foreach my $j (@temp) {
                if ( $j =~ m/http:\/\/www.bundespraesident.de\/SharedDocs\/Reden\/DE\/.+?\/Reden\/[0-9]{4}\/[0-9]{2}\/.+?\.html/ ) {
                    push (@urls, $&);
                }
            }
        }
        else {
            print "Problem in query: error page fetched\n";
        }
    }
    # sleep (important)
    sleep(10);
}

## TMP
open( TEMP, ">", "temp" );
print TEMP $seite;
close(TEMP);

my %seen = ();
@urls = grep { ! $seen{ $_ }++ } @urls;
print "Total links: " , scalar(@urls) , "\n";


### Write the links that are not in the stoplist (speeches in English) to a file

my $links = "Bundespraesidenten_list-all-xml";
open( LINKS, ">>", $links ) || die "Can't open $links: $!";
$a = 0;
foreach my $n (@urls) {
    unless ($n ~~ @stoplist) {
        print LINKS "$n\n";
        $a++;
    }
}

print "Number of links written (i.e. not on stoplist): " , $a , "\n";

close (LINKS);
