#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'trollop'
require 'ruby-progressbar'
require 'rbconfig'
require 'zip'
require 'pry'
require 'colorize'
require 'open-uri'

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
total = 101

bar = ProgressBar.create(title: "Found", :format => "%c of %C Records parsed. -- %a | %B | %p%% %e".yellow, total: total, remainder_mark: '-', progress_mark: '#')

doc = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
    xml.collection('xmlns:zs' => "http://www.loc.gov/zing/srw/", 'xmlns:marc' => "http://www.loc.gov/MARC21/slim")
end

if source_file
  #Start reading stream
  xmlstream = Marcxml::Xmlstream.new(ofile)
  xmlstream.each_record(source_file) do |record|
    record.remove_namespaces!
    # To have only the people
    next unless record.xpath("//datafield[@tag='210']").empty?
    b_record = Nokogiri.XML('<record></record>')
    leader=record.xpath("//leader")
    isn=record.xpath("//controlfield[@tag='001']")
    b_record.root << leader.to_xml
    b_record.root << isn.to_xml

    iccu_id = isn.first.content.split("\\")[2] + isn.first.content.split("\\")[3]
    cluster = "https://viaf.org/viaf/search?query=cql.serverChoice+%3D+%22#{iccu_id}%22&recordSchema=info:srw/schema/1/marcxml-v1.1&maximumRecords=100&startRecord=1&httpAccept=text/xml"
    cluster_doc = Nokogiri::XML(open(cluster))
    viaf_id = cluster_doc.xpath("//mx:controlfield[@tag='001']", "mx" => "http://www.loc.gov/MARC21/slim").first.content rescue nil
    n024=Nokogiri.XML("<datafield tag='024' ind1='7' ind2=' '><subfield code='2'>ICCU</subfield><subfield code='a'>#{iccu_id}</subfield></datafield>")
    if viaf_id
      puts viaf_id
      viaf_node=Nokogiri.XML("<datafield tag='024' ind1='7' ind2=' '><subfield code='2'>VIAF</subfield><subfield code='a'>#{viaf_id.gsub("viaf", "")}</subfield></datafield>")
    end
    b_record.root << n024.root.to_xml
    b_record.root << viaf_node.root.to_xml if viaf_id
    life_date = record.xpath("//datafield[@tag='300']/subfield[@code='a']").first
    life_date["code"]="d" if life_date
    life_date.content = life_date.content.split(" //").first if life_date
    name=record.xpath("//datafield[@tag='200']").first
    if name
      sf_a = name.xpath("subfield[@code='a']")
      sf_b = name.xpath("subfield[@code='b']")
      sf_a.first.content += (sf_b.first.content rescue "")
      sf_b.remove
      name << life_date if life_date
      name["tag"]='100'
      b_record.root << name.to_xml
    end

    doc.doc.root << b_record.root.to_xml
    
    bar.increment
  end
end 

if ofile
  xml_out = Nokogiri::XML(doc.to_xml,&:noblanks)
  ofile.write(xml_out.to_s)
  ofile.close
  puts "\nCompleted!".green
else
  puts source_file + " is not a file!".red
end
