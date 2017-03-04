sx = Source.where.not(:source_id => nil)
sx.each do |s|
  s.update_77x rescue next
end
