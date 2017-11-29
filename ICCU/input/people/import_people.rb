#This script compares a person in the import-file with the existing people pool of muscat. See README
ifile = "../input/people/iccu_people_import.xml"

# Use the marcimporter
marc_import = MarcImport.new(ifile, "Person")
marc_import.each_record(ifile) do |record|
  ref_person = nil
  viaf_id = nil
  iccu_id = nil
  #Stage 1: look for matching VIAF-id
  record.xpath("//datafield[@tag='024']").each do |df|
    if df.xpath("subfield[@code='2']").first.content == 'VIAF'
      viaf_id = df.xpath("subfield[@code='a']").first.content
    end
    if df.xpath("subfield[@code='2']").first.content == 'ICCU'
      iccu_id = df.xpath("subfield[@code='a']").first.content
    end
  end
  if viaf_id
    s= Sunspot.search(Person) do 
      adjust_solr_params do |params| 
        params[:q] = "024a_text:#{viaf_id}" 
      end
    end
    if !s.hits.empty?
      ref_id = s.hits.first.result.id
      ref_person = Person.find(ref_id)
      marc = ref_person.marc
      new_024 = MarcNode.new(Person, "024", "", "##")
      ip = marc.get_insert_position("024")
      new_024.add(MarcNode.new(Person, "2", "ICCU", nil))
      new_024.add(MarcNode.new(Person, "a", "#{iccu_id}", nil))
      marc.root.children.insert(ip, new_024)
      ref_person.save rescue puts "#{ref_person.full_name}"
      next
    end
  end

  unless ref_person
    #Stage 2: look for person with same full_name
    full_name = record.xpath("//datafield[@tag='100']/subfield[@code='a']").first.content rescue next
  # Uncomment if there is a need for improved matching with life_dates:
=begin
    life_date = record.xpath("//datafield[@tag='100']/subfield[@code='d']").first.content rescue ""
    birth_date = life_date.gsub(/\D/, "")[0..3]
    ref_person = Person.where(:full_name => full_name).where('life_dates like ?', "#{birth_date}%").take
=end
    ref_person = Person.where(:full_name => full_name).take
      binding.pry
    if ref_person
      marc = ref_person.marc
      new_024 = MarcNode.new(Person, "024", "", "##")
      ip = marc.get_insert_position("024")
      new_024.add(MarcNode.new(Person, "2", "ICCU", nil))
      new_024.add(MarcNode.new(Person, "a", "#{iccu_id}", nil))
      marc.root.children.insert(ip, new_024)
      ref_person.save rescue puts "Error saving person #{ref_person.full_name}"
      next
    end
  end

  record.add_namespace(nil, "http://www.loc.gov/MARC21/slim")
  xml = Nokogiri::XML(record)
  xml << record
  xslt  = Nokogiri::XSLT(File.read(Rails.root.join('housekeeping/import/', 'marcxml2marctxt_1.0.xsl')))
  marctext = CGI::unescapeHTML(xslt.apply_to(xml).to_s)
  puts marctext
  marc_import.create_record(marctext)
end

# Addon
# Viaf search with SRU
#http://iccu.rism.info/sru/people?operation=searchRetrieve&version=1.1&query=provider=viaf%20and%20provider_id=163710944&maximumRecords=1
#
