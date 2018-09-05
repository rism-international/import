#!/bin/bash
echo $PWD
bin/marcxml -t -c bin/oenb.yaml -i input/oenb.xml -o output/test.xml
