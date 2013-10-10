#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.1 (http://code.google.com/p/gps-corpus-builder/).
###	Copyright (C) Adrien Barbaresi, 2013.
###	This is open source software, freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## BR subpart: Bundesregierung (Chancellor and a few ministers)

# Function: Go through all the available archive pages between certain dates to gather links.
# Use: perl Bundesregierung_find-links.pl --begin 01.01.2012 --end 01.01.2013 --verbose


use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use open ':encoding(utf8)';


## Variables
my (@urls, %liste, %seen);
my $counter = 0;
my ($help, $begin, $end, $existing_file, $verbose, $page);

## User Agent
my $lwp_ua = LWP::UserAgent->new;
$lwp_ua->agent("GPS-corpus-builder/1.1 +https://code.google.com/p/gps-corpus-builder/");
$lwp_ua->timeout(12);


### Parse args
usage() if ( @ARGV < 1
	or ! GetOptions ('help|h' => \$help, 'begin|b=s' => \$begin, 'end|e=s' => \$end, 'seen=s' => \$existing_file, 'verbose|v' => \$verbose)
	or defined $help
);

sub usage {
	print "Unknown option: @_\n" if ( @_ );
	print "Usage: perl " . $0 . " [--begin|-b] DD.MM.YYYY [--end|-e] DD.MM.YYYY [--seen|-s] filename\n\n";
	print "begin and end: dates in DD.MM.YYYY format\n";
	print "seen: already existing list (optional)\n";
	print "help: display this message\n\n";
	exit;
}


### If it exists, read a list of already stored links
if (defined $existing_file) {
    open(my $existing_fh, "<", $existing_file ) || die "Can't open $existing_file: $!";
    while (<$existing_fh>) {
        chomp;
        $liste{$_}++;
    }
    close ($existing_fh);
}


### Fetch the query URL and extract the links (CMS hack)

## Fetch the first page
my $query = "dateOfIssue_startDate=" . $begin . "&path=%2FBPAInternet%2FContent%2FDE%2FRede*&docType=Speech&dateOfIssue_stopDate=" . $end;
print "Initiating query from " . $begin . " to " . $end . "\n";

my $response = $lwp_ua->get("http://www.bundesregierung.de/SiteGlobals/Forms/Webs/Breg/Suche/DE/Nachrichten/Redensuche_formular.html?" . $query);
if ($response->is_success) {
    $page = $response->decoded_content;
}
else {
    die "Problem during fetching of first query, aborting.";
}

if (defined $verbose) {
    print length($page) . "\n";
}
if ($page =~ m/<h3>Anzahl der .+?([0-9]+)<\/h3>/) {
    print $1 . " URLs expected.\n";
}

## Patterns
my $next_regex = qr/<li class="forward">.+?<a href="(SiteGlobals\/.+?Redensuche_formular\.html.+?amp;pageNo=[0-9]+)\"/s;
my $extract_pattern = qr/href="(Content\/DE\/Rede\/[0-9]{4}\/[0-9]{2}\/.+?\.html)/;


## Loop
my $loop_control = 1;
while ($loop_control == 1) {
    $counter++;
    if (defined $verbose) {
        print length($page) . "\n";
    }
    push (@urls, extract($page));
    if ($page =~ m/$next_regex/) {
        my $next = $1;
        # sanitize
        $next =~ s/&amp;/&/g; 
        # sleep (important)
        sleep(10);
        if (defined $verbose) {
            print "fetching: " . $next . "\n";
        }
        my $response = $lwp_ua->get("http://www.bundesregierung.de/" . $next);
        if ($response->is_success) {
            $page = $response->decoded_content;
        }
        else {
            print "This page could not be fetched: " . "http://www.bundesregierung.de/" . $next . "\n";
        }
        # output stats
        if ($next =~ m/queryResultId=([0-9]+)&.+?pageNo=([0-9]+)/) {
            print "page number: " . $2 . "\tquery id: " . $1 . "\n";
        }
    }
    else {
        print "Crawl finished after " . $counter . " requests\n";
        $loop_control = 0;
    }
}


## Extract the URLs (sub)
sub extract {
    # init
    my $html = shift;
    my @templinks;
    # split and extract
    foreach (split ("<a", $html)) {
        # print $_ . "\n";
        if ($_ =~ m/$extract_pattern/) {
            if (defined $existing_file) {
                my $tempurl = "http://www.bundesregierung.de/" . $1;
                unless (exists $liste{$tempurl}) {
                    push (@templinks, $tempurl);
                }
            }
            else {
                push (@templinks, "http://www.bundesregierung.de/" . $1);
            }
        }
    }
    # fast deduplicate
    %seen = ();
    @templinks = grep { ! $seen{ $_ }++ } @templinks;
    # return the list
    return @templinks;
}


### Write the links in a file
%seen = ();
@urls = grep { ! $seen{ $_ }++ } @urls;
print scalar(@urls) . " URLs found.\n";

my $output = "Bundesregierung_new-links"; #.txt ?
open (my $output_fh, ">>", $output) or die "Can't open $output: $!";
foreach my $url (@urls) {
    print $output_fh "$url\n";
}
close ($output_fh);
