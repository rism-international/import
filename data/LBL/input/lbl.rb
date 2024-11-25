# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to ffm             #################################"
# puts "#########################   Expected collection size: 50.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require 'csv'
require 'pry'
require 'nokogiri'

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = []

#data = CSV.open(filename, headers: :first_row, :col_sep => "\t").map(&:to_h)
data = CSV.read(filename, headers: :first_row, :col_sep => "\t")

data.each do |e|
  res << {'001' => e[0], '852a' => 'GB-Lbl', '8520' => '30001581', '852c' => e[1], '500a1' => e[2], '500a2' => e[3], '856u' => e[4], '856x' => e[5], '856z' => e[6]}
end

doc = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.collection('xmlns' => "http://www.loc.gov/MARC21/slim") do
  end
end

collection = doc.doc.root

def datafield(record, field, code, content)
  tag = Nokogiri::XML::Node.new "datafield", record
  tag['tag'] = field
  tag['ind1'] = ' '
  tag['ind2'] = ' '
  sf = Nokogiri::XML::Node.new "subfield", record
  sf['code'] = code
  sf.content = content
  tag << sf
  record << tag
  return tag
end

def addSubfield(datafield, code, content)
  sf = Nokogiri::XML::Node.new "subfield", datafield
  sf['code'] = code
  sf.content = content
  datafield << sf
end

res.each do |e|
  record = Nokogiri::XML::Node.new "record", collection
  tag = Nokogiri::XML::Node.new "controlfield", record; tag['tag'] = '001'; tag.content = e['001']; record << tag
  df = datafield(record, "500", "a", e["500a1"]) if e["500a1"]
  df = datafield(record, "500", "a", e["500a2"]) if e["500a2"]
  df = datafield(record, "852", "a", e["852a"])
  addSubfield(df, "c", e["852c"])
  addSubfield(df, "0", e["8520"])
  df = datafield(record, "856", "u", e["856u"])
  addSubfield(df, "x", e["856x"])
  addSubfield(df, "z", e["856z"])





  collection << record

end

binding.pry
