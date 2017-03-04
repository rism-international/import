#!/bin/bash
IMPORT=$1
BIN="/home/dev/projects/marcxml-tools"
TARGET="/home/dev/projects/import/$IMPORT"
INPUT="$TARGET/input/input.xml"
if [ ! -f $INPUT ]; then
  echo "File does not exits"
  exit
fi
OUTPUT="$TARGET/output/output.xml"
ANALYZE="$TARGET/output/output_analyze.yml"

echo "Convert BRNO"
cd $BIN
ruby marcxml --transform -i $INPUT -c conf/$IMPORT.yaml -o $OUTPUT
ruby marcxml --analyze -i $OUTPUT -o $ANALYZE --with-content

cd $TARGET/muscat

rails r $TARGET/../before_import.rb
rails r housekeeping/import/import_from_marc.rb $TARGET/output/output.xml Source
rails r $TARGET/../after_import.rb
rake sunspot:reindex
