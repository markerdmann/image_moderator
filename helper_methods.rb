module HelperMethods

  def authenticated?(key)
    
    # uses account.json for extra speed. if the key is valid
    # it returns a content-type error, but if the key is not
    # valid it returns a 401.
    response = HTTParty.get("https://www.crowdflower.com/account.json?key=#{key}")
    return true if response.code != 401
  
  end

end