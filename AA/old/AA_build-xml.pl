#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.0 (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## AA subpart : Auswärtiges Amt (Ministry of Foreign Affairs)

# Function : process a list of links, get the HTML documents, scrape the HTML code and store the whole as an XML file containing metadata and rawtext.
# Use : without arguments.



use strict;
use warnings;
#use locale;
use LWP::Simple;
use Text::Trim;
use open ':encoding(utf8)';
use utf8; #Problems with \xDF \xE4 \xF6


### Initialisation

my $runs = 1;
my ($block, $seite, @text, $titel, $text, $excerpt, $info, $autor, $datum, $person, $ort, $untertitel, $anrede, @anrede, $muster, $anrpat, $kolmuster, $exmuster);
my ($url, $link, @links, @temp, $line, %seen, @stoplist);
my ($q, $a, $n, $string);

my $output = "AA-all.xml";
open (OUTPUT, '>', $output) or die;
print OUTPUT "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
print OUTPUT "<!DOCTYPE collection [
  <!ELEMENT collection (text+)>
  <!ELEMENT text (rohtext)>
  <!ATTLIST text person CDATA #REQUIRED>
  <!ATTLIST text titel CDATA #REQUIRED>
  <!ATTLIST text datum CDATA #REQUIRED>
  <!ATTLIST text info CDATA #REQUIRED>
  <!ATTLIST text url CDATA #REQUIRED>
  <!ATTLIST text anrede CDATA #REQUIRED>
  <!ELEMENT rohtext (#PCDATA)>
]>\n\n\n";
print OUTPUT "<collection>\n\n\n";


my $done = 'AA_list-done';
open (DONE, '>', $done);

## Loading the list of links (collected by other scripts)

my $links = 'AA_list-all';
open( LINKS, "<", $links ) || die "Can't open $links: $!";
my @liste = <LINKS>;
chomp (@liste);
close (LINKS);
# Just in case... remove duplicates
%seen = ();
@liste = grep { ! $seen{ $_ }++ } @liste;

print scalar (@liste), "\n";


### Main loop

