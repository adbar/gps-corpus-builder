#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.1 (http://code.google.com/p/gps-corpus-builder/).
###	Copyright (C) Adrien Barbaresi, 2013.
###	This is open source software, freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## AA subpart: Auswärtiges Amt (Ministry of Foreign Affairs)

# Function: Go through all the available archive pages to gather links.
# Use: without arguments.



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
my $stoplist = 'Auswaertiges-Amt_stoplist';
open( INPUT, "<", $stoplist ) or print "Can't open $stoplist: $!";
my @stoplist = <INPUT>;
chomp (@stoplist);
close (INPUT);


### Process all the archive pages year by year

#2006
for (my $n=4; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2006_ArchivReden_node.html?gtp=588814_unnamed%253D$n";
    push(@urls, $query);
}

#2007
for (my $n=7; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2007_ArchivReden_node.html?gtp=594926_unnamed%253D$n";
    push(@urls, $query);
}

#2008
for (my $n=7; $n>0; $n--) {
	$query = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2008_ArchivReden_node.html?gtp=594936_unnamed%253D$n";
	push(@urls, $query);
}

#2009
for (my $n=5; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2009_ArchivReden_node.html?gtp=594946_unnamed%253D$n";
    push(@urls, $query);
}

#2010
for (my $n=5; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2010_ArchivReden_node.html?gtp=594956_unnamed%253D$n";
    push(@urls, $query);
}

#2011
for (my $n=6; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/Archivlisten_Reden/2011_ArchivReden_node.html?gtp=605382_unnamed%253D$n";
    push(@urls, $query);
}

#2012
for (my $n=30; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/ArchivReden_node.html?gtp=532008_unnamed%253D$n";
    push(@urls, $query);
}


### Process the pages linked to a particular person

# Westerwelle
for (my $n=25; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/yyy_Archivlisten/ArchivPresse/BM-Reden/dyn_Liste_lang_node.html?gtp=550356_list%253D$n";
    push(@urls, $query);
}

# Link
for (my $n=3; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/yyy_Archivlisten/ArchivPresse/StM-Link-Reden/dyn_Liste_lang_node.html?gtp=606852_list%253D$n";
    push(@urls, $query);
}

# Pieper
for (my $n=9; $n>0; $n--) {
    $query = "http://www.auswaertiges-amt.de/DE/yyy_Archivlisten/ArchivPresse/StM-Pieper-Reden/dyn_Liste_lang_node.html?gtp=550720_list%253D$n";
    push(@urls, $query);
}


print "Number of pages: " . scalar (@urls) . "\n";


### Extract the links

foreach my $url (@urls) {
    my $response = $lwp_ua->get($url);
    if ($response->is_success) {
        my $seite = $response->decoded_content;
        my @temp = split ("<a", $seite);
        foreach my $j (@temp) {
            if ( $j =~ m/Reden\/[0-9]{4}\/[0-9]{6}.+?\.html/ ) {
	        push (@links, "http://www.auswaertiges-amt.de/DE/Infoservice/Presse/" . $&);
	    }
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

my $links = 'Auswaertiges-Amt_list-all';
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
