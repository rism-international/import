# encoding: UTF-8
require 'rubygems'
require 'nokogiri'
require 'rbconfig'
Dir[File.dirname(__FILE__) + '../*.rb'].each {|file| require file }

module Marcxml
  class Fitz < Transformator
    NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
    include Logging
    @refs = {}
    @@without_siglum = {}
    puts Dir.pwd
    HOLDINGS = Nokogiri::XML(File.open("./output/holdings.xml"))
    SORTING = YAML.load_file("./sorting.yml")
    COLL = YAML.load_file("./coll.yml")
    EXISTENT = YAML.load_file("./all_ids.yml")
    #EXISTENT = Nokogiri::XML(File.open("./input/034-fitz-test.xml"))
    #SORTING = Nokogiri::XML(File.open("./input/034-fitz-test.xml"))
    #@@ids = {}
    #@@isil_codes = YAML.load_file("utils/isil_codes.yml")
    @@ids = YAML.load_file("./ids.yml")
    #@@relator_codes = YAML.load_file("utils/unimarc_relator_codes.yml")
    class << self
      attr_accessor :refs, :ids, :relator_codes, :isil_codes, :without_siglum
    end
    attr_accessor :node, :namespace, :methods
    def initialize(node, namespace={'marc' => "http://www.loc.gov/MARC21/slim"})
      @namespace = namespace
      @node = node
      @methods = [# :build_numbers, 
                  :map, :get_852, :get_773, :get_774, :fix_ids, :collection_leader, :add_material_layer,
                  #:build_all_ids,
                  #:build_coll,
                  #:build_numbers,
                  #:build_sorting,
                  #:fix_852, :remove_controlfields, :move_linking 
                  #:replace_rism_siglum, :insert_773_ref, :insert_774_ref, :collection_leader, :fix_id, :add_original_entry, 
                  #:concat_personal_name, :remove_whitespace_from_incipit, :change_leader, :change_relator_codes, :add_material_layer,
                  #:add_anonymus, :update_title, :move_650_to_comments
      ]
    end

    def build_all_ids
      res = []  
      ids = EXISTENT.xpath(".//marc:controlfield[@tag='001']", NAMESPACE)
      ids.each do |id|
        res << id.content 
      end
      binding.pry
      ofile=File.open("all_ids.yml", "w")
      if ofile
        ofile.write(res.to_yaml)
        ofile.close
      end
      exit
    end

    def get_coll(id)
      res = []
      shelf = COLL[id]
      coll = COLL.select{|key, hash| hash==shelf }
      coll.each do |k,v|
        res << {k => SORTING[k]}
      end
      return res.sort {|a,b| a.values.to_s <=> b.values.to_s}# rescue binding.pry
    end

    def get_main_entry(id)
      m = get_coll(id)
      if !m || m.empty? || m.size <= 2
        return nil
      else
        return m.first.keys.first
      end
    end


    def add_material_layer
      layers = %w(260 300 593)
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

    def collection_leader
        refs = node.xpath("//marc:datafield[@tag='774']", NAMESPACE)
        if refs.empty?
          leader=node.xpath("//marc:leader", NAMESPACE)[0]
          leader.content="00000ndm a2200000 u 4500"
        else
          leader=node.xpath("//marc:leader", NAMESPACE)[0]
          leader.content="00000ndc a2200000   4500"
        end
    end

    def fix_ids
      id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first
      binding.pry if id =~ /5084/
      old_id = id.text
      id.content = @@ids[old_id]
    end

    def get_774
      #res = {}
      id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.text
      coll = get_coll(id)
      main_entry = get_main_entry(id)
      
      #parent = HOLDINGS.root.xpath(".//marc:controlfield[@tag='001'][text()='#{id}']/..", NAMESPACE)
      #ref_ids = parent.xpath(".//marc:controlfield[@tag='004']", NAMESPACE)
      #ref_ids.each do |r|
      #  res[r.content] = SORTING[r.content]
      #end
      #binding.pry if id =~ /421207/
      return unless SORTING[id]
      return if !EXISTENT.include?(id)
      #binding.pry if id =~ /66938/
      if main_entry == id && coll.size > 1
        coll.each do |e|
          next if !EXISTENT.include?(e.keys.first)
          next if e.keys.first == id
          tag = Nokogiri::XML::Node.new "datafield", node
          tag['tag'] = '774'
          tag['ind1'] = '1'
          tag['ind2'] = ' '
          sfw = Nokogiri::XML::Node.new "subfield", node
          sfw['code'] = 'w'
          sfw.content = @@ids[e.keys.first]
          tag << sfw
          node.root << tag
        end
      end
    end

    def build_coll
      res = []
      records = HOLDINGS.root.xpath(".//marc:record", NAMESPACE)
      records.each do |record|
        ids = record.xpath(".//marc:controlfield", NAMESPACE)
        ids.each do |id|
          shelf = record.xpath(".//marc:datafield[@tag='852']/marc:subfield[@code='c']", NAMESPACE).first.content rescue nil
          if shelf
            res << {id.content => shelf}
          end
        end
        binding.pry
      end
      ofile=File.open("coll.yml", "w")
      if ofile
        ofile.write(res.to_yaml)
        ofile.close
      end
      exit
    end


    def build_sorting
      res = []
      records = SORTING.root.xpath(".//marc:record", NAMESPACE)
      records.each do |record|
        id = record.xpath(".//marc:controlfield[@tag='001']", NAMESPACE).first.content
        page = record.xpath(".//marc:datafield[@tag='830']/marc:subfield[@code='v']", NAMESPACE).first.content rescue nil
        if page
          res << {id => page}
        end
      end
      ofile=File.open("sorting.yml", "w")
      if ofile
        ofile.write(res.to_yaml)
        ofile.close
      end
      exit
    end



    def build_numbers
      rism_start = 806700000
      res = []
      dict = {}
      nodes = HOLDINGS.root.xpath(".//marc:controlfield[@tag='001' or @tag='004']", NAMESPACE)
      nodes.each do |e| 
        res << e.text
      end
      res.sort!
      res.each do |e|
        dict[e] = (rism_start += 1).to_s
      end
      ofile=File.open("ids.yml", "w")
      if ofile
        ofile.write(Hash[dict.sort].to_yaml)
        ofile.close
      end
      exit
    end

    def get_852
      id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.text
      parent = HOLDINGS.root.xpath(".//marc:controlfield[@tag='001' or @tag='004'][text()='#{id}']/..", NAMESPACE)
      s = parent.xpath(".//marc:datafield[@tag='852']", NAMESPACE)
      sf_a = s.xpath(".//marc:subfield[@code='a']", NAMESPACE).first.content
      sf_b = s.xpath(".//marc:subfield[@code='b']", NAMESPACE).first.content
      sf_c = s.xpath(".//marc:subfield[@code='c']", NAMESPACE).first.content
      tag = Nokogiri::XML::Node.new "datafield", node
      tag['tag'] = '852'
      tag['ind1'] = '1'
      tag['ind2'] = ' '
      sfa = Nokogiri::XML::Node.new "subfield", node
      sfa['code'] = 'a'
      sfa.content = sf_a
      tag << sfa
      sfb = Nokogiri::XML::Node.new "subfield", node
      sfb['code'] = 'b'
      sfb.content = sf_b
      tag << sfb
      sfc = Nokogiri::XML::Node.new "subfield", node
      sfc['code'] = 'c'
      sfc.content = sf_c
      tag << sfc
      node.root << tag
    end    
    
    def get_773
      id = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.text
      parent = get_main_entry(id)
      return if id == parent || !parent
      return unless SORTING[id]
      #parent = HOLDINGS.root.xpath(".//marc:controlfield[@tag='004'][text()='#{id}']/..", NAMESPACE)
      if parent
        #collection_id = parent.xpath(".//marc:controlfield[@tag='001']", NAMESPACE).first.text
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '773'
        tag['ind1'] = '1'
        tag['ind2'] = ' '
        sfw = Nokogiri::XML::Node.new "subfield", node
        sfw['code'] = 'w'
        sfw.content = @@ids[parent]
        tag << sfw
        node.root << tag
      end
    end



    def remove_controlfields
      node.xpath("//marc:leader", NAMESPACE).first.remove rescue nil
      node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.remove rescue nil
      node.xpath("//marc:controlfield[@tag='005']", NAMESPACE).first.remove rescue nil
      node.xpath("//marc:controlfield[@tag='008']", NAMESPACE).first.remove rescue nil
    end

    def move_linking
      linking = node.xpath("//marc:controlfield[@tag='004']", NAMESPACE).first
      linking["tag"] = "001"
      #node.xpath("//marc:controlfield[@tag='004']", NAMESPACE).each do |e| e.remove rescue nil end
    end

    def fix_852
      tag=node.xpath("//marc:datafield[@tag='852']", NAMESPACE).first
      sfa = Nokogiri::XML::Node.new "subfield", node
      sfa['code'] = 'a'
      sfa.content = "GB-Cfm"
      tag << sfa
      tag.children.sort_by{ |node|
        node.attr("code")
      }.each{ |node|
        tag.add_child(node)
      }
    end



    def update_title
      datafields=node.xpath("//marc:datafield[@tag='240']", NAMESPACE)
      if datafields.empty?
        insert_datafield_with_subfield({tag: '240', code: 'a', content: 'Pieces'})
      end
      datafields=node.xpath("//marc:datafield[@tag='245']", NAMESPACE)
      if datafields.empty?
        insert_datafield_with_subfield({tag: '245', code: 'a', content: "[without title]"})
      end
    end

    def add_anonymus
      leader=node.xpath("//marc:leader", NAMESPACE)[0]
      unless leader.content[7] == "c"
        composer=node.xpath("//marc:datafield[@tag='100']", NAMESPACE)
        if composer.empty?
          tag = Nokogiri::XML::Node.new "datafield", node
          tag['tag'] = '100'
          tag['ind1'] = '1'
          tag['ind2'] = ' '
          sfu = Nokogiri::XML::Node.new "subfield", node
          sfu['code'] = 'a'
          sfu.content = "Anonymus"
          tag << sfu
          sfz = Nokogiri::XML::Node.new "subfield", node
          sfz['code'] = '0'
          sfz.content = "30004985"
          tag << sfz
          node.root << tag
        end
      end
    end

    def move_650_to_comments
      subfields=node.xpath("//marc:datafield[@tag='650']/marc:subfield[@code='a']", NAMESPACE)
      subfields.each do |sf|
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '500'
        tag['ind1'] = '1'
        tag['ind2'] = ' '
        sfu = Nokogiri::XML::Node.new "subfield", node
        sfu['code'] = 'a'
        sfu.content = "Subject heading: #{sf.content}"
        tag << sfu
        node.root << tag
        sf.parent.remove 
      end

    end

    def replace_rism_siglum
      subfields=node.xpath("//marc:datafield[@tag='852']/marc:subfield[@code='a']", NAMESPACE)
      subfields.each do |sf|
        if @@isil_codes[sf.content]
          sf.content = @@isil_codes[sf.content]      
        else
          unless @@without_siglum[sf.content]
            @@without_siglum[sf.content] = 1
          else
            @@without_siglum[sf.content] += 1
          end
          #File.write('output/without_siglum.yml', @@without_siglum.to_yaml)
        end
      end

    end

    def change_relator_codes
      px = node.xpath("//marc:subfield[@code='4']", NAMESPACE)
      px.each do |p|
        p.content = @@relator_codes[p.content]
      end
    end

    def fix_id
      controlfield = node.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first
      if ((Integer(controlfield.content) rescue false) == false)
        controlfield.content = Iccu.ids[controlfield.content]
      end
      #TODO find linking field
      subfields = node.xpath("//marc:datafield[@tag='773' or @tag='774']/marc:subfield[@code='w']", NAMESPACE)
      subfields.each do |subfield|
        if subfield.content.start_with?("001")
          collection_id_s = subfield.content[3..-1]
          unless Iccu.ids[collection_id_s]
            subfield.parent.remove
          else
            collection_id = Iccu.ids[collection_id_s]
          end
          subfield.content = collection_id
        else
          subfield.parent.remove
        end
      end
      #links = node.xpath("//marc:datafield[@tag='773']/marc:subfield[@code='w']", NAMESPACE)
      #links.each {|link| link.content = link.content.gsub("(OCoLC)", "1")}
    end

    def remove_whitespace_from_incipit
      incipits = node.xpath("//marc:datafield[@tag='031']", NAMESPACE)
      incipits.each do |incipit|
        sfx = incipit.xpath("marc:subfield", NAMESPACE) rescue nil
        sfx.each do |sf|
          if sf && sf.content
            sf.content = sf.content.strip
          end
        end
      end
    end


    def fix_incipit_zeros
      codes = %w(a b c)
      incipits = node.xpath("//marc:datafield[@tag='031']", NAMESPACE)
      incipits.each do |incipit|
        codes.each do |code|
          sf = incipit.xpath("marc:subfield[@code='#{code}']", NAMESPACE).first rescue nil
          if sf && sf.content
            sf.content = sf.content.sub(/^0/, "")
          end
        end
      end

    end

    def add_original_entry
      oce = node.xpath("//marc:controlfield[@tag='003']", NAMESPACE).first rescue nil
      if oce
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '856'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfu = Nokogiri::XML::Node.new "subfield", node
        sfu['code'] = 'u'
        sfu.content = oce.content rescue ""
        tag << sfu
        sfz = Nokogiri::XML::Node.new "subfield", node
        sfz['code'] = 'z'
        sfz.content = "Original catalogue entry"
        tag << sfz
        node.root << tag
      end
    end

    def change_009
      cfield = node.xpath("//marc:controlfield[@tag='009']", NAMESPACE).empty? ? nil : node.xpath("//marc:controlfield[@tag='009']", NAMESPACE)
      return 0 unless cfield
      local_id = cfield.first.content
      insert_datafield_with_subfield({tag: "035", code: "a", content: local_id})
      cfield.remove
    end

    def insert_773_ref
      refs = %w(461 463)
      refs.each do |e|
        ref = node.xpath("//marc:datafield[@tag='#{e}']", NAMESPACE)
        next if ref.empty?
        ref.each do |r|
          local_ref = r.xpath("marc:subfield[@code='1']", NAMESPACE).first
          tag = Nokogiri::XML::Node.new "datafield", node
          tag['tag'] = '773'
          tag['ind1'] = ' '
          tag['ind2'] = ' '
          sfw = Nokogiri::XML::Node.new "subfield", node
          sfw['code'] = 'w'
          sfw.content = local_ref.content
          tag << sfw
          node.root << tag
          ref.remove
        end
      end
    end

    def insert_774_ref
      ref = node.xpath("//marc:datafield[@tag='464']", NAMESPACE)
      return if ref.empty?
      ref.each do |r|
        local_ref = r.xpath("marc:subfield[@code='1']", NAMESPACE).first
        tag = Nokogiri::XML::Node.new "datafield", node
        tag['tag'] = '774'
        tag['ind1'] = '1'
        tag['ind2'] = '8'
        sfw = Nokogiri::XML::Node.new "subfield", node
        sfw['code'] = 'w'
        sfw.content = local_ref.content
        tag << sfw
        node.root << tag
      end
    end


    def check_material
      result = Hash.new
      subfield=node.xpath("//marc:datafield[@tag='100']/marc:subfield[@code='a']", NAMESPACE)
      if subfield.text=='Collection' || subfield.empty?
        result[:level] = "c"
      else
        result[:level] = "m"
      end
      subfield=node.xpath("//marc:datafield[@tag='762']", NAMESPACE)
      unless subfield.empty?
        result[:level] = "c"
      end

      subfield=node.xpath("//marc:datafield[@tag='773']", NAMESPACE)
      unless subfield.empty?
        result[:level] = "d"
      end

      subfields=node.xpath("//marc:datafield[@tag='593']/marc:subfield[@code='a']", NAMESPACE)
      material = []
      subfields.each do |sf|
        if (sf.text =~ /Ms/) || (sf.text =~ /autog/)
          material << :manuscript
        elsif sf.text =~ /print/
          material << :print
        else
          material << :other
        end
      end
      case
      when material.include?(:manuscript) && material.include?(:print)
        result[:type] = "p"
      when material.include?(:manuscript) && !material.include?(:print)
        result[:type] = "d"
      else
        result[:type] = "c"
      end
      return result
    end

    def change_leader
      leader=node.xpath("//marc:leader", NAMESPACE)[0]
      code = leader.content[5..7]
      if code == 'nda'
        leader.content="00000ndd a2200000   4500"
      end
    end


    def change_attribution
      subfield100=node.xpath("//marc:datafield[@tag='100']/marc:subfield[@code='j']", NAMESPACE)
      subfield700=node.xpath("//marc:datafield[@tag='700']/marc:subfield[@code='j']", NAMESPACE)
      subfield710=node.xpath("//marc:datafield[@tag='710']/marc:subfield[@code='g']", NAMESPACE)
      subfield100.each { |sf| sf.content = convert_attribution(sf.content) }
      subfield700.each { |sf| sf.content = convert_attribution(sf.content) }
      subfield710.each { |sf| sf.content = convert_attribution(sf.content) }
    end

    def convert_attribution(str)
      case str
      when "e"
        return "Ascertained"
      when "z"
        return "Doubtful"
      when "g"
        return "Verified"
      when "f"
        return "Misattributed"
      when "l"
        return "Alleged"
      when "m"
        return "Conjectural"
      else
        return str
      end
    end

    def prefix_performance
      subfield=node.xpath("//marc:datafield[@tag='518']/marc:subfield[@code='a']", NAMESPACE)
      subfield.each { |sf| sf.content = "Performance date: #{sf.content}" }
    end

    def split_730
      datafields = node.xpath("//marc:datafield[@tag='730']", NAMESPACE)
      return 0 if datafields.empty?
      datafields.each do |datafield|
        hs = datafield.xpath("marc:subfield[@code='a']", NAMESPACE)
        title = split_hs(hs.map(&:text).join(""))
        hs.each { |sf| sf.content = title[:hs] }
        sfk = Nokogiri::XML::Node.new "subfield", node
        sfk['code'] = 'g'
        sfk.content = "RISM"
        datafield << sfk
        if title[:sub]
          sfk = Nokogiri::XML::Node.new "subfield", node
          sfk['code'] = 'k'
          sfk.content = title[:sub]
          datafield << sfk
        end
        if title[:arr]
          sfk = Nokogiri::XML::Node.new "subfield", node
          sfk['code'] = 'o'
          sfk.content = title[:arr]
          datafield << sfk
        end
      end
    end

    def change_243
      tags=node.xpath("//marc:datafield[@tag='243']", NAMESPACE)
      tags.each do |sf|
        sfa = Nokogiri::XML::Node.new "subfield", node
        sfa['code'] = 'g'
        sfa.content = "RAK"
        sf << sfa
        tags.attr("tag", "730")
      end
    end

    def remove_pipe
      subfields=node.xpath("//marc:datafield[@tag='240']/marc:subfield[@code='a']", NAMESPACE)
      subfields.each do |sf|
        if sf.content.include?("|")
          sf.content = sf.content.gsub("|", "")
        end
      end

    end


    def change_593_abbreviation
      subfield=node.xpath("//marc:datafield[@tag='593']/marc:subfield[@code='a']", NAMESPACE)
      subfield.each { |sf| sf.content = convert_593_abbreviation(sf.content) }
    end

    def convert_593_abbreviation(str)
      case str
      when "mw"
        return "Other"
      when "mt"
        return "Treatise, handwritten"
      when "ml"
        return "Libretto, handwritten"
      when "mu"
        return "Treatise, printed"
      when "mv"
        return "unknown"
      when "autograph"
        return "Autograph manuscript"
      when "partly autograph"
        return "Partial autograph"
      when "manuscript"
        return "Manuscript copy"
      when "probably autograph"
        return "Possible autograph manuscript"
      when "mk"
        return "Libretto, printed"
      when "mz"
        return "Music periodical"
      when "4"
        return "Other"
      else
        return str
      end
    end
    
    def convert_siglum(str)
      case str
      when "FR-751131010" 
        return "F-Pnla"
      when "FR-751021003" 
        return "F-Pn"
      when "FR-751131011" 
        return "F-Pnlr"
      when "FR-751041002" 
        return "F-Pa"
      when "FR-751091001" 
        return "F-Po"
      when "FR-751041001" 
        return "F-Pnas"
      when "FR-751041006" 
        return "F-Pnm"
      end
    end




















    

  end
end

