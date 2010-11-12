module Golem
  module Actions
    class Follow < Action

      attr_reader :pending_moves

      def setup(name)
        @name = name

        if player = state.players[name]
          @following = player.id
          @position = player.position
          @follow_position = @position ? @position.map(&:to_i) : nil
        end

        @pending_moves = []

        log "following #{name}" if @position

        follow
      end

      def update(packet)
        case packet.class.kind

        when :named_entity_spawn
          if packet.name == @name
            log "following #{@name}"
            @following = packet.id
            @position = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
            follow
          end

        when :entity_move, :entity_move_look
          if packet.id == @following
            deltas = [packet.x, packet.y, packet.z].map { |v| v.to_f / 32 }
            @position = @position.map.with_index { |v, i| (v + deltas[i]) }
            follow
          end

        when :entity_teleport
          if packet.id == @following
            @position = [packet.x, packet.y, packet.z].map { |v| v / 32 }
            follow
          end

        when :destroy_entity
          if packet.id == @following
            log "#{@name} went away, can't follow :("
            @following = nil
            @position = nil
            @follow_position = nil
          end

        end

      end

      # runs until replaced by anything else
      def done?
        false
      end

      def tick
        return if pending_moves.empty?
        state.look_at(@position[0], @position[1] + 1.5, @position[2])
        move_to(*pending_moves.shift) # sends move_look
      end

      protected

      def follow
        return unless @following && @position

        new_pos = @position.map(&:floor).map(&:to_i)
        if @follow_position != new_pos
          # log "player has moved to #{new_pos.inspect}"
          @follow_position = new_pos
          available = map.available(*new_pos, :follow)

          if !available.empty? && path = map.path(state.coords, available)
            @pending_moves = path
          else
            log "can't follow #{@name}!"
          end
        end

      end

    end
  end
end

