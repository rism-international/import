#!/bin/bash

ACTUAL=$PWD
BIN="/home/dev/projects/marcxml-tools"
INPUT="/home/dev/projects/import/BNF/input/input.xml"
OUTPUT="/home/dev/projects/import/BNF/output/output.xml"
ANALYZE="/home/dev/projects/import/BNF/output/output_analyze.yml"

echo "Build subentries"
#ruby build_ids.rb -i input/unimarc_input.xml -o id.yml
#ruby build_subentries.rb -i input/unimarc_input.xml -o input/input.xml


echo "Convert BNF"
cd $BIN
#ruby marcxml --transform -i $INPUT -c conf/bnf.yaml -o $OUTPUT
#ruby marcxml --analyze -i $OUTPUT -o $ANALYZE --with-content
#ruby marcxml --analyze -i $INPUT -o $ACTUAL/input/input_analyze.yml --with-content

cd $ACTUAL/muscat
rails r housekeeping/import/import_from_marc.rb $ACTUAL/output/output.xml Source
