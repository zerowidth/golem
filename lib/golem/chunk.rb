module Golem

  class Chunk

    FULL_CHUNK = 16 * 16 * 128

    attr_reader :x, :y, :z
    attr_reader :size_x, :size_y, :size_z

    def initialize(x, y, z, size_x, size_y, size_z, data)
      # sizes are raw from packet, so add 1
      @x, @y, @z = x, y, z
      @size_x, @size_y, @size_z = size_x + 1, size_y + 1, size_z + 1

      if data
        @data = data
      else
        @blocks = Array.new(@size_x * @size_y * @size_z) { :air }
      end
    end

    def full_chunk?
      blocks.size == FULL_CHUNK
    end

    def valid?
      blocks.all? {|b| b}
    end

    # for iterating over and sending updates
    def each_column
      (0...size_x).each do |x|
        (0...size_z).each do |z|
          offset = (x * size_z * size_y) + (z * size_y)
          yield x + self.x, self.y, z + self.z, blocks[offset...(offset + size_y)]
        end
      end
    end

    def update(x, y, z, data)
      x = x - self.x
      y = y - self.y
      z = z - self.z
      offset = (x * size_z * size_y) + (z * size_y) + y
      blocks[offset...(offset+data.size)] = data
    end

    # access using chunk-localized coords, x=0..15, y=0..127, z=0..15
    def local(x, y, z)
      blocks[(x * size_z * size_y) + (z * size_y) + y]
    end

    # access using map-absolute coords
    def [](x, y, z)
      # chunk is at -16, -16, then -3 maps to -3 -(-16) == 16 - 3 == 13
      local(x - self.x, y - self.y, z - self.z)
    end

    # assign using map-absolute coords
    def []=(x, y, z, type)
      blocks[(x - self.x) * size_z * size_y + y - self.y + (z - self.z) * size_y] = type
    end

    def find(type, absolute=true)
      found = []
      blocks.each.with_index do |b, i|
        if b == type
          x, y, z = [i / (size_x * size_y), i % size_y, i % (size_x*size_y) / size_y]
          if absolute
            found << [x + self.x, y + self.y, z + self.z]
          else
            found << [x, y, z]
          end
        end
      end
      found
    end

    protected

    def blocks
      return @blocks if @blocks
      @blocks = []
      data = Zlib::Inflate.inflate(@data)
      size = @size_x * @size_y * @size_z
      *block_types = data[0...size].unpack("c#{size}")
      block_types.each do |code|
        @blocks << BLOCKS[code]
      end
      @blocks
    end

  end
end
