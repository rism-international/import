from sickle import Sickle
from lxml import etree

sickle = Sickle('https://eu02.alma.exlibrisgroup.com/view/oai/43ACC_ONB/request')
records = sickle.ListRecords(metadataPrefix='marc21', set='MUSHANMARC')

cnt = 0

ofile = open("oenb.xml", "w")
ofile.write("<collection>\n")
ofile.close()

for record in records:
  cnt = cnt + 1
  print(cnt)
  with open("oenb.xml", "a") as myfile:
    myfile.write(etree.tostring(record.xml, pretty_print=True, encoding='UTF-8') + "\n")

ofile = open("oenb.xml", "a+")
ofile.write("\n</collection>")
ofile.close




