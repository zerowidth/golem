module Golem
  module Actions
    class Come < Action

      def setup(name)
        player = state.players[name]

        if player
          position = player.position.map { |v| v/32 }
          log "coming to #{position.inspect}"

          available = map.available(*position, :follow)
          if !available.empty? && path = map.path(state.coords, available)
            path.each { |move| move_to(*move) }
          else
            log "can't come!"
          end
        else
          log "can't find #{name}!"
        end
      end

    end
  end
end

