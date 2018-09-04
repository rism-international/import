#!/bin/bash
echo $PWD
bin/marcxml -t -c config/iccu.yaml -i input/input.xml -o output/output.xml
