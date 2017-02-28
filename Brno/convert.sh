#!/bin/bash

BIN="/home/dev/projects/marcxml-tools"
INPUT="/home/dev/projects/import/Brno/input/input.xml"
OUTPUT="/home/dev/projects/import/Brno/output/output.xml"
ANALYZE="/home/dev/projects/import/Brno/output/output_analyze.yml"


echo "Convert BRNO"
cd $BIN
ruby marcxml --transform -i $INPUT -c conf/brno.yaml -o $OUTPUT
ruby marcxml --analyze -i $OUTPUT -o $ANALYZE --with-content
#rails r housekeeping/import/import_from_marc.rb ../Brno/output/output.xml Source
