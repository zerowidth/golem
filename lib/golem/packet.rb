module Golem

  class Packet

    class << self

      def parse(data, server_packet=true)
        code, data = data.unpack("Ca*")
        packet_class = server_packet ? server_packets_by_code[code] : client_packets_by_code[code]

        unless packet_class
          debug data
          raise Error, "unknown #{server_packet ? "server" : "client"} packet with code #{'0x%02x' % code}"
        end

        # puts "#{'0x%0x' % code}: #{packet_class.kind}"

        packet = packet_class.new
        remainder = packet.parse(data)
        [packet, remainder]
      end

      def server_packet(p)
        server_packets_by_code[p.code] = p
        server_packets_by_kind[p.kind] = p
      end

      def client_packet(p)
        client_packets_by_code[p.code] = p
        client_packets_by_kind[p.kind] = p
      end

      def server_packets_by_code
        @server_packets_by_code ||= {}
      end

      def client_packets_by_code
        @client_packets_by_code ||= {}
      end

      def server_packets_by_kind
        @server_packets_by_kind ||= {}
      end

      def client_packets_by_kind
        @client_packets_by_kind ||= {}
      end

      attr_accessor :code
      attr_accessor :kind

      # fields defined for subclasses
      def fields
        @fields ||= []
      end

      def debug(data)
        print "-" * 52
        row = -1
        column = 16
        data.each_byte do |byte|
          if column == 16
            row += 1
            column = 0
            print "\n%04x" % row
          end
          print " %02x" % byte
          column += 1
        end
        puts
      end

      protected

      def field(name, type)
        fields << type
        index = fields.size - 1
        define_method(name) { values[index] }
      end

      def string(name)
        field name, Field::String
      end

      def int(name)
        field name, Field::Integer
      end

      def long(name)
        field name, Field::Long
      end

      def short(name)
        field name, Field::Short
      end

      def bool(name)
        field name, Field::Boolean
      end

      def double(name)
        field name, Field::Double
      end

      def float(name)
        field name, Field::Float
      end

      def byte(name)
        field name, Field::Byte
      end
    end

    attr_reader :values

    def initialize(*values)
      @values = values
    end

    def parse(data)
      @values = []
      self.class.fields.each do |field|
        *values, data = field.new.parse(data)
        @values.concat values
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
      "<#{'0x%02x' % self.class.code}: #{self.class.kind} #{values.inspect}>"
    end

  end
end
