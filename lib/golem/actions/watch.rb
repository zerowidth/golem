module Golem
  module Actions
    class Watch < Action

      def setup(name, entity_id, position)
        @name = name
        @watching = entity_id
        @position = position

        client.log "watching #{name}" if @position

        look
      end

      def update(packet)
        case packet.class.kind

        when :named_entity_spawn
          if packet.name == @name
            client.log "watching #{@name}"
            @watching = packet.id
            @position = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
            look
          end

        when :entity_move, :entity_move_look
          if packet.id == @watching
            deltas = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
            @position = @position.map.with_index { |v, i| (v + deltas[i]) }
            look
          end

        when :entity_teleport
          if packet.id == @watching
            @position = [packet.x, packet.y, packet.z].map { |v| v / 32 }
            look
          end

        when :destroy_entity
          if packet.id == @watching
            client.log "#{@name} went away, can't watch :("
            @watching = nil
            @position = nil
          end

        end

      end

      # runs until replaced by anything else
      def done?
        false
      end

      protected

      def look

        return unless @watching && @position
        client.look_at(@position[0], @position[1] + 1, @position[2])
        client.send_look

      end

    end
  end
end
