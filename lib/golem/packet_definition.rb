module Golem
  module PacketDefinition

    def string(name)
      fields[name] = Field::String
    end

    def int(name)
      fields[name] = Field::Integer
    end

    attr_accessor :description

    def respond(&blk)
      define_method :respond, &blk
    end

  end
end
