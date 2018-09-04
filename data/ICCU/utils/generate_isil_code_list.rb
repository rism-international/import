class ICCULibrary
  attr_accessor :isil, :rism
  def initialize(isil=nil, rism=nil)
    @isil = isil
    @rism = rism
  end

  def from_json(json_object)
    rism = json_object["codici-identificativi"]["rism"]
    isil = (json_object["codici-identificativi"]["isil"]).gsub("IT-", "")
    self.rism = rism
    self.isil = isil
  end

  def self.read_json_file
    JSON.parse(File.read('./utils/biblioteche.json'))
  end

  def self.build_objects
    arry = []
    ICCULibrary.read_json_file["biblioteche"].each do |library|
      iccu_library = ICCULibrary.new
      iccu_library.from_json(library)
      arry << iccu_library
    end
    return arry
  end

  def self.export_yaml
    res = {}
    ICCULibrary.build_objects.each do |obj|
      res[obj.isil] = obj.rism
    end
    File.write("./utils/isil_codes.yml", res.to_yaml)
  end
end

class RISMLibrary
  def initialize
  end

  def to_yaml
  end
end


class ICCUtoRISMConverter
  def initialize
  end

  def convert
    #iccu to rism
  end
end





=begin
puts File.absolute_path('unimarc_sources_20171206.xml')
f = File.new('./testfile', "w")
f.syswrite("Hello world\n")
f.close()
puts "done"

f = File.open("testfile", "r")
=end

