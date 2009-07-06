class Mime::Type
  attr_reader :synonyms
  
  def all_types
    ([self.to_s] + synonyms).uniq
  end
end
