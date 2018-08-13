# encoding: UTF-8
require 'rubygems'
require 'nokogiri'
require 'rbconfig'
Dir[File.dirname(__FILE__) + '../*.rb'].each {|file| require file }

module Marcxml
  class Moravian < Transformator
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    include Logging
    @refs = {}
    @@id_reference = YAML.load_file("../import/Moravian/id_reference.yml")
    @@muscat_conf = MuscatMarcConfig.new(:Source).tags_with_subtags
    #@@start_id = 240000
    class << self
      attr_accessor :refs
    end
    attr_accessor :node, :namespace, :methods
    def initialize(node, namespace={'marc' => "http://www.loc.gov/MARC21/slim"})
      @namespace = namespace
      @node = node
      @methods = [:insert_original_entry, :fix_id, :fix_dots, :fix_leader, :add_material_layer, 
                  :join630, :move_language, :create_excerpts, :concat_245, :concat_555, 
                  :concat_382, :correct_siglum_ws, :remove_empty_773, :add_240_a, :clear_unused_fields,
                  :map]
    end

    # Records have string at beginning
    def fix_id
      controlfield = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first
      controlfield.content = @@id_reference[controlfield.content]
      #open('id_reference.yml', 'a') { |f|
      #  f.puts "#{controlfield.content}: #{@@start_id += 1}"
      #}
      links = node.xpath("//marc:datafield[@tag='773']/marc:subfield[@code='w']", NAMESPACE)
      links.each {|link| link.content = @@id_reference[link.content.gsub("(OCoLC)", "ocn")]}
    end

    def insert_original_entry
      id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE)[0].content
      tag = Nokogiri::XML::Node.new "datafield", node
      tag['tag'] = '856'
      tag['ind1'] = ' '
      tag['ind2'] = ' '
      sfu = Nokogiri::XML::Node.new "subfield", node
      sfu['code'] = 'u'
      sfu.content = "https://moravianmusic.on.worldcat.org/oclc/#{id[3..-1]}"
      tag << sfu
      sfz = Nokogiri::XML::Node.new "subfield", node
      sfz['code'] = 'z'
      sfz.content = "Original catalogue entry"
      tag << sfz

      node.root << tag
    end

    def fix_leader
      leader = node.xpath("//marc:leader", NAMESPACE).first
      if leader.content[5..7] == "cda"
        c = leader.content
        c[5..7] = "cdm"
        leader.content = c
      end
    end

    def move_language
      leader = node.xpath("//marc:controlfield[@tag='008']", NAMESPACE)[0].content
      lang_code = leader[35..37]
      if lang_code && lang_code != "zxx"
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '041'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfu = Nokogiri::XML::Node.new "subfield", node
        sfu['code'] = 'a'
        sfu.content = "#{lang_code}"
        tag << sfu
        node.root << tag
      end
    end

    def join630
      sf = node.xpath("//marc:datafield[@tag='630']", NAMESPACE)
      sf.each do |s|
        sf_a = s.xpath("marc:subfield[@code='a']", NAMESPACE)[0].content rescue ""
        sf_p = s.xpath("marc:subfield[@code='p']", NAMESPACE)[0].content rescue ""
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '500'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfu = Nokogiri::XML::Node.new "subfield", node
        sfu['code'] = 'a'
        sfu.content = "#{sf_a} #{sf_p}"
        tag << sfu
        node.root << tag
      end
    end

    def create_excerpts
      ex = node.xpath("//marc:datafield[@tag='240']/marc:subfield[@code='p']", NAMESPACE)
      unless ex.empty?
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '730'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfu = Nokogiri::XML::Node.new "subfield", node
        sfu['code'] = 'a'
        sfu.content = "#{ex.first.content}"
        tag << sfu
        node.root << tag
        ex.first.remove
        df = node.xpath("//marc:datafield[@tag='240']", NAMESPACE).first
        sf = df.xpath("marc:subfield[@code='k']", NAMESPACE).first
        if !sf
          sfk = Nokogiri::XML::Node.new "subfield", node
          sfk['code'] = 'k'
          sfk.content = "Excerpts"
          df << sfk
        end
      end
    end

    def concat_245
      codes = %w( b c f g h k n p s )
      txt = []
      ex = node.xpath("//marc:datafield[@tag='245']", NAMESPACE)
      codes.each do |code|
        sf = ex.xpath("marc:subfield[@code='#{code}']", NAMESPACE)
        sf.each do |e| txt << e.content end
        sf.remove
      end
      dip = node.xpath("//marc:datafield[@tag='245']/marc:subfield[@code='a']", NAMESPACE).first
      dip.content = "#{dip.content} #{txt.join(" ")}" if dip
    end

    def concat_555
      ex = node.xpath("//marc:datafield[@tag='555']", NAMESPACE)
      ex.each do |e|
        txt = []
        ex.xpath("marc:subfield[@code='a']", NAMESPACE).each do |e|
          txt << e.content
        end
        sfd = ex.xpath("marc:subfield[@code='d']", NAMESPACE)
        sfd.each do |e|
          txt << e.content
          sfd.remove
        end
        ex.xpath("marc:subfield[@code='a']", NAMESPACE).first.content = txt.join(" ")
      end
    end

    def concat_382
      txt = []
      ex = node.xpath("//marc:datafield[@tag='382']", NAMESPACE)
      ex.each do |df|
        df.xpath("marc:subfield[@code='a']", NAMESPACE).each do |sf|
          txt << sf.content
        end
        df.remove
      end
      unless txt.empty?
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '500'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfu = Nokogiri::XML::Node.new "subfield", node
        sfu['code'] = 'a'
        sfu.content = "Instrumentation: #{txt.join(", ")}"
        tag << sfu
        node.root << tag
      end
    end

    def correct_siglum_ws
      xvalue = "30002512"
      ex = node.xpath("//marc:datafield[@tag='852']", NAMESPACE)
      ex.each do |df|
        df.xpath("marc:subfield[@code='a']", NAMESPACE).each do |sf|
          if sf.content == "US-WS"
            sfu = Nokogiri::XML::Node.new "subfield", node
            sfu['code'] = 'x'
            sfu.content = xvalue
            df << sfu
          end
        end
      end
    end

    def remove_empty_773
      ex = node.xpath("//marc:datafield[@tag='773']", NAMESPACE)
      ex.each do |df|
        df.xpath("marc:subfield[@code='w']", NAMESPACE).each do |sf|
          if !sf || sf.content == ""
            ex.remove
          end
        end
      end
    end

    def add_240_a
      ex = node.xpath("//marc:datafield[@tag='240']", NAMESPACE)
      ex.each do |df|
        if df.xpath("marc:subfield[@code='a']", NAMESPACE).empty?
            sfu = Nokogiri::XML::Node.new "subfield", node
            sfu['code'] = 'a'
            sfu.content = "Pieces"
            df << sfu
        end
      end
    end


    def clear_unused_fields
      clear_unknown_muscat_fields(@@muscat_conf)
    end

  end
end

