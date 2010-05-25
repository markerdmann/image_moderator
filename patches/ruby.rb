class Hash
  def to_simple_xml
    s = hash_to_xml_string(self)
    # add newline after the first parent tag
    s =~ /(<.+?>)/
    s.gsub!($1, $1 + "\n")
    # add some encoding info at the top
    s = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + s 
  end

private

  def hash_to_xml_string(h)
    s = ""
    h.each do |k,v|
      s += "<#{k}>"
      if v.class == Hash
        s += hash_to_xml_string(v)
      elsif v.class == Array
        v.each {|i|  s += hash_to_xml_string(i) }
      else
        s += v.to_s
      end
      s += "</#{k}>\n"
    end
    return s
  end
end