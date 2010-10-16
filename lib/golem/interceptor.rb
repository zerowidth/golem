module Golem

  class Interceptor < EM::Connection

    attr_reader :server, :server_parser, :client_parser

    def initialize(server_host, server_port)
      @server = EM.connect(server_host, server_port, Server, self)
    end

    def post_init
      puts "got connection"
      @server_parser = Parser.new
      @client_parser = Parser.new(false)
    end

    def receive_data(data)
      client_parser.parse(data).each do |packet|
        puts "<-- #{packet.inspect}"
      end
      server.send_data data
    end

    def send_data(data)
      super
    end

    def from_server(data)
      server_parser.parse(data).each do |packet|
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
