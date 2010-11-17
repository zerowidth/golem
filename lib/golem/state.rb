module Golem

  Position = Struct.new(:x, :y, :stance, :z, :rotation, :pitch, :flying)
  Entity = Struct.new(:id, :position, :type, :name)

  class State

    attr_reader :map, :position, :entities, :players

    def initialize
      @map = Map.new
      @position = Position.new
      @entities = {}
      @players = {}
    end

    def update(packet)
      case packet.kind

      when :player_look
        rotation, pitch, flying = packet.values
        position.rotation, position.pitch, position.flying = rotation, pitch, flying

      when :player_position
        x, y, stance, z, flying = packet.values
        position.x, position.y, position.z = x, y, z
        position.stance = stance
        position.flying = flying

      when :player_move_look
        x, stance, y, z, rotation, pitch, flying = packet.values

        position.x, position.y, position.z = x, y, z
        position.stance = stance
        position.rotation, position.pitch, position.flying = rotation, pitch, flying

      when :vehicle_spawn, :mob_spawn
        entities[packet.id] = Entity.new(packet.id, [packet.x, packet.y, packet.z], nil)

      when :named_entity_spawn
        pos = [packet.x, packet.y, packet.z]
        entity = Entity.new packet.id, pos, :player, packet.name
        entities[packet.id] = players[packet.name] = entity

      when :pickup_spawn
        pos = [packet.x, packet.y, packet.z]
        # puts "pickup: #{packet.id} #{pos} #{pos.map { |v| v / 32 }}"
        entities[packet.id] = Entity.new packet.id, pos, :pickup

      when :entity_move, :entity_move_look
        if entity = entities[packet.id]
          deltas = [packet.x, packet.y, packet.z]
          new_pos = entity.position.map.with_index { |v, i| v + deltas[i] }
          entity.position = new_pos
        end

      when :entity_teleport
        if entities[packet.id]
          entities[packet.id].position = [packet.x, packet.y, packet.z]
        end

      when :destroy_entity
        deleted = entities.delete packet.id
        if deleted.type == :player
          players.delete deleted.name
        end

      when :pre_chunk
        if !packet.add
          map.drop(packet.x, packet.z)
        end

      when :map_chunk
        map.add Chunk.new(packet.x, packet.y, packet.z, packet.size_x, packet.size_y, packet.size_z, packet.values.last)

      when :block_change
        map[packet.x, packet.y, packet.z] = packet.type

      when :multi_block_change
        packet.changes.each do |location, type|
          map[*location] = type
        end
      end
    end

    def coords
      [position.x, position.y, position.z].map(&:floor).map(&:to_i)
    end

    def look_at(x, y, z)
      dist = Math.hypot(position.x.floor - x, position.z.floor - z)
      position.pitch = Math.atan2(position.y - y + STANCE, dist).in_degrees
      xpos = position.x.floor - x
      zpos = position.z.floor - z
      if xpos == 0 && zpos == 0
        position.rotation = 0
      else
        position.rotation = Math.atan2(zpos, xpos).in_degrees + 90
      end
    end

    def move_to(x, y, z)
      position.x = x + 0.5
      position.y = y
      position.z = z + 0.5
      position.stance = y + STANCE
      position.flying = map.solid?(x, y - 1, z)
    end

    def look_values
      [position.rotation, position.pitch, position.flying]
    end

    def move_look_values
      [position.x, position.y, position.stance, position.z, position.rotation, position.pitch, position.flying]
    end

    def flying
      position.flying
    end

  end
end
