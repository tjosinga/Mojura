module MojuraAPI

  # DbObjectTags is a mixin module for DbObject and adds votes support for an object.
  # :category: DbObject
  module DbObjectVotes

    def load_vote_fields
      yield :votes_average, Float,   :required => true,  :group => 'votes', :default => 0
      yield :votes_count,   Integer, :required => true,  :group => 'votes', :default => 0
    end


  end


end