foreach $n (@liste) {
print DONE $n, "\n";

@text = ();
print OUTPUT "<text ";


## Fetch the page
$seite = get $n;

@temp = split ("<div class=\"reden\">", $seite);
$seite = $temp[1];
@temp = split ("<div id=\"footerWrap\">", $seite);
$seite = $temp[0];

## Extract metadata

# Title
$seite =~ m/<h1 class="isFirstInSlot">.+?<\/h1>/s;
$titel = $&;
$titel = normalize($titel);
$titel = xmlize($titel);
$titel = "titel=\"" . $titel . "\"\n";

# Person
if ($titel =~ m/Westerwelle/) {
	$person = "Guido Westerwelle";
}
elsif ($titel =~ m/Steinmeier/) {
	$person = "Frank-Walther Steinmeier";
}
else {
	$person = "NN";
}
$person = "person=\"" . $person . "\"\n";

push (@text, $person);
push (@text, $titel);

# Date
$seite =~ m/<p>([0-9]{2}\.[0-9]{2}\.[0-9]{4})<\/p>/;
$datum = $1;
$datum = "datum=\"" . $datum . "\"\n";
push (@text, $datum);

# Url
$url= "url=\"" . $n . "\"" . "\n";
push (@text, $url);


## Text cleaning

$seite =~ s/<h1 class="isFirstInSlot">.+?<\/h1>//s;
$seite =~ s/<p>[0-9]{2}\.[0-9]{2}\.[0-9]{4}<\/p>//;
$seite =~ s/<!--.+?-->//s;
$seite =~ s/-* ?(E|e)s gilt das gesprochene Wort\.? ?!?-*//;

if ($seite =~ m/--------------------------------/) {
	@temp = split ("--------------------------------", $seite);
	$untertitel = $temp[0];
	$block = $temp[1];
	$info = $untertitel;
}
else {
$info = "";
$block = $seite;
}

if ($block =~ m/<h5 class.+?<\/h5>/s) {
	$info .= $&;
	$block =~ s/$&//s;
}
if ($block =~ m/Grußwort von.+?$/) {
	$info .= $&;
	$block =~ s/$&//s;
}
if ($block =~ m/Staatsministerin Cornelia Pieper.+?$/) {
	$info .= $&;
	$block =~ s/$&//s;
}

$info = normalize($info);
$info = xmlize($info);
$info = "info=\"" . $info . "\"\n";
push (@text, $info);



## Problems that may still appear
#$block =~ s/<div class="gallery-switcher">.+?<div class="gallery-pagination">//gs;
#$block =~ s/<li class="pa.+?<\/li>//gs;
#$block =~ s/Kein Flash-Plugin vorhanden//;


### Extract the addresses (not always efficient)

if ($block =~ m/Liebe Mitbürgerinnen und Mitbürger,/){
	$anrede = $&;
	$block =~ s/$anrede//;
}
elsif ($block =~ m/Anrede(|n),/) {
	$anrede = $&;
	$block =~ s/$anrede//;
}
else {
	$anrpat = "(Verehrter|(S|s)ehr|Herr|(L|l)iebe(|r)|(M|m)eine)( sehr|)( geehrt|).+?(Herren|Festversammlung|träger|(G|g)äste|nrw|parlament|Bundestages|Kollegen|Anwesende|Freunde|Professor) ?(,|!|)\$" ;
	$muster = "((M|m)eine |)(((S|s)ehr |)((V|v)er|(G|g)e)ehrte(n|)|) ?(Damen und Herren|Gäste|Freunde)(,|!|\$)";
	$kolmuster = "Kolleginnen und Kollegen ?!";
	$exmuster = "Excellenzen,";
	$a = 1; $anrede = "";
	if ($block =~ m/$muster/s) {
		if ( length($&) < 550 ) {
			@temp = split ($&, $block);
			$anrede = $temp[0] . " " . $&;
			$block = $temp[1];
		}
	}
	if ( ($block =~ m/$kolmuster/s) || ($block =~ m/$exmuster/s) ) {
		if ( length($&) < 550 ) {
			@temp = split ($&, $block);
			$anrede .= $temp[0] . " " . $&;
			$block = $temp[1];
		}
	}
	while ($a == 1) {
		if ( ($block =~ m/$anrpat/s) ) { #&& (length($&) < 200) ) {
			if ( length($&) < 550 ) {
				$anrede .= " " . $&;
				$block =~ s/$&//s;
			}
		}
		else {
			$a = 0;
		}
	}
}

$anrede = normalize($anrede);
$anrede = xmlize($anrede);
$anrede = "anrede=\"" . $anrede . "\">\n\n";
push (@text, $anrede);


### Find the English texts (if indicated as an attribute)

my $count = () = $block =~ /lang="(en|EN)\-GB"/g;
if ($count > 2) {
	push (@stoplist, $n);
}


### Process the paragraphs

push (@text, "<rohtext>\n");

$block =~ s/(Änderungen vorbehalten. )?Es gilt das gesprochene Wort.//;
$block =~ s/\(.+?\)//g;
#$block =~ s/<em>Fotos von der Konferenz finden Sie in derBildergalerie<\/em>\.//;
$block =~ s/Redemanuskript!//;

#$block =~ s/^(-|)\s+$//g;
#$block =~ s/^([a-z])/\U\1/;
#$block =~ s/<span.+?<\/span>//g;

$block = normalize($block);
$block = xmlize($block);
push (@text, $block);

push (@text, "</rohtext>\n");
$text = join ("", @text);

print OUTPUT "$text";
print OUTPUT "</text>\n\n";

$runs++;
} # end of main loop


### Write to file

print OUTPUT "</collection>";
close (OUTPUT);
close (DONE);

my $stoplist = 'AA_stoplist-auto';
open( STOPLIST, ">", $stoplist ) || die "Can't open $stoplist: $!";

foreach $n (@stoplist) {
	print STOPLIST "$n\n";
}
close (STOPLIST);


## Subroutines : text cleaning and XML conversion

sub normalize {
	my $string = shift;

	$string =~ s/<div class="bildBeschriftung">.+?<\/div>//gs;
	$string =~ s/<p class="beschreibung">.+?<\/p>//gs;
	$string =~ s/<p class="copyright">.+?<\/p>//gs;
	$string =~ s/<p class="picInfo">.+?<\/p>//gs;

	$string =~ s/<\/p>/\n/g;
	$string =~ s/<script type="text\/javascript">.+?<\/script>//gs;

	$string =~ s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;
	$string =~ s/^\W*//g;

	my @temp = split("\n", $string);
	trim (@temp);
	$string = join ("\n", @temp);
	$string =~ s/[\n\r]+/\n/g;

	return $string; #unless ($string =~ m/^$/) ;
}

sub xmlize {
	my $string = shift;
	$string =~ s/["„“”‚’]/&quot;/g;
	$string =~ s/'/&apos;/g;
	$string =~ s/&/&amp;/g;
	$string =~ s/&#039;/&rsquo;/g;
	$string =~ s/&gt;&gt;//g;
	$string =~ s/&lt;&lt;//g;
	$string =~ s/&amp;quot;/&quot;/g;
	$string =~ s/(&#8221;|&#x201c;|&#x201e;)/&quot;/g;
	$string =~ s/&#x2013;/\-\-/g;

	return $string;
}