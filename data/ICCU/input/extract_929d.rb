require 'nokogiri'
require 'csv'
require 'yaml'
require 'pry'
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

fomu = {}
CSV.read("./fomu.csv", headers: true).each do |e|
  fomu[e[0]]=e[1]
end

res = []
Marc.new.each_record("input.xml") do |node|
  id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.content
  url = node.xpath("//marc:controlfield[@tag='003']", NAMESPACE).first.content
  rism_id = ids[id]

  s929_d = node.xpath("//marc:datafield[@tag='929']/marc:subfield[@code='d']", NAMESPACE).map{|f| f.content.strip}.join(";")

  if s929_d.size > 0
    s929_d.split(";").each do |abr|
      res << [rism_id, url, abr]
      puts "#{rism_id}, #{url}, #{abr}"
    end
  end
  #unless fields.empty?
  #  res << [id, fields.map{|f| f.content}.join("; ")]
  #end
end

CSV.open("929d.csv", "w") do |csv|
  csv << %w(RISM_ID ID 929d )
  res.each do |e|
    csv << e
  end
end
