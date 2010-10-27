module Golem

  Position = Struct.new(:x, :y, :stance, :z, :rotation, :pitch, :flying)
  Entity = Struct.new(:position, :type, :name)

  class Client < ::EventMachine::Connection

    STANCE = 1.62000000476837

    attr_reader :parser, :position, :entities, :map
    attr_reader :current_action

    def initialize(opts={})
    end

    def post_init
      log "client connected"
      @parser = Parser.new
      @position = Position.new
      @entities = {}
      @map = Map.new
      send_packet :handshake, "golem"
    end

    def unbind
      log "client disconnected"
      EM.stop
    end

    def receive_data(data)
      parser.parse(data).each do |packet|
        debug "server --> #{packet.inspect}"
        handle packet
      end
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise
    end

    attr_reader :debug_pattern
    def debug_pattern=(pattern)
      @debug_pattern = pattern ? Regexp.new(pattern) : nil
    rescue RegexpError => e
      log "invalid regex: #{e.message}: #{pattern.inspect}"
    end

    def look_at(x, y, z)
      dist = Math.sqrt((position.x.floor - x)**2 + (position.z.floor - z)**2 + 0.001)
      position.pitch = Math.atan2(position.y - y + 1, dist).in_degrees
      position.rotation = Math.atan2(position.z.floor - z, position.x.floor - x + 0.001).in_degrees + 90
    end

    def send_look
      send_packet :player_look, position.rotation, position.pitch, position.flying
    end

    def send_move_look
      send_packet :player_move_look, position.x, position.y, position.stance, position.z, position.rotation, position.pitch, position.flying
    end

    def send_packet(kind, *values)
      packet_class = Packet.client_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new(*values)
      debug "<-- client  #{packet.inspect}"
      send_data packet.encode
    end

    def stop
      @current_action = nil
    end

    def watch(player)
      id = pos = nil
      if entity = entities.detect { |i, e| e.name == player }
        id, entity = *entity
        pos = entity.position
      end

      action Actions::Watch, player, id, pos
    end

    def log(msg)
      puts Time.now.strftime("%F %H:%M:%S.%3N ") << msg
    end

    protected

    def action(action_class, *args)
      @current_action = action_class.new(self, map)
      @current_action.setup(*args)
    end

    def handle(packet)
      case packet.class.kind

      when :server_handshake
        send_packet :login, 2, "golem", "password"

        # keepalive
        EM.add_periodic_timer(0.5) { send_packet :flying_ack, position.flying if position.x }
        EM.add_periodic_timer(10) { send_packet :keepalive }

        # general action proessing
        EM.add_periodic_timer(0.1) do
          if current_action
            if current_action.done?
              @current_action = nil
            else
              current_action.tick
            end
          end
        end

      when :disconnect
        EM.stop

      when :player_move_look
        x, stance, y, z, rotation, pitch, flying = packet.values

        position.x, position.y, position.z = x, y, z
        position.stance = stance
        position.rotation, position.pitch, position.flying = rotation, pitch, flying

        # verify our position with the server
        send_packet :player_move_look, x, y, stance, z, rotation, pitch, flying

      when :vehicle_spawn, :mob_spawn
        entities[packet.id] = Entity.new([packet.x, packet.y, packet.z], nil)

      when :named_entity_spawn
        pos = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
        entities[packet.id] = Entity.new pos, :player, packet.name

      when :entity_move, :entity_move_look
        if entity = entities[packet.id]
          deltas = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
          new_pos = entity.position.map.with_index { |v, i| v + deltas[i] }
          entity.position = new_pos
        end

      when :entity_teleport
        if entities[packet.id]
          entities[packet.id].position = [packet.x, packet.y, packet.z].map { |v| v / 32 }
        end

      when :destroy_entity
        deleted = entities.delete packet.id

      when :pre_chunk
        if packet.add
          map.preinitialize(packet.x, packet.z)
        else
          map.drop(packet.x, packet.z)
        end

      when :map_chunk
        send_packet :flying_ack, true
        before = map.size
        map.add Chunk.new(packet.x, packet.y, packet.z, packet.size_x, packet.size_y, packet.size_z, packet.values.last)

      when :block_change
        map[packet.x, packet.y, packet.z] = BLOCKS[packet.type]

      when :multi_block_change
        packet.changes.each do |location, type|
          map[*location] = BLOCKS[type]
        end
        send_packet :flying_ack, position.flying
      end

      current_action.update(packet) if current_action
    end

    def debug(msg)
      log msg if debug_pattern && msg =~ debug_pattern
    end

    # # delegators

    # def position
    #   state.position
    # end

    # # def move_to(x, y, z)
    # #   state.move_to(x, y, z)
    # # end

    # def block_at(x, y, z)
    #   state.block_at(x, y, z)
    # end

    # def adjacent
    #   state.adjacent
    # end

    # def path_to(x, y, z)
    #   state.path_to(x, y, z)
    # end

    # def follow(flag)
    #   state.follow_mode = flag ? :follow : :watch
    # end

    # def follow_position
    #   state.follow_position
    # end

    # def equip(code)
    #   state.equip(code.to_i)
    # end

    # def dig(x, y, z, direction)
    #   state.dig(x, y, z, direction)
    # end

    # def place(x, y, z, code)
    #   state.place(x, y, z, code)
    # end

    # def say(msg)
    #   state.say(msg)
    # end

  end
end
