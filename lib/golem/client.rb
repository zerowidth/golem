module Golem

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

    def coords
      [position.x, position.y, position.z].map(&:floor).map(&:to_i)
    end

    def look_at(x, y, z)
      dist = Math.sqrt((position.x.floor - x)**2 + (position.z.floor - z)**2 + 0.001)

      # always look downward a bit, so digging blocks next to the feet work.
      position.pitch = Math.atan2(position.y - y + STANCE, dist).in_degrees
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

    def say(msg)
      send_packet :chat, msg
    end

    def equip(code)
      send_packet :block_item_switch, 0, code
    end

    def dig(x, y, z)
      look_at(x, y, z)
      send_look

      equip map.tool_for(x, y, z)

      # favor x, z directionality over y, since
      # digging to the side could mean y + 1 or y + 0
      if coords[0] < x
        face = 4
      elsif coords[0] > x
        face = 5
      elsif coords[2] < z
        face = 2
      elsif coords[2] > z
        face = 3
      elsif coords[1] < y
        face = 0
      elsif coords[1] > y
        face = 1
      end

      to_send = []
      to_send << [:block_dig, 0, x, y, z, face]
      to_send << [:arm_animation, 0, true]

      # an extra 5 packets for good measure seems to make it work better
      count = (DIGS[map[x, y, z]] || 3000) + 5
      count.times do
        to_send << [:block_dig, 1, x, y, z, face]
      end

      to_send << [:block_dig, 3, x, y, z, face]
      to_send << [:block_dig, 2, 0, 0, 0, 0]

      to_send.each { |packet| send_packet(*packet) }

    end

    def place(x, y, z, code)
      look_at(x, y, z)
      send_look

      equip code
      send_packet :place, code, x, y - 1, z, 1
    end

    def block_at(x, y, z)
      map[x, y, z]
    end

    def watch(player)
      id = pos = nil
      if entity = entities.detect { |i, e| e.name == player }
        id, entity = *entity
        pos = entity.position
      end

      action Actions::Watch, player, id, pos
    end

    def follow(player)
      id = pos = nil
      if entity = entities.detect { |i, e| e.name == player }
        id, entity = *entity
        pos = entity.position
      end

      action Actions::Follow, player, id, pos
    end

    def come_to(player)
      pos = nil
      if entity = entities.detect { |i, e| e.name == player }
        id, entity = *entity
        pos = entity.position
        action Actions::Come, pos
      else
        puts "#{player} unknown"
      end
    end

    def send_empty_inventory
      # tell the server we have all the tools, but plenty of room for picking up the things we just dug
      send_packet :player_inventory, [-3, [nil, nil, nil, nil]]
      send_packet :player_inventory, [-2, [nil, nil, nil, nil]]
      send_packet :player_inventory, [-1, [
        # main inventory slots:
        [276, 1, 1], # sword
        [277, 1, 1], # spade
        [278, 1, 1], # pickaxe
        [279, 1, 1], # axe
        nil, nil, nil, nil,
        [345, 1, 0], # compass

        nil, nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil, nil, nil
      ]]
    end


    def survey(blueprint, center = nil)
      where = center || coords
      action Actions::Survey, blueprint, where
    end

    def build(blueprint, center = nil)
      where = center || coords
      puts "building #{blueprint} at #{where.inspect}"
      action Actions::Build, blueprint, where
    end

    def hole(x, y, z)
      action Actions::Hole, x, y, z
    end

    def path_to(x, y, z)
      map.path(coords, [x, y, z].map(&:floor).map(&:to_i))
    end

    def move_to(x, y, z)
      # debug "moving to #{x} #{y} #{z}"
      position.x = x + 0.5
      position.y = y
      position.z = z + 0.5
      position.stance = y + STANCE
      position.flying = map.solid?(x, y - 1, z)
      send_move_look
    end

    def log(msg)
      puts Time.now.strftime("%F %H:%M:%S.%3N ") << msg
    end

    def action(action_class, *args)
      @current_action = action_class.new(self, map)
      @current_action.setup(*args)
    end

    protected

    def handle(packet)
      case packet.class.kind

      when :server_handshake
        send_packet :login, 3, "golem", "Password"
        9.times { send_packet :keepalive }

        # keepalive
        EM.add_periodic_timer(1) { send_packet :flying_ack, position.flying if position.x }
        EM.add_periodic_timer(10) { send_packet :keepalive }

        # general action proessing
        EM.add_periodic_timer(0.25) do
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

      when :chat
        log packet.message

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

      when :pickup_spawn
        pos = [packet.x, packet.y, packet.z].map {|l| l/32 } # absolute positions
        entities[packet.id] = Entity.new pos, :pickup

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
        if !packet.add
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

  end
end
