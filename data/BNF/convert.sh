#!/bin/bash
echo $PWD

../../marcxml/marcxml -t -c conf/bnf.yaml -i input/input.xml -o output/output.xml

