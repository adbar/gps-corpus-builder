#!/usr/bin/perl


###	This script is part of the German political speeches corpus builder v1.0 (http://code.google.com/p/gps-corpus-builder/).
###	It is brought to you by Adrien Barbaresi.
###	It is freely available under the GNU GPL v3 license (http://www.gnu.org/licenses/gpl.html).

## BP subpart : Bundespräsidenten (Presidents)

# Function : process a list of links, get the HTML documents, scrape the HTML code and store the whole as an XML file containing metadata and rawtext.
# Use : without arguments.



use strict;
use warnings;
#use locale;
use LWP::Simple;
use Text::Trim;
use open ':encoding(utf8)';
use utf8;


### Initialisation

my $runs = 1;
my ($block, $seite, @text, $titel, $text, $excerpt, $info, $autor, $datum, $person, $ort, $untertitel, $anrede, @anrede, $muster, $anrpat, $kolmuster, $exmuster);
my ($url, $link, @links, @temp, $line, %seen, @stoplist);
my ($q, $a, $n, $string);

my $output = ">BP-all.xml";
open (OUTPUT, $output) or die;
print OUTPUT "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
print OUTPUT "<!DOCTYPE collection [
  <!ELEMENT collection (text+)>
  <!ELEMENT text (rohtext)>
  <!ATTLIST text person CDATA #REQUIRED>
  <!ATTLIST text titel CDATA #REQUIRED>
  <!ATTLIST text datum CDATA #REQUIRED>
  <!ATTLIST text ort CDATA #REQUIRED>
  <!ATTLIST text untertitel CDATA #REQUIRED>
  <!ATTLIST text url CDATA #REQUIRED>
  <!ATTLIST text anrede CDATA #REQUIRED>
  <!ELEMENT rohtext (#PCDATA)>
]>\n\n\n";
print OUTPUT "<collection>\n\n\n";


my $done = '>BP_list-done';
open (DONE, $done);

## Loading the list of links (collected by other scripts)

my $links = 'BP_list-all';
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


@temp = split ("<div id=\"main\">", $seite);
$seite = $temp[1];
@temp = split ("<div class=\"sectionRelated\">", $seite);
$seite = $temp[0];


## Extract metadata

# Person
if ($n =~ m/Horst-Koehler/) {
	$person = "Horst Köhler";
}
elsif ($n =~ m/Roman-Herzog/) {
	$person = "Roman Herzog";
}
elsif ($n =~ m/Johannes-Rau/) {
	$person = "Johannes Rau";
}
elsif ($n =~ m/Christian-Wulff/) {
	$person = "Christian Wulff";
}
elsif ($n =~ m/Richard-von-Weizsaecker/) {
	$person = "Richard von Weizsäcker";
}
elsif ($n =~ m/Joachim-Gauck/) {
	$person = "Joachim Gauck";
}
else {
	$person = "NN";
}
$person = "person=\"" . $person . "\" ";
push (@text, $person);



# Title
$seite =~ m/<h1.+?<\/h1>/s;
	$titel = $&;
	$titel = normalize($titel);
	$titel = xmlize($titel);
$titel = "titel=\"" . $titel . "\" ";
push (@text, $titel);
# Possible caveat : <h1 class="isFirstInSlot"><span>Eröffnung des 33. Evangelischen Kirchentages<br/>

# Info : date + place
$seite =~ m/<div class="article-metadata">.+?<\/div>/s;
$info = $&;
$info = normalize($info);

# Place
$info =~ m/[A-ZÄÖÜa-zäöü ,]+([A-ZÄÖÜa-zäöü ,]+|)/;
$ort = $&;
if ($ort !~ m/,/) {
$ort = "";
}
else {
$ort =~ s/,\s$//;
}

# Date
$info =~ m/[0-9]+\.[A-ZÄÖÜa-zäöü ]+[0-9]{4}/;
$datum = $&;
$datum = "datum=\"" . $datum . "\" ";
push (@text, $datum);

$ort = xmlize($ort);
$ort = "ort=\"" . $ort . "\" ";
push (@text, $ort);

