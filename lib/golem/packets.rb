module Golem
  module Packets
    def self.packet(code, description, &blk)
      p = Class.new(Packet)
      p.code = code
      p.description = description
      p.module_eval(&blk) if blk
      Packet.packets[code] = p
    end

    def self.client_packet(key, code, description, &blk)
      p = Class.new(Packet)
      p.code = code
      p.description = description
      p.module_eval(&blk) if blk
      Packet.client_packets[key] = p
    end

    client_packet :keepalive, 0x00, "client keepalive"

    client_packet :login, 0x01, "client login" do
      int :protocol_version
      string :username
      string :password
    end

    packet 0x01, "server accepts login" do
      int :player_id
      string :unused_1
      string :unused_2
    end

    client_packet :handshake, 0x02, "client handshake" do
      string :username
    end

    packet 0x02, "handshake" do
      string :server_id # or username, for handshake response
      respond do |client|
        client.send_packet :login,
          :protocol_version => 2,
          :username => "golem",
          :password => "Password"
      end
    end

    packet 0xff, "server disconnect" do
      string :message

      respond do |client|
        client.close_connection
        EventMachine.stop_event_loop
      end

    end

  end
end
