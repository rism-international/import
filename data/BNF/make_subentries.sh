#!/bin/bash
echo "Build subentries"
ruby build_ids.rb -i input/unimarc_input.xml -o id.yml
ruby build_subentries.rb -i input/unimarc_input.xml -o input/input.xml
