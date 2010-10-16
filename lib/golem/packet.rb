module Golem


  class Packet

    class << self

      def parse(data)
        code, data = data.unpack("Ca*")
        packet_class = by_code[code]
        unless packet_class
          debug data
          raise Error, "unknown packet with code #{'0x%02x' % code}"
        end
        # puts "#{'0x%0x' % code}: #{packet_class.kind}"
        # debug data
        packet = packet_class.new
        remainder = packet.parse(data)
        [packet, remainder]
      end

      def debug(data)
        print "-" * 52
        row = -1
        column = 16
        data.each_char do |char|
          if column == 16
            row += 1
            column = 0
            print "\n%04x" % row
          end
          print " %02x" % char.ord
          column += 1
        end
        puts
      end

      # for code-based server packets
      def by_code
        @by_code ||= {}
      end

      # for named client packets
      def by_kind
        @by_kind ||= {}
      end

      def fields
        @fields ||= []
      end

      def string(name)
        fields << Field::String
      end

      def int(name)
        fields << Field::Integer
      end

      def long(name)
        fields << Field::Long
      end

      def short(name)
        fields << Field::Short
      end

      def bool(name)
        fields << Field::Boolean
      end

      def double(name)
        fields << Field::Double
      end

      def float(name)
        fields << Field::Float
      end

      def byte(name)
        fields << Field::Byte
      end

      attr_accessor :code
      attr_accessor :description
      attr_accessor :kind
    end

    attr_reader :values

    def initialize(*values)
      @values = values
    end

    def parse(data)
      @values = []
      self.class.fields.each do |field|
        *parsed_values, data = field.new.parse(data)
        @values.concat parsed_values
      end
      data
    end

    def encode
      data = [self.class.code].pack("C")
      values.each_with_index do |value, i|
        data << self.class.fields[i].new(value).encode
      end
      data
    end

    def inspect
      "<packet #{'0x%02x' % self.class.code}: #{self.class.kind} #{values.inspect}>"
    end

  end

  UnknownPacket = Class.new(Packet)
  UnknownPacket.kind = :unknown
  UnknownPacket.description = "unknown packet"
end
