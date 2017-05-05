Description
-------------

In this folder there are two scripts for processing the original ICCU-marc-file of people 'names.xml' to manage the import of the data in Muscat:

Converter
---------
* First there is a converter 'convert\_people.rb' which transforms the original file into a MARC21-xml called 'iccu\_people\_import.xml' with selected fields. Additional there is a function to get VIAF references into the converted file from viaf.org, so the result will be something like:
```text
=024 $2 VIAF $a 1293
=024 $2 ICCU $a BVC78
=100 $a full_name $d life_date
```

Also this script filters out all institutions with datafield 210.

Importer
----------
* Second the import script 'import\_people.rb' with the task of import new people to muscat or make a reference to VIAF/ICCU with existing people.

Matching is done in two steps:
In a first step it looks for a person with the same VIAF-ID and inserts the ICCU-ID.
Then it looks for a person with the same name and make a reference with ICCU-ID.

At the end all people without any matching are created in Muscat, all the others have references to ICCU in subfield 024.

Result
-------
Result is online at the adress http://iccu.rism.info, it can be filtered to the import set with http://iccu.rism.info/admin/people?utf8=%E2%9C%93&q%5Bfull_name_equals%5D=ICCU&commit=Filtern&order=full_name_desc


