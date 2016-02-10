class Array
  def find_property(property, value)
    find { |e| e[property] && e[property] == value }
  end
end