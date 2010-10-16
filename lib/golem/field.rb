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
        size, rest = consume data, "n"
        value, rest = consume rest, "a#{size}"
        [value, rest]
      end

      def encode
        [value.size, value].pack("na*")
      end
    end

    class Integer < Base
      def parse(data)
        # N isn't correct, need big-endian signed 32-bit integer
        value, rest = consume data, "N"
        [value, rest]
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
        # n is wrong, it's unsigned... convert to signed
        value, remainder = data.unpack("na*")
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
        type, supposed_count, rest = consume data, "Nn"
        count = case type
        when 0xFFFFFFFF # -1
          36
        else
          4
        end

        count.times do |n|
          item_id, rest = consume rest, "n"
          # item_id = item_id & 0x4000 > 0 ? -((item_id ^ 0xFFFF) & 0x7FFF) - 1 : item_id

          puts "    slot #{n} item id #{item_id}"

          unless item_id == 0xFFFF
            item_count, item_health, rest = consume rest, "cn"
          end
        end

        puts "done with inventory"
        [supposed_count, rest]
      end
    end

  end
end
