module MojuraAPI

  # DbObjectOrderId is a mixin module for DbObject and adds sorting support for an object.
  # :category: DbObject
  module DbObjectOrderId
  
    def load_orderid_fields 
      yield :orderid,   Integer, :required => true,	:default => 99999
    end
    
  
  end
  
  
end