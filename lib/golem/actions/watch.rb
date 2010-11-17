module Golem
  module Actions
    class Watch < Action

      def setup(name)
        player = state.players[name]
        @name = name
        if player
          @watching = player.id
          @position = player.position.map { |v| v / 32 }
        end

        log "watching #{name}" if @position

        look
      end

      def update(packet)
        case packet.class.kind

        when :named_entity_spawn
          if packet.name == @name
            log "watching #{@name}"
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
            log "#{@name} went away, can't watch :("
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
        state.look_at(@position[0], @position[1] + 1.5, @position[2])
        send_packet :player_look, *state.look_values
      end

    end
  end
end
