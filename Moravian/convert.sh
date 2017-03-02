#!/bin/bash

ACTUAL=$PWD
BIN="/home/dev/projects/marcxml-tools"
INPUT="/home/dev/projects/import/Moravian/input/input.xml"
OUTPUT="/home/dev/projects/import/Moravian/output/output.xml"
ANALYZE="/home/dev/projects/import/Moravian/output/output_analyze.yml"


echo "Convert Moravian"
cd $BIN
ruby marcxml --transform -i $INPUT -c conf/moravian.yaml -o $OUTPUT
ruby marcxml --analyze -i $OUTPUT -o $ANALYZE --with-content
ruby marcxml --analyze -i $INPUT -o $ACTUAL/input/input_analyze.yml --with-content

cd $ACTUAL/muscat
rails r housekeeping/import/import_from_marc.rb $ACTUAL/output/output.xml Source
