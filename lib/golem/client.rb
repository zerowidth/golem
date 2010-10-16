module Golem
  class Client < ::EventMachine::Connection

    def self.run(host)
      EventMachine.run do
        EventMachine.connect host, 25565, self
      end
    end

    attr_reader :parser

    def send_packet(kind, *values)
      packet_class = Packet.client_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new(*values)
      puts "<-- #{packet.inspect}"
      send_data packet.encode
    end

    def post_init
      @parser = Parser.new
      send_packet :handshake, "golem"
    end

    def receive_data(data)
      parser.parse(data).each do |packet|
        puts "--> #{packet.inspect}"
        respond(packet)
      end
    end

    def respond(packet)
      case packet.class.kind
      when :server_handshake
        send_packet :login, 2, "golem", "password"
      when :pre_chunk
        # send_packet :flying_ack, 1
      when :disconnect
        close_connection
        EventMachine.stop_event_loop
      else
        # puts "unknown packet, sending keepalive"
        # send_packet :keepalive
      end
    end

  end
end
