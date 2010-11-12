module Golem
  class Proxy < Session

    attr_reader :client
    attr_reader :client_parser

    def initialize(client)
      super
      @client = client
    end

    def post_init
      @client_parser = Parser.new(false)
      @time = nil
    end

    def handle(packet)
      if packet.kind == :update_time && @time
        send_server_packet :update_time, @time
      else
        client.send_data packet.raw
      end
    end

    def from_client(data)
      client_parser.parse(data).each do |packet|
        debug "client  --> #{packet.inspect}"
        if packet.kind == :chat
          send_data packet.raw unless proxy_command(packet.message)
        else
          send_data packet.raw
        end
      end
    end

    def proxy_command(message)
      case message
      when /\/time (\d+|dawn|sunrise|dusk|sunset|noon|midnight|server)/
        case $1
        when "dawn", "sunrise"
          @time = 23000
        when "dusk", "sunset"
          @time = 13000
        when "noon"
          @time = 6000
        when "midnight"
          @time = 18000
        when "server"
          @time = nil
        else
          @time = $1.to_i
        end
        tell_client "setting time to #{$1}"
      when /\/(where|gps)/
        tell_client "current coords: #{state.coords.inspect}"
      else
        return false
      end
      true
    end

    def tell_client(msg)
      send_server_packet :chat, "<proxy> #{msg}"
    end

    def send_server_packet(kind, *values)
      packet_class = Packet.server_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new(*values)
      debug "<-- client  #{packet.inspect}"
      client.send_data packet.encode
    end

  end
end
