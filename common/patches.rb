class Array
  def find_property(property, value)
    find { |e| e.send(property) == value }
  end
end