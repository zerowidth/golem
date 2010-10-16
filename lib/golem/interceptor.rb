module Golem

  class Parser
    def initialize
      @buffer = ""
    end

    def parse(data)
      @buffer << data

      packets = []
      while @buffer != ""
        begin
          packet, @buffer = Packet.parse(@buffer)
          packets << packet
        rescue IncompletePacket
          break
        end
      end

      packets
    end
  end

  class Interceptor < EM::Connection

    attr_reader :server, :server_packets

    def initialize(server_host, server_port)
      @server = EM.connect(server_host, server_port, Server, self)
    end

    def post_init
      puts "got connection"
      @server_packets = Parser.new
    end

    def receive_data(data)
      # puts "<-- #{data.inspect}"

      server.send_data data
    end

    def send_data(data)
      # puts "--> #{data.inspect}"
      super
    end

    def from_server(data)
      server_packets.parse(data).each do |packet|
        puts "--> #{packet.inspect}"
      end
      send_data(data)
    end

  end

  class Server < EM::Connection
    def initialize(client)
      @client = client
    end
    def receive_data(data)
      @client.from_server(data)
    end
  end
end
