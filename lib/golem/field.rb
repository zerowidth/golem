module Golem
  module Field
    class Base
      attr_accessor :value

      # sets the value based on type and returns the remaining data
      # must be overwritten in subclasses!
      def parse(data)
        data
      end

      # encode the value appropriately, returns a string
      def encode
        ""
      end
    end

    class String < Base
      def parse(data)
        size, rest = data.unpack("na*")
        self.value, remainder = rest.unpack("a#{size}a*")
        remainder
      end

      def encode
        [value.size, value].pack("na*")
      end
    end

    class Integer < Base
      def parse(data)
        self.value, remainder = data.unpack("Na*")
        remainder
      end

      def encode
        [value].pack("N")
      end
    end

  end
end
