# encoding: UTF-8
require 'rubygems'
require 'nokogiri'
require 'rbconfig'
Dir[File.dirname(__FILE__) + '../*.rb'].each {|file| require file }

module Marcxml
  class Brno < Transformator
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    include Logging
    @refs = {}
    @ids = YAML.load_file("/home/dev/projects/import/Brno/ids.yml")
    @c240 = YAML.load_file("/home/dev/projects/import/Brno/240.yml")
    @c300 = YAML.load_file("/home/dev/projects/import/Brno/300.yml")
    @c650 = YAML.load_file("/home/dev/projects/import/Brno/650.yml")
    @collections = [916245, 916912, 935799, 962168, 1131893]
    @prints = [1405436, 1248647, 1258498, 1255530, 1255196, 1256064]
    class << self
      attr_accessor :refs, :ids, :c240, :c300, :c650, :collections, :prints
    end
    attr_accessor :node, :namespace, :methods
    def initialize(node, namespace={'marc' => "http://www.loc.gov/MARC21/slim"})
      @namespace = namespace
      @node = node
      @methods = [:change_leader, :add_composer, :insert_original_entry,
                  :fix_id, :fix_dots, :fix_incipit_no, :copy_650, :add_material_layer, 
                  :add_catalogue_agency, :insert_852, 
                  :change_240, :change_650, :change_300, :source_type,
                  :map]
    end

    # Change leader to muscat
    def change_leader
      leader=node.xpath("//marc:leader", NAMESPACE)[0]
      if leader
        leader.content=leader.content.sub(/^...../, "00000" )
      end
      controlfield = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first
      if Brno.collections.include?(controlfield.content.to_i)
        leader.content=leader.content.sub("00000ndm", "00000ndc")
      end
      if Brno.prints.include?(controlfield.content.to_i)
        leader.content=leader.content.sub("00000ncm", "00000ndm")
      end
    end

    def fix_id
      controlfield = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first
      if ((Integer(controlfield.content) rescue false) == false)
        controlfield.content = Brno.ids[controlfield.content]
      end
      datafield = node.xpath("//marc:datafield[@tag='773']/marc:subfield[@code='w']", NAMESPACE).first rescue nil
      if datafield
        datafield.content = Brno.ids[datafield.content]
      end
    end

    def change_240
      subfield240=node.xpath("//marc:datafield[@tag='240']/marc:subfield[@code='a']", NAMESPACE)
      subfield240.each do |sf| 
        if Brno.c240.keys.include?(sf.content)
          sf.content = Brno.c240[sf.content] 
        end
      end
    end

    def change_650
      subfield650=node.xpath("//marc:datafield[@tag='650']/marc:subfield[@code='a']", NAMESPACE)
      subfield650.each do |sf| 
        if Brno.c650.keys.include?(sf.content)
          sf.content = Brno.c650[sf.content] 
        end
      end
    end

    def change_300
      subfield300=node.xpath("//marc:datafield[@tag='300']/marc:subfield[@code='a']", NAMESPACE)
      subfield300.each do |sf|
        res = []
        new_content = sf.content.gsub(/[\(\)\[\]]/, "").gsub(" rkp", "").gsub(" rkp.", "")
        new_content.split(" ").each do |t|
          if Brno.c300.keys.include?(t)
            res << Brno.c300[t]
          else
            res << t
          end
        end
        sf.content = res.join(" ") 
      end
    end

    def source_type
      subfield500=node.xpath("//marc:datafield[@tag='500']/marc:subfield[@code='a']", NAMESPACE)
      subfield500.each do |sf|
        if sf.content =~ /Autograf/
          tag = Nokogiri::XML::Node.new "datafield", node
          tag['tag'] = '593'
          tag['ind1'] = ' '
          tag['ind2'] = ' '
          sfa = Nokogiri::XML::Node.new "subfield", node
          sfa['code'] = 'a'
          sfa.content = "Autograph manuscript"
          tag << sfa
          node.root << tag
          sf8 = Nokogiri::XML::Node.new "subfield", node
          sf8['code'] = '8'
          sf8.content = "01"
          tag << sf8 
          node.root << tag
          break
        else
          tag = Nokogiri::XML::Node.new "datafield", node
          tag['tag'] = '593'
          tag['ind1'] = ' '
          tag['ind2'] = ' '
          sfa = Nokogiri::XML::Node.new "subfield", node
          sfa['code'] = 'a'
          sfa.content = "Manuscript copy"
          tag << sfa
          sf8 = Nokogiri::XML::Node.new "subfield", node
          sf8['code'] = '8'
          sf8.content = "01"
          tag << sf8 
          node.root << tag
          break
        end
      end
    end

    def add_composer
      controlfield = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first
      return 0 if Brno.collections.include?(controlfield.content.to_i)
      if node.xpath("//marc:datafield[@tag='100']", NAMESPACE).empty?
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '100'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfa = Nokogiri::XML::Node.new "subfield", node
        sfa['code'] = 'a'
        sfa.content = "Anonymus"
        tag << sfa
        node.root << tag
      end
    end

    def add_material_layer
      layers = %w(260 300)
      layers.each do |l|
        material = node.xpath("//marc:datafield[@tag='#{l}']", NAMESPACE)
        material.each do |block|
          next unless block.xpath("marc:subfield[@code='8']", NAMESPACE).empty?
          sf8 = Nokogiri::XML::Node.new "subfield", node
          sf8['code'] = '8'
          sf8.content = "01"
          block << sf8
        end
      end
    end

    def insert_original_entry
      id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE)[0].content
      tag = Nokogiri::XML::Node.new "datafield", node
      tag['tag'] = '856'
      tag['ind1'] = ' '
      tag['ind2'] = ' '
      sfa = Nokogiri::XML::Node.new "subfield", node
      sfa['code'] = 'u'
      sfa.content = "https://vufind.mzk.cz/Record/MZK01-#{id}"
      tag << sfa
      sfz = Nokogiri::XML::Node.new "subfield", node
      sfz['code'] = 'z'
      sfz.content = "Original catalogue entry"
      tag << sfz
      node.root << tag
    end
    
    def add_catalogue_agency
      tag = Nokogiri::XML::Node.new "datafield", node
      tag['tag'] = '040'
      tag['ind1'] = ' '
      tag['ind2'] = ' '
      sfa = Nokogiri::XML::Node.new "subfield", node
      sfa['code'] = 'a'
      sfa.content = "CZ-Bu"
      tag << sfa
      sfc = Nokogiri::XML::Node.new "subfield", node
      sfc['code'] = 'c'
      sfc.content = "DE-633"
      tag << sfc
      node.root << tag
    end


    # Copy 650 to 240 if no 240 exists
    def copy_650
      et = node.xpath("//marc:datafield[@tag='240']", NAMESPACE)
      genre = node.xpath("//marc:datafield[@tag='650']/marc:subfield[@code='a']", NAMESPACE)
      if et.empty?
        new_et = genre.first.content.capitalize rescue "Pieces"
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '240'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfa = Nokogiri::XML::Node.new "subfield", node
        sfa['code'] = 'a'
        sfa.content = new_et.sub(/\s{1}\(.*$/, "").sub(/\s{1}\-.*$/, "")
        tag << sfa
        node.root << tag
      end
    end

    #insert siglum
    def insert_852
      siglum = node.xpath("//marc:datafield[@tag='852']", NAMESPACE)
      shelfmark = node.xpath("//marc:datafield[@tag='910']/marc:subfield[@code='b']", NAMESPACE)
      if siglum.empty?
        new_shelfmark = shelfmark.first.content rescue "[without shelfmark]"
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '852'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfa = Nokogiri::XML::Node.new "subfield", node
        sfa['code'] = 'a'
        sfa.content = "CZ-Bu"
        tag << sfa
        sfc = Nokogiri::XML::Node.new "subfield", node
        sfc['code'] = 'c'
        sfc.content = new_shelfmark
        tag << sfc
        node.root << tag
      end
 

    end

    # Records have dot or komma at end
    def fix_dots
      fields = %w(100$a 100$d 240$a 300$a $650a 710$a 700$a 700$d)
      fields.each do |field|
        tag, code = field.split("$")
        links = node.xpath("//marc:datafield[@tag='#{tag}']/marc:subfield[@code='#{code}']", NAMESPACE)
        links.each {|link| link.content = link.content.gsub(/[\.,:]$/, "")}
      end
    end

    def fix_incipit_no
      incipits = node.xpath("//marc:datafield[@tag='031']", NAMESPACE)
      incipits.each do |incipit|
        nos = %w(a b c)
        nos.each do |no|
          n = incipit.xpath("marc:subfield[@code='#{no}']", NAMESPACE).first rescue nil
          if n
            n.content = n.content.to_i.to_s
          end
        end
      end
    end


  end
end

