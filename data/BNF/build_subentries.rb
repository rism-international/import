#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'nokogiri'
require 'trollop'
require 'ruby-progressbar'
require 'rbconfig'
require 'zip'
require 'pry'
require 'colorize'

NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
SCHEMA_FILE="conf/MARC21slim.xsd"
#OPTIONS
opts = Trollop::options do
  version "RISM Marcxml 0.1 (2016.07)"
  banner <<-EOS
This utility program changes MARCXML nodes according to an YAML file. 
Overall required argument is -i [inputfile].

Usage:
   marcxml [-cio] [-aftmrsd] [--with-content --with-linked --with-disjunct --zip --with-limit]
where [options] are:
  EOS

  opt :infile, "Input-Filename", :type => :strings, :short => "-i"
  opt :outfile, "Output-Filename", :type => :string, :default => "out.xml", :short => '-o'
end

Dir['/home/dev/projects/marcxml-tools/lib/*.rb'].each do |file| 
  require file 
end

Trollop::die :infile, "must exist" if !opts[:infile]
Trollop::die :outfile, "must exist" if opts[:report]

if opts[:infile].size == 1
  source_file = opts[:infile].first
end

ofile=File.open(opts[:outfile], "w")

total = 10000

bar = ProgressBar.create(title: "Found", :format => "%c of %C Records parsed. -- %a | %B | %p%% %e".yellow, total: total, remainder_mark: '-', progress_mark: '#')

result = {}
max = 840020000
if source_file
  cnt = 1
  #Start reading stream
  xmlstream = Marcxml::Xmlstream.new(ofile)
  xmlstream.header unless (opts[:analyze] || opts[:report])
  xmlstream.each_record(source_file) do |record|
    isn = record.xpath('//marc:controlfield[@tag="001"]', NAMESPACE)[0].content rescue next
    oce = record.xpath('//marc:controlfield[@tag="003"]', NAMESPACE)[0].content rescue nil
    siglum = record.xpath('//marc:datafield[@tag="930"]', NAMESPACE)[0]
    author = record.xpath('//marc:datafield[@tag="700"]', NAMESPACE)[0]
    title = record.xpath('//marc:datafield[@tag="500"]', NAMESPACE)[0]
    genre = record.xpath('//marc:datafield[@tag="606"]', NAMESPACE)[0]
    impressum = record.xpath('//marc:datafield[@tag="210"]', NAMESPACE)[0]
    material = record.xpath('//marc:datafield[@tag="215"]', NAMESPACE)[0]
    autograph = record.xpath('//marc:datafield[@tag="205"]', NAMESPACE)[0]

    refs=record.xpath("//*[@code='9']", NAMESPACE)
    unless refs.empty?
      incipits = record.xpath('//marc:datafield[@tag="036"]', NAMESPACE)
      #if incipits.empty?
        lead = record.xpath('//marc:leader', NAMESPACE)[0]
        lead.content="00000ncc a2200000   4500"
      #end
      subs = Hash.new([])
      refs.each do |ref|
        subs[ref.content] += [ref.parent]
        ref.parent.remove
      end
      nodes = record.xpath("//marc:datafield", NAMESPACE).remove
      xmlstream.append(record, nodes)
      subs.each do |k,v|
        v.each do |t|
          if t["tag"] == "701"
            t["tag"] = "700"
          end
        end
        existent_datafields = v.map{|e| e.xpath("@tag").first.value}.flatten

        doc = Nokogiri::XML "<record></record>"
        leader = Nokogiri::XML::Node.new "leader", doc
        leader.content="00000ndd a2200000   4500"
        doc.root << leader

        id_field = Nokogiri::XML::Node.new "controlfield", doc
        id_field['tag'] = '001'
        id_field.content = max
        doc.root << id_field
        max += 1

        tag = Nokogiri::XML::Node.new "datafield", doc
        tag['tag'] = '773'
        tag['ind1'] = ' '
        tag['ind2'] = ' '
        sfa = Nokogiri::XML::Node.new "subfield", doc
        sfa['code'] = 'w'
        sfa.content = isn
        tag << sfa
        doc.root << tag
      
        doc.root << siglum if siglum
        if impressum && existent_datafields.include?("210")
          doc.root << impressum 
        end
        if material && existent_datafields.include?("215")
          doc.root << material
        end 
        
        unless existent_datafields.include?("700")
          if author
            doc.root << author
          else
            tag = Nokogiri::XML::Node.new "datafield", doc
            tag['tag'] = '700'
            tag['ind1'] = ' '
            tag['ind2'] = ' '
            sfa = Nokogiri::XML::Node.new "subfield", doc
            sfa['code'] = 'a'
            sfa.content = "Anonymus"
            tag << sfa
            doc.root << tag
          end
        end
        
        unless existent_datafields.include?("500")
          if title
            doc.root << title
          else
            tag = Nokogiri::XML::Node.new "datafield", doc
            tag['tag'] = '500'
            tag['ind1'] = ' '
            tag['ind2'] = ' '
            sfa = Nokogiri::XML::Node.new "subfield", doc
            sfa['code'] = 'a'
            sfa.content = "Pieces"
            tag << sfa
            doc.root << tag
          end
        end
  
        unless existent_datafields.include?("606")
          if genre
            doc.root << genre
          else
            tag = Nokogiri::XML::Node.new "datafield", doc
            tag['tag'] = '606'
            tag['ind1'] = ' '
            tag['ind2'] = ' '
            sfa = Nokogiri::XML::Node.new "subfield", doc
            sfa['code'] = 'a'
            sfa.content = "Pieces"
            tag << sfa
            doc.root << tag
          end
        end
 
        unless existent_datafields.include?("205")
          if autograph
            doc.root << autograph
          else
            tag = Nokogiri::XML::Node.new "datafield", doc
            tag['tag'] = '205'
            tag['ind1'] = ' '
            tag['ind2'] = ' '
            sfa = Nokogiri::XML::Node.new "subfield", doc
            sfa['code'] = 'a'
            sfa.content = "Manuscript copy"
            tag << sfa
            doc.root << tag
          end
        end
                
        if oce
          tag = Nokogiri::XML::Node.new "datafield", doc
          tag['tag'] = '856'
          tag['ind1'] = ' '
          tag['ind2'] = ' '
          sfu = Nokogiri::XML::Node.new "subfield", doc
          sfu['code'] = 'u'
          sfu.content = oce
          tag << sfu
          sfx = Nokogiri::XML::Node.new "subfield", doc
          sfx['code'] = 'x'
          sfx.content = "Other"
          tag << sfx
          sfz = Nokogiri::XML::Node.new "subfield", doc
          sfz['code'] = 'z'
          sfz.content = "Original catalogue entry"
          tag << sfz
          doc.root << tag
        end
        xmlstream.append(doc, v)
      end
    else
      nodes = record.xpath("//marc:datafield", NAMESPACE).remove
      xmlstream.append(record, nodes)
    end
    cnt += 1
    
    bar.increment
  end
  xmlstream.close
end 

if ofile
  ofile.write(Hash[result.sort].to_yaml)
  ofile.close
  puts "\nCompleted!".green
else
  puts source_file + " is not a file!".red
end
