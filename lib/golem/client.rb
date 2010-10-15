module Golem
  class Client < ::EventMachine::Connection

    def self.run(host)
      EventMachine.run do
        EventMachine.connect host, 25565, self
      end
    end

    def send_packet(kind, values = {})
      packet_class = Packet.client_packets[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new
      values.each { |key, value| packet[key] = value }
      puts "sending packet #{kind}"
      send_data packet.encode
    end

    def send_data(data)
      puts "<-- #{data.inspect}"
      super
    end

    def post_init
      send_packet :handshake, :username => "golem"
    end

    def receive_data(data)
      puts "--> " + data.inspect
      packet = Packet.parse(data)

      packet.respond(self)

    end

  end
end
