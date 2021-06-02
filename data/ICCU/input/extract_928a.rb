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

  s928_a = node.xpath("//marc:datafield[@tag='928']/marc:subfield[@code='a']", NAMESPACE).map{|f| f.content.strip}.join(";")

  if s928_a.size > 0
    s928_a.split(";").each do |abr|
      res << [rism_id, url, abr, fomu[abr]]
      puts "#{rism_id}, #{url}, #{abr}, #{fomu[abr]}"
    end
  end
  #unless fields.empty?
  #  res << [id, fields.map{|f| f.content}.join("; ")]
  #end
end

CSV.open("928a.csv", "w") do |csv|
  csv << %w(RISM_ID ID 928a )
  res.each do |e|
    csv << e
  end
end
