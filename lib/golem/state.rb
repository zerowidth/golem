module Golem

  Position = Struct.new(:x, :y, :stance, :z, :rotation, :pitch, :flying)
  Entity = Struct.new(:position, :follow_position)

  class State

    STANCE = 1.62000000476837

    attr_reader :entities, :position, :packet_channel, :following
    attr_accessor :follow_mode

    def initialize(packet_channel, opts={})
      @packet_channel = packet_channel
      @position = Position.new
      @entities = {}
      @follow_player = opts[:follow]
      @following = nil
      @follow_mode = :watch # or :look

      send_delayed 0.5, :handshake, "golem"
      # send_packet :handshake, "golem"

      # pending moves
      EM.add_periodic_timer(0.1) do
        if move = pending_moves.shift
          x, y, z = *move
          puts "moving to #{x} #{y} #{z}"
          position.x = x + 0.5
          position.y = y
          position.z = z + 0.5
          position.stance = y + STANCE
          position.flying = map.solid?(x, y - 1, z)
          send_move_look
        end
      end


      EM.add_periodic_timer(1) do
        while dig = pending_digs.shift
        # if dig = pending_digs.shift
          send_packet(*dig)
        end
      end
    end

    def update(packet)
      case packet.class.kind

      when :server_handshake
        send_packet :login, 2, "golem", "password"
        # keepalive
        EM.add_periodic_timer(0.5) { send_packet :flying_ack, @position.flying }
        EM.add_periodic_timer(10) { send_packet :keepalive }

      when :disconnect
        EM.stop

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
        entities[packet.id] = Entity.new([packet.x, packet.y, packet.z], nil)

      when :named_entity_spawn
        pos = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
        follow_pos = pos.map { |c| c.floor.to_i }
        entities[packet.id] = Entity.new pos, follow_pos
        if packet.name == @follow_player
          puts "yay, #{@follow_player} is here!"
          @following = entities[packet.id]
          follow
        end

      when :entity_move, :entity_move_look
        if entity = entities[packet.id]
          deltas = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
          new_pos = entity.position.map.with_index { |v, i| v + deltas[i] }
          entity.position = new_pos
          follow if entity == @following
        end

      when :entity_teleport
        if entities[packet.id]
          entities[packet.id].position = [packet.x, packet.y, packet.z].map { |v| v / 32 }
          follow if entity == @following
        end

      when :destroy_entity
        deleted = entities.delete packet.id
        if following == deleted
          puts "#{@follow_player} has gone away :("
          @following = nil
        end

      when :pre_chunk
        if packet.add
          map.preinitialize(packet.x, packet.z)
        else
          map.drop(packet.x, packet.z)
        end

      when :map_chunk
        # puts "map chunk"
        send_packet :flying_ack, true
        before = map.size
        map.add Chunk.new(packet.x, packet.y, packet.z, packet.size_x, packet.size_y, packet.size_z, packet.values.last)

      when :block_change
        # puts "block change"
        map[packet.x, packet.y, packet.z] = BLOCKS[packet.type]

      when :multi_block_change
        # puts "multi block change"
        packet.changes.each do |location, type|
          map[*location] = BLOCKS[type]
        end
        send_packet :flying_ack, position.flying
      end

    end

    def block_at(x, y, z)
      map[x, y, z]
    end

    def adjacent
      map.available(position.x.floor, position.y.floor, position.z.floor)
    end

    def path_to(x, y, z)
      map.path([position.x.floor, position.y.to_i, position.z.floor].map(&:to_i), [x, y, z].map(&:to_i))
    end

    def follow_position
      following ? following.follow_position : nil
    end

    def follow
      return unless following && position.x

      current = following.position.map { |v| v.floor.to_i }

      if following.follow_position.nil?
        following.follow_position = current
      end

      if following.follow_position != current
        following.follow_position = current
        x, y, z = *current

        # + 1 to look at the player's head, not feet
        look_at(x, y + 1, z)

        if follow_mode == :watch
          send_look
        else
          my_position = [position.x.floor, position.y.to_i, position.z.floor].map(&:to_i)
          next_to_player = map.available(*current, :follow)

          if next_to_player.size > 0
            path = map.path(my_position, next_to_player)
            if path && path.size > 0
              pending_moves.clear
              pending_moves.concat path
            end
          else
            puts "nowhere to go, can't follow master!"
          end
        end

      end
    end

    def equip(code)
      send_packet :block_item_switch, 0, code
    end

    def dig(x, y, z, direction)
      look_at(x, y, z)
      send_look
      direction ||= 0

      to_send = []

      # (0..5).each do |direction|
        # equip 277 # diamond spade
        1000.times do
          to_send << [:arm_animation, 0, true]
          to_send << [:block_dig, 0, x, y, z, direction]
          to_send << [:block_dig, 1, x, y, z, direction]
          to_send << [:block_dig, 1, x, y, z, direction]
          to_send << [:block_dig, 1, x, y, z, direction]
          to_send << [:block_dig, 1, x, y, z, direction]
          to_send << [:block_dig, 1, x, y, z, direction]
        end
        to_send << [:block_dig, 3, x, y, z, direction]
        to_send << [:block_dig, 2, 0, 0, 0, 0]
      # end

        # while p = to_send.shift
        #   send_packet(*p)
        # end
      # EM.add_timer(0.1) do
      #   puts "done sending packets."
      # end
      pending_digs.concat to_send

    end

    def place(x, y, z, code)
      look_at(x, y, z)
      send_look
      equip code
      send_packet :place, code, x, y - 1, z, 1
    end

    def say(msg)
      send_packet :chat, msg
    end

    def look_at(x, y, z)
      dist = Math.sqrt((position.x.floor - x)**2 + (position.z.floor - z)**2 + 0.001)
      position.pitch = Math.atan2(position.y - y + 1, dist).in_degrees
      position.rotation = Math.atan2(position.z.floor - z, position.x.floor - x + 0.001).in_degrees + 90
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

    def send_packet(kind, *values)
      packet_class = Packet.client_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet_channel.push packet_class.new(*values)
    end

    def send_delayed(delay, kind, *values)
      packet_class = Packet.client_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new(*values)
      EM.add_timer(delay) { packet_channel.push packet }
    end

    def pending_moves
      @pending_moves ||= []
    end

    def pending_digs
      @pending_digs ||= []
    end

  end
end
