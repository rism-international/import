#!/bin/bash
IMPORT="Brno"
ACTUAL=$PWD
BIN="/home/dev/projects/marcxml-tools"
INPUT="/home/dev/projects/import/$IMPORT/input/input.xml"
OUTPUT="/home/dev/projects/import/$IMPORT/output/output.xml"
ANALYZE="/home/dev/projects/import/$IMPORT/output/output_analyze.yml"

echo "Convert BRNO"
cd $BIN
ruby marcxml --transform -i $INPUT -c conf/$IMPORT.yaml -o $OUTPUT
ruby marcxml --analyze -i $OUTPUT -o $ANALYZE --with-content

cd $ACTUAL/muscat
rails r housekeeping/import/import_from_marc.rb $ACTUAL/output/output.xml Source
