module Golem

  Position = Struct.new(:x, :y, :stance, :z, :rotation, :pitch, :flying)
  Entity = Struct.new(:position, :type, :name)

  class State

    attr_reader :map, :position, :entities

    def initialize
      @map = Map.new
      @position = Position.new
      @entities = {}
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
        before = map.size
        map.add Chunk.new(packet.x, packet.y, packet.z, packet.size_x, packet.size_y, packet.size_z, packet.values.last)

      when :block_change
        map[packet.x, packet.y, packet.z] = BLOCKS[packet.type]

      when :multi_block_change
        packet.changes.each do |location, type|
          map[*location] = BLOCKS[type]
        end
      end
    end

    def coords
      [position.x, position.y, position.z].map(&:floor).map(&:to_i)
    end

  end
end
