require 'nokogiri'
require 'csv'
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

res = []
Marc.new.each_record("input.xml") do |node|
  id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.content

  fields = node.xpath("//marc:datafield[@tag='929']/marc:subfield[@code='h']", NAMESPACE)
  unless fields.empty?
    res << [id, fields.map{|f| f.content}.join("; ")]
  end
end

CSV.open("929.csv", "w") do |csv|
  csv << %w(ID FIELD)
  res.each do |e|
    csv << e
  end
end
