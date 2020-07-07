require 'nokogiri'
require 'csv'
require 'yaml'
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
class Marc
  def each_record(filename, &block)
    File.open(filename) do |file|
      Nokogiri::XML::Reader.from_io(file).each do |node|
        if node.name == 'record' || node.name == 'marc:record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          yield(Nokogiri::XML(node.outer_xml, nil, "UTF-8"))
        end
      end
    end
  end
end

ids = YAML.load_file("ids.yml")

res = []
Marc.new.each_record("input.xml") do |node|
  id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.content
  rism_id = ids[id]
  puts rism_id

  s128_b = node.xpath("//marc:datafield[@tag='128']/marc:subfield[@code='b']", NAMESPACE).map{|f| f.content}.join(";")
  s128_c = node.xpath("//marc:datafield[@tag='128']/marc:subfield[@code='c']", NAMESPACE).map{|f| f.content}.join(";")

  if s128_b.size > 0 or s128_c.size > 0
    res << [rism_id, id, s128_b, s128_c]
  end
  #unless fields.empty?
  #  res << [id, fields.map{|f| f.content}.join("; ")]
  #end
end

CSV.open("128.csv", "w") do |csv|
  csv << %w(RISM_ID ID 128b 128c )
  res.each do |e|
    csv << e
  end
end
