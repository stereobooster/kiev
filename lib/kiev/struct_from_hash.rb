module Kiev
  module StructFromHash
    def create(hash)
      new(*hash.values_at(*members))
    end
  end
end
