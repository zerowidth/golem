module Golem

  class Interceptor < EM::Connection

    attr_reader :server, :server_parser, :client_parser

    def initialize(server_host, server_port)
      @server = EM.connect(server_host, server_port, Server, self)
    end

    def post_init
      puts "proxying new connection"
      @server_parser = Parser.new
      @client_parser = Parser.new(false)
    end

    def receive_data(data)
      to_send = ""
      client_parser.parse(data).each do |packet|
        # puts "<-- #{packet.inspect}"
        to_send << packet.raw
      end
      server.send_data to_send unless to_send.empty?
    end

    def send_data(data)
      super
    end

    def from_server(data)
      to_send = ""
      server_parser.parse(data).each do |packet|
        # puts "--> #{packet.inspect}"
        to_send << packet.raw
      end
      send_data to_send unless to_send.empty?
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
