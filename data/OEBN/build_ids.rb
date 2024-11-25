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
require 'csv'

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

total = 44000

bar = ProgressBar.create(title: "Found", :format => "%c of %C Records parsed. -- %a | %B | %p%% %e".yellow, total: total, remainder_mark: '-', progress_mark: '#')

result = {}
ids = []

dubl = {}

if source_file
  cnt = 600100000
  #Start reading stream
  xmlstream = Marcxml::Xmlstream.new(ofile)
  xmlstream.each_record(source_file) do |record|
    isn=record.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.content
    if dubl[isn]
      dubl[isn] += 1
    else
      dubl[isn] = 1
    end
    ids << isn
    result[isn]=cnt
    cnt += 1
    bar.increment
  end
end 

CSV.open("doubl.csv", "w") do |csv|
  dubl.each do |k,v|
    next if v == 1
    csv << [k, v]
  end
end

idfile=File.open("id.txt", "w")
idfile.write(ids.sort.join("\r"))
idfile.close

if ofile
  ofile.write(Hash[result.sort].to_yaml)
  ofile.close
  puts "\nCompleted!".green
else
  puts source_file + " is not a file!".red
end
