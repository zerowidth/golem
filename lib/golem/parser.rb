module Golem
  class Parser

    def initialize(server_packets=true)
      @buffer = ""
      @server_packets = server_packets
    end

    def server_packets?
      @server_packets
    end

    def parse(data)
      @buffer << data

      packets = []
      while @buffer != ""
        begin
          packet, @buffer = Packet.parse(@buffer, server_packets?)
          yield packet if block_given?
          packets << packet
        rescue IncompletePacket
          break
        end
      end

      packets
    end
  end

end
