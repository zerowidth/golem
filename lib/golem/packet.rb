module Golem
  class Packet

    def self.parse(data)
      code, data = data.unpack("Ca*")
      packet_class = packets[code] || UnknownPacket
      puts "   parsing as #{packet_class.description}"
      packet_class.new(data)
    end

    def self.packets
      @packets ||= {}
    end

    def self.client_packets
      @client_packets ||= {}
    end

    class << self
      attr_accessor :code

      # name / class mapping for fields
      # ORDERED HASH, requires ruby 1.9, or more hackery.
      unless RUBY_VERSION =~ /1\.9\.\d+/
        raise "aieee hashes aren't ordered in #{RUBY_VERSION}" 
      end

      def fields
        @fields ||= {}
      end
    end

    extend PacketDefinition

    attr_reader :fields

    def initialize(data=nil)
      @fields = {}
      self.class.fields.each do |key, field_class|
        field = field_class.new
        @fields[key] = klass.new
      end
    end

    def [](name)
      fields[name] ? fields[name].value : nil
    end

    def []=(name, value)
      field = fields.detect { |key, _| key == name }
      if field
        _, field = field
        field.value = value
      else
        raise ArgumentError, "unknown field #{name.inspect}"
      end
    end

    def encode
      data = [self.class.code].pack("C")
      fields.each do |key, field|
        data << field.encode
      end
      data
    end

    def respond(client)
      # noop
    end

  end

  UnknownPacket = Class.new(Packet)
  UnknownPacket.description = "unknown packet"
end
