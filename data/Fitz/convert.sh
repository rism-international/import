#!/bin/bash
echo $PWD

#../../marcxml/marcxml -t -c config/fitz.yaml -i input/holdings.xml -o output/holdings.xml
../../marcxml/marcxml -t -c config/fitz.yaml -i input/034-fitz-test.xml -o output/fitzwilliam.xml
