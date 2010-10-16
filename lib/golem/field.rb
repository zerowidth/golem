module Golem
  module Field
    class Base
      attr_reader :value
      def initialize(value=nil)
        @value = value
      end

      # sets the value based on type and returns the remaining data
      def parse(data)
        data
      end

      # encode the value appropriately, returns a string
      def encode
        ""
      end

      protected

      def consume(data, pattern)
        results = data.unpack(pattern + "a*")
        raise IncompletePacket if results.any? {|r| r.nil?}
        results
      end
    end

    class String < Base
      def parse(data)
        size, data = consume data, "n"
        *bytes, data = consume data, "C#{size}"
        value = bytes.map { |b| b.chr }.join("")
        [value, data]
      end

      def encode
        [value.size, value].pack("na*")
      end
    end

    class Integer < Base
      def parse(data)
        value, data = consume data, "N"
        value = value & 0x40000000 > 0 ? -((value ^ 0xFFFFFFFF) & 0x7FFFFFFF) - 1 : value
        [value, data]
      end

      def encode
        [value].pack("N")
      end
    end

    class Long < Base
      def parse(data)
        big, little, remainder = consume data, "NN"
        [(big << 32) + little, remainder]
      end

      def encode
        big = value >> 32
        little = value - (value >> 32 << 32)
        [big, little].pack("NN")
      end
    end

    class Short < Base
      def parse(data)
        value, data = consume data, "n"
        value = value & 0x4000 > 0 ? -((value ^ 0xFFFF) & 0x7FFF) - 1 : value
        [value, data]
      end

      def encode
        [value].pack("n")
      end
    end

    class Boolean < Base
      def parse(data)
        flag, remainder = consume data, "C"
      end

      def encode
        [value].pack("C")
      end
    end

    class Double < Base
      def parse(data)
        value, remainder = consume data, "G"
      end

      def encode
        [value].pack("G")
      end
    end

    class Float < Base
      def parse(data)
        value, remainder = consume data, "g"
      end
      def encode
        [value].pack("g")
      end
    end

    class Byte < Base
      def parse(data)
        value, remainder = consume data, "c"
      end

      def encode
        [value].pack("c")
      end
    end

    class PlayerInventory < Base
      def parse(data)
        type, supposed_count, data = consume data, "Nn"
        count = case type
        when 0xFFFFFFFF # -1
          36
        else
          4
        end

        count.times do |n|
          item_id, data = consume data, "n"
          # item_id = item_id & 0x4000 > 0 ? -((item_id ^ 0xFFFF) & 0x7FFF) - 1 : item_id
          # puts "    slot #{n} item id #{item_id}"
          unless item_id == 0xFFFF
            item_count, item_health, data = consume data, "cn"
          end
        end

        # puts "done with inventory"
        [supposed_count, data]
      end
    end

    class MapChunk < Base
      def parse(data)
        size_x, size_y, size_z, chunk_size, data = consume data, "cccN"
        # total_entries = (size_x + 1) * (size_y + 1) * (size_z + 1)
        if data.size >= chunk_size
          chunk_data = data[0...chunk_size]
          data = data[chunk_size..-1]
        else
          raise IncompletePacket
        end
        # chunk_data, data = consume data, "C#{chunk_size}"
        # *bytes, data = consume data, "C#{(total_entries * 2.5).to_i}"
        # chunk = bytes.map {|b| b.chr }.join("")
        # [[size_x + 1, size_y + 1, size_z + 1, chunk_size], data]
        [size_x + 1, size_y + 1, size_z + 1, "#{chunk_size} bytes", data]
      end
    end

    class EntityPayload < Base
      def parse(data)
        size, data = consume data, "n"
        *bytes, data = consume data, "C#{size}"
        payload = bytes.map {|b| b.chr }.join("")
        [[size, payload], data]
      end
    end

  end
end
