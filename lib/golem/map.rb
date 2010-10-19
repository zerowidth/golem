module Golem
  class Map
    def initialize
      @chunks = {}
    end

    def chunk(x, z)
      @chunks[x / 16] && @chunks[x / 16][z / 16]
    end

    def [](x, y, z)
      c = self.chunk(x, z)
      c && c[x, y, z]
    end

    def []=(x, y, z, type)
      c = self.chunk(x, z)
      c && c[x, y, z] = type
    end

    # add a chunk to the map
    def add(chunk)
      @chunks[chunk.x / 16] ||= {}
      @chunks[chunk.x / 16][chunk.z / 16] = chunk
    end

    # drop a chunk from the map
    def drop(x, z)
      @chunks[x/16] && @chunks[x/16].delete(z/16)
    end

    def available(x, y, z)
      Location.new(self).available(x, y, z)
    end
  end

  class Location
    NORTH = [-1, 0, 0]
    EAST  = [0, 0, -1]
    SOUTH = [1, 0, 0]
    WEST  = [0, 0, 1]
    UP    = [0, 1, 0]

    attr_reader :map

    def initialize(map)
      @map = map
    end

    def available(x, y, z)
      pos = [x, y, z]
      list = []
      standing_on = map[x, y, z]

      # look in ordinal directions:
      [NORTH, EAST, SOUTH, WEST].map do |transform|
        test = combine(pos, transform)
        if pass?(*test) && pass?(*(combine(test, UP)))
          list << test
        end
      end

      list
    end

    def pass?(x, y, z)
      block = map[x, y, z]
      # don't pathfind into the unknown!
      !block.nil? && !SOLID.include?(map[x, y, z])
    end

    def combine(start, delta)
      start.zip(delta).map { |operands| operands.inject(0) { |m, v| m + v } }
    end

  end
end
