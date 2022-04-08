# encoding: UTF-8
require 'rubygems'
require 'nokogiri'
require 'rbconfig'

Dir[File.dirname(__FILE__) + '/../bin/*.rb'].each {|file| puts file; require file }

module Marcxml
  class OENB < Transformator
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    include Logging
    
    #@relator_codes = YAML.load_file("/home/dev/projects/marcxml-tools/lib/unimarc_relator_codes.yml")
    class << self
      attr_accessor :refs, :ids, :relator_codes, :keys, :genres, :scoring
    end
    attr_accessor :node, :namespace, :methods
    def initialize(node, namespace={'marc' => "http://www.loc.gov/MARC21/slim"})
      @namespace = namespace
      @node = node
      @methods = [:map, :fix_id]
    end

    
    def fix_id
      controlfield = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first
      puts controlfield.content
      if ((Integer(controlfield.content) rescue false) == false)
        controlfield.content = BNF.ids[controlfield.content]
      end
      datafield = node.xpath("//marc:datafield[@tag='773']/marc:subfield[@code='w']", NAMESPACE).first rescue "1111"
      if datafield
        datafield.content = BNF.ids[datafield.content]
      end
      #links = node.xpath("//marc:datafield[@tag='773']/marc:subfield[@code='w']", NAMESPACE)
      #links.each {|link| link.content = link.content.gsub("(OCoLC)", "1")}
    end

    def change_leader
      leader=node.xpath("//marc:leader", NAMESPACE)[0]
      result=check_material
      code = "n#{result}"
      raise "Leader code #{code} false" unless code.size == 3
      if leader
        leader.content="00000#{code} a2200000   4500"
      else
        leader = Nokogiri::XML::Node.new "leader", node
        leader.content="00000#{code} a2200000   4500"
        node.root.children.first.add_previous_sibling(leader)
      end
      leader
    end

    def check_material
      "HUHU"
    end

   

  end
end

