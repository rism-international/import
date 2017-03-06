puts "Clearing old joins..."
last = Person.where(:marc_source => nil).order(:created_at => :asc)
if !last.empty?
  adatum = last.first.created_at - 1.day
else
  adatum = Person.order(:created_at => :desc).limit(1).take.created_at + 1.minute
end
puts adatum
Person.where('created_at >= ?', adatum).delete_all
Institution.where('created_at >= ?', adatum).delete_all
Catalogue.where('created_at >= ?', adatum).delete_all
StandardTitle.where('created_at >= ?', adatum).delete_all
Place.where('created_at >= ?', adatum).delete_all
StandardTerm.where('created_at >= ?', adatum).delete_all
LiturgicalFeast.where('created_at >= ?', adatum).delete_all
Source.delete_all

jointables = [
  "truncate table sources_to_catalogues",
  "truncate table sources_to_institutions",
  "truncate table sources_to_liturgical_feasts",
  "truncate table sources_to_people",
  "truncate table sources_to_places",
  "truncate table sources_to_standard_terms",
  "truncate table sources_to_standard_titles",
]
jointables.each do |jt|
  ActiveRecord::Base.connection.execute(jt)
end
puts "Cleared old joins!"
