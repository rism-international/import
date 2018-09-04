#!/bin/bash
echo $PWD

../../marcxml/marcxml -t -c config/iccu.yaml -i input/input.xml -o output/output.xml
