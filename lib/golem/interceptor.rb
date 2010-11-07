module Golem

  class Interceptor < EM::Connection

    attr_reader :server, :server_parser, :client_parser
    attr_reader :state

    def initialize(server_host, server_port)
      @server = EM.connect(server_host, server_port, ServerConnection, self)
    end

    def post_init
      puts "proxying new connection"
      @server_parser = Parser.new
      @client_parser = Parser.new(false)
      @state = State.new
      @time = nil
      @possessed = true
    end

    def unbind
      puts "client disconnected, shutting down"
      EM.stop
    end

    def receive_data(data) # from client, outbound
      to_send = ""
      client_parser.parse(data).each do |packet|
        state.update packet unless possessed?
        # puts "<-- #{packet.inspect}"
        to_send << intercept(packet)
      end
      server.send_data to_send unless to_send.empty?
    end

    def send_data(data)
      super
    end

    def from_server(data)
      to_send = ""
      server_parser.parse(data).each do |packet|
        state.update packet
        if packet.kind == :update_time && @time
          to_send << Packet.server_packets_by_kind[:update_time].new(@time).encode
        else
          to_send << intercept(packet)
        end
        # puts "--> #{packet.inspect}"
      end
      send_data to_send unless to_send.empty?
    end

    def possessed?
      @possessed
    end

    def intercept(packet)
      to_send = ""

      if packet.kind == :chat
        unless proxy_command(packet)
          to_send << packet.raw
        end
      else
        if possessed?
          case packet.kind
          when :player_position, :player_move_look
            # TODO rate-limit this. hovering in midair sends a lot of packets
            pos = state.position
            reset = Packet.server_packets_by_kind[:player_position].new(pos.x, pos.stance, pos.y, pos.z, pos.flying)
            send_data reset.encode
          when :player_look
            # ignore, let the client look wherever it wants
          else
            to_send << packet.raw # let it through
          end
        else
          to_send << packet.raw
        end
      end

      to_send
    end

    def proxy_command(packet)
      message = packet.values.first
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
      when /\/possess/
        tell_client "you are possessed!"
        @possessed = true
      when /\/me/
        tell_client "you are feeling much more like yourself!"
        @possessed = false
      when /\/move (-?\d+) (-?\d+) (-?\d+)/
        movement = [$1, $2, $3].map(&:to_i)
        if possessed?
          tell_client "moving #{movement.inspect}"
          move(*movement)
        else
          tell_client "no way man"
        end
      else
        return false
      end
      true
    end

    def tell_client(msg)
      send_data Packet.server_packets_by_kind[:chat].new("<proxy> #{msg}").encode
    end

    # relative movement
    def move(x, y, z)
      pos = state.position
      puts "currently #{pos.inspect}"
      pos.x = pos.x.floor + x + 0.5
      pos.y = pos.y.floor + y
      pos.z = pos.z.floor + z + 0.5
      puts "now: #{pos.inspect}"

      packet = Packet.client_packets_by_kind[:player_position].new(pos.x, pos.y, pos.stance, pos.z, pos.flying)
      state.update packet

      reset = Packet.server_packets_by_kind[:player_position].new(pos.x, pos.stance, pos.y, pos.z, pos.flying)

      server.send_data packet.encode
      send_data reset.encode
    end

  end

  class ServerConnection < EM::Connection
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
