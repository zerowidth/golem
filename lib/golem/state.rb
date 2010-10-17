module Golem

  Position = Struct.new(:x, :y, :stance, :z, :rotation, :pitch, :flying)

  class State

    def initialize
      @position = Position.new
      @entities = {}
      @tracking = nil
      send_delayed 0.5, :handshake, "golem"
    end

    def respond
      while !packets_to_send.empty?
        yield packets_to_send.shift
      end
    end

    def update(packet)
      case packet.class.kind
      when :server_handshake
        send_packet :login, 2, "golem", "password"

      # position updates
      when :player_move_look
        x, stance, y, z, rotation, pitch, flying = packet.values

        @position.x, @position.y, @position.z = x, y, z
        @position.stance = stance
        @position.rotation, @position.pitch, @position.flying = rotation, pitch, flying

        # verify our position
        send_packet :player_move_look, x, y, stance, z, rotation, pitch, flying

      when :entity
        # don't care

      when :vehicle_spawn, :mob_spawn
        @entities[packet.id] = [packet.x, packet.y, packet.z]

      when :named_entity_spawn
        @entities[packet.id] = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
        @tracking ||= packet.id

      when :entity_move, :entity_move_look
        if @entities[packet.id]
          deltas = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
          @entities[packet.id] = @entities[packet.id].map.with_index { |v, i| v + deltas[i] }
          if @tracking == packet.id
            # puts "tracking: #{deltas.inspect} #{@entities[@tracking].inspect}"
            update_tracking
          end
        end

      when :entity_teleport
        if @entities[packet.id]
          @entities[packet.id] = [packet.x, packet.y, packet.z].map { |v| v / 32 }
        end

      when :destroy_entity
        @entities.delete packet.id

      when :disconnect
        packets_to_send << :disconnect
      end
    end

    protected

    def update_tracking
      x, y, z = @entities[@tracking]
      @position.x = x + 2
      @position.y = y
      @position.stance = y + 1.6
      @position.z = z + 1
      send_position
    end

    def send_position
      send_packet :player_position, @position.x, @position.y, @position.stance, @position.z, @position.flying
    end

    def send_packet(kind, *values)
      packet_class = Packet.client_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packets_to_send << packet_class.new(*values)
    end

    def send_delayed(delay, kind, *values)
      packet_class = Packet.client_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new(*values)
      packet.wait = delay
      packets_to_send << packet
    end

    def packets_to_send
      @packets_to_send ||= []
    end

  end
end
