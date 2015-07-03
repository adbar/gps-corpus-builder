### DESCRIPTION ###

Tools to crawl German official speeches repositories in order to gather a corpus.

A complete version of the corpus including a visualization tool is available here : [http://purl.org/corpus/german-speeches](http://purl.org/corpus/german-speeches)

Starting from the front page, the crawler retrieves a list of links. Then, the corpus builder explores it, stripping the text of each speech out of the HTML formatting and saving it into an XML file containing the metadata that could be extracted (e.g. the speaker, the date or the place) and raw text.

Due to its specialization this tool is able to build a reliable corpus.



### FILES & USAGE ###

The initial release of the software can be downloaded as a [bundle (gps-corpus-builder-1.0.zip)](http://gps-corpus-builder.googlecode.com/files/gps-corpus-builder-1.0.zip) which includes tools to gather three subcorpora : the German Chancellery, Presidency and Ministry of Foreign Affairs.

For more information please refer to the [README file](http://code.google.com/p/gps-corpus-builder/source/browse/trunk/README).