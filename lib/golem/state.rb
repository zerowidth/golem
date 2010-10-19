module Golem

  Position = Struct.new(:x, :y, :stance, :z, :rotation, :pitch, :flying)

  class State

    STANCE = 1.62000000476837

    attr_reader :entities, :position, :master

    def initialize
      @position = Position.new
      @entities = {}
      @master = nil
      send_delayed 0.5, :handshake, "golem"

      # keepalive
      EM.add_periodic_timer(5) { send_packet :flying_ack, @position.flying }
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

      when :disconnect
        packets_to_send << :disconnect

      when :player_move_look
        x, stance, y, z, rotation, pitch, flying = packet.values

        position.x, position.y, position.z = x, y, z
        position.stance = stance
        position.rotation, position.pitch, position.flying = rotation, pitch, flying

        # verify our position with the server
        send_packet :player_move_look, x, y, stance, z, rotation, pitch, flying

      when :entity
        # don't care

      when :vehicle_spawn, :mob_spawn
        entities[packet.id] = [packet.x, packet.y, packet.z]

      when :named_entity_spawn
        entities[packet.id] = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
        @master ||= packet.id

      when :entity_move, :entity_move_look
        if entities[packet.id]
          deltas = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
          entities[packet.id] = entities[packet.id].map.with_index { |v, i| v + deltas[i] }
          if @master == packet.id
            look_at_master
            send_look
          end
        end

      when :entity_teleport
        if entities[packet.id]
          entities[packet.id] = [packet.x, packet.y, packet.z].map { |v| v / 32 }
        end

      when :destroy_entity
        entities.delete packet.id

      when :pre_chunk
        if !packet.add
          map.delete(packet.x, packet.z)
        end

      when :map_chunk
        send_packet :flying_ack, true
        map.add Chunk.new(packet.x, packet.z, packet.values.last)

      when :block_change
        # TODO update map

      when :multi_block_change
        # TODO update map

      end

    end

    def move(x, y, z)
      position.x = x
      position.y = y
      position.stance = y + STANCE
      position.z = z
      look_at_master
      send_move_look
    end

    def block_at(x, y, z)
      map[x, y, z]
    end

    def adjacent
      map.available(position.x.floor, position.y.floor, position.z.floor)
    end

    protected

    def send_look
      send_packet :player_look, position.rotation, position.pitch, position.flying
    end

    def send_move_look
      send_packet :player_move_look, position.x, position.y, position.stance, position.z, position.rotation, position.pitch, position.flying
    end

    def map
      @map ||= Map.new
    end

    def look_at_master
      x, y, z = entities[@master]
      return unless x && y && z
      position.pitch = Math.atan2(position.y - y, Math.sqrt((position.x - x)**2 + (position.z - z)**2)).in_degrees
      position.rotation = Math.atan2(position.z - z, position.x - x).in_degrees + 90
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
