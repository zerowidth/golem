module Golem
  module Actions
    class ListPlayers < Action
      def setup
        puts "#{state.players.size} other players"
        state.players.each do |name, entity|
          pos = entity.position.map(&:to_i)
          puts "#{name}: #{pos.inspect}"
        end
      end
    end
  end
end
