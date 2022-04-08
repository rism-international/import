#!/bin/bash
echo $PWD
#bin/marcxml -t -c conf/oenb.yml -i input/test.xml -o output/out.xml
#bin/marcxml -t -c conf/oenb.yml -i input/input.xml -o output/out.xml
../../marcxml/marcxml -t -c conf/oenb.yml -i input/input.xml -o output/out.xml
