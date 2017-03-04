#!/bin/bash
IMPORT=$1
BIN="/home/dev/projects/marcxml-tools"
TARGET="/home/dev/projects/import/$IMPORT"
INPUT="$TARGET/input/input.xml"
if [ ! -f $INPUT ]; then
  echo "File does not exits"
  exit
fi

echo "Convert $IMPORT"
cd $BIN
ruby marcxml --transform -i $INPUT -c conf/$IMPORT.yaml -o $TARGET/output/output.xml
ruby marcxml --analyze -i $TARGET/output/output.xml -o $TARGET/output/output_analyze.yml --with-content

cd $TARGET/muscat

rails r $TARGET/../before_import.rb
rails r housekeeping/import/import_from_marc.rb $TARGET/output/output.xml Source
rails r $TARGET/../after_import.rb
rake sunspot:reindex
echo $(date)
echo "Sucessfully imported $IMPORT records!"
