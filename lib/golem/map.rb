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
  end
end
