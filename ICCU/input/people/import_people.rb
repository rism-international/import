#http://iccu.rism.info/sru/people?operation=searchRetrieve&version=1.1&query=provider=viaf%20and%20provider_id=163710944&maximumRecords=1
#
ifile = "../input/people/test_import.xml"
# Use the marcimporter
marc_import = MarcImport.new(ifile, "Person")
marc_import.each_record(ifile) do |record|
  ref_person = nil
  viaf_id = nil
  #Stage 1: look for VIAF-id
  record.xpath("//datafield[@tag='024']").each do |df|
    if df.xpath("subfield[@code='2']").first.content == 'VIAF'
      viaf_id = df.xpath("subfield[@code='a']").first.content
    end
  end
  if viaf_id
    s= Sunspot.search(Person) do 
      adjust_solr_params do |params| 
        params[:q] = "024a_text:#{viaf_id}" 
      end
    end
    if !s.hits.empty?
      ref_person = s.hits.first.result
    end
  end
  binding.pry if ref_person 
  unless ref_person
    #Stage 2: look for person with same full_name and life_dates
    full_name = record.xpath("//datafield[@tag='100']/subfield[@code='a']").first.content rescue ""
    life_date = record.xpath("//datafield[@tag='100']/subfield[@code='d']").first.content rescue ""
    ref_person = Person.where(:full_name => full_name).take
  end
  record.add_namespace(nil, "http://www.loc.gov/MARC21/slim")
  xml = Nokogiri::XML(record)
  xml << record


  unless ref_person
    # Use external XSLT 1.0 file for converting to MARC21 text
    xslt  = Nokogiri::XSLT(File.read(Rails.root.join('housekeeping/import/', 'marcxml2marctxt_1.0.xsl')))
    marctext = CGI::unescapeHTML(xslt.apply_to(xml).to_s)
    puts marctext

  end
end