# Subtitle
if ($seite =~ m/<div class="subheadline">/) {
$seite =~ m/<div class="subheadline">.+?<\/div>/s;
$untertitel = $&;
$untertitel = normalize($untertitel);
$untertitel = xmlize($untertitel);
$seite =~ s/<div class="subheadline">.+?<\/div>//gs;
}
else {
$untertitel = "";
}
$untertitel = "untertitel=\"" . $untertitel . "\" ";
push (@text, $untertitel);

# Url
$url= "url=\"" . $n . "\"" . "\n";
push (@text, $url);


## Text cleaning

@temp = split ("<div[ ]+id=\"main-inner\">", $seite);
$block = $temp[1];

$block =~ s/<div class="gallery-switcher">.+?<div class="gallery-pagination">//gs;
$block =~ s/<li class="pa.+?<\/li>//gs;
$block =~ s/Kein Flash-Plugin vorhanden//;


### Extract the addresses (not always efficient)

if ($block =~ m/Liebe Mitbürgerinnen und Mitbürger,/){
	$anrede = $&;
	$block =~ s/$anrede//;
}
elsif ($block =~ m/Anrede(|n)(,|!)/) {
	$anrede = $&;
	$block =~ s/$anrede//;
}

else {
	$anrpat = "(Verehrter|(S|s)ehr|Herr|(L|l)iebe(|r)|(M|m)eine)( sehr|)( geehrt|).+?(Herren|Festversammlung|träger|(G|g)äste|nrw|parlament|Bundestages|Kollegen|Anwesende|Freunde|Professor)[A-ZÄÖÜa-zäöü ]*?(,|!|)";
	$muster = "((M|m)eine |(S|s)ehr |((V|v)er|(G|g)e)ehrte(n|) )(((S|s)ehr |)((V|v)er|(G|g)e)ehrte(n|)|) ?(Damen und Herren|Gäste|Freunde)(,|!|)";
	$kolmuster = "Kolleginnen und Kollegen ?!";
	$exmuster = "Excellenzen,";
	$a = 1; $anrede = "";
	if ( ($block =~ m/$kolmuster/s) || ($block =~ m/$exmuster/s) ) {
		if ( length($&) < 250 ) {
			@temp = split ($&, $block);
			$anrede .= $temp[0] . " TUDU:" . $&;
			$block = $temp[1];
		}
	}
		if ( ($block =~ m/$anrpat/s) && (length($&) < 200) ) {
			@temp = split ($&, $block);
			if (length($temp[0]) < 550) {
				$anrede .= $&;
				shift (@temp);
				$block = join("", @temp);
			}
		}
}

$anrede = normalize($anrede);
$anrede = xmlize($anrede);
$anrede = "anrede=\"" . $anrede . "\">\n\n";
push (@text, $anrede);


### Process the paragraphs

push (@text, "<rohtext>\n");

## Text cleaning
$block =~ s/-* ?(E|e)s gilt das gesprochene Wort\.? ?!?-*//;
$block =~ s/(Änderungen vorbehalten. )?Es gilt das gesprochene Wort.//;
$block =~ s/\(.+?\)//g;
$block =~ s/<em>Fotos von der Konferenz finden Sie in derBildergalerie<\/em>\.//;
#$block =~ s/Redemanuskript!//;


#$block =~ s/^([a-z])/\U\1/;
$block =~ s/<span class="Verfgung">//g;
$block =~ s/<span.+?<\/span>//g;

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
	$string =~ s/('|&#8216;)/&apos;/g;
	$string =~ s/&/&amp;/g;
	$string =~ s/&#039;/&rsquo;/g;
	$string =~ s/&gt;&gt;//g;
	$string =~ s/&lt;&lt;//g;
	$string =~ s/&amp;quot;/&quot;/g;
	$string =~ s/(&#8220;|&#8221;|&#8222;|&#x201c;|&#x201e;|&#034;)/&quot;/g;
	$string =~ s/&#x2013;/\-\-/g;
	$string =~ s/(&#8211;|&#8212;)/–/g;
	$string =~ s/&#8364;/€/g;

	return $string;
}
