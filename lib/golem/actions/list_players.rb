module Golem
  module Actions
    class ListPlayers < Action
      def setup
        log "#{state.players.size} other players"
        state.players.each do |name, entity|
          pos = entity.position.map {|v| v / 32 }
          log "#{name}: #{pos.inspect}"
        end
      end
    end
  end
end
