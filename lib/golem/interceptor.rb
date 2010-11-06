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
      @time = 0
    end

    def unbind
      puts "client disconnected, shutting down"
      EM.stop
    end

    def receive_data(data)
      to_send = ""
      client_parser.parse(data).each do |packet|
        if packet.kind == :chat && packet.values.first =~ /\/time (\d+|dawn|sunrise|dusk|sunset|noon|midnight)/
          case $1
          when "dawn", "sunrise"
            @time = 23000
          when "dusk", "sunset"
            @time = 13000
          when "noon"
            @time = 6000
          when "midnight"
            @time = 18000
          else
            @time = $1.to_i
          end
          tell_client "setting time to #{$1}"
        else
        # puts "<-- #{packet.inspect}"
          to_send << packet.raw
        end
      end
      server.send_data to_send unless to_send.empty?
    end

    def send_data(data)
      super
    end

    def from_server(data)
      to_send = ""
      server_parser.parse(data).each do |packet|
        if packet.kind == :update_time
          to_send << Packet.server_packets_by_kind[:update_time].new(@time).encode
        else
          to_send << packet.raw
        end
        # puts "--> #{packet.inspect}"
      end
      send_data to_send unless to_send.empty?
    end

    def tell_client(msg)
      send_data Packet.server_packets_by_kind[:chat].new("<proxy> #{msg}").encode
    end

  end

  class Server < EM::Connection
    def initialize(client)
      @client = client
    end
    def receive_data(data)
      @client.from_server(data)
    end
    def unbind
      puts "lost connection to server"
      EM.stop
    end
  end
end
