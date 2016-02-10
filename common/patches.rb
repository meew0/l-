class Array
  def find_property(property, value)
    find { |e| e[property.to_s] && e[property.to_s] == value }
  end
end