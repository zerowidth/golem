module Golem
  class Client < ::EventMachine::Connection

    def self.run(host)
      EventMachine.run do
        EventMachine.connect host, 25565, self
      end
    end

    attr_reader :buffer

    def send_packet(kind, *values)
      packet_class = Packet.by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      puts "sending packet #{kind}"
      packet = packet_class.new(*values)
      send_data packet.encode
    end

    def send_data(data)
      puts "<-- #{data.inspect}"
      super
    end

    def post_init
      @buffer = ""
      send_packet :handshake, "golem"
    end

    def receive_data(data)
      puts "--> " + data.inspect
      buffer << data
      packets = parse
      packets.each { |packet| respond(packet) }
    end

    def parse
      packets = []
      while buffer != ""
        begin
          packet, @buffer = Packet.parse(buffer)
          packets << packet
        rescue IncompletePacket
          puts "incomplete"
          break
        end
      end
      packets
    end

    def respond(packet)
      case packet.class.kind
      when :server_handshake
        puts "server says hello. server id is #{packet.values[0]}"
        send_packet :login, 2, "golem", "password"
      when :accept_login
        # ?
      when :pre_chunk
        send_packet :flying_ack, 1
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
