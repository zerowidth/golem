module Golem
  module Actions
    class Come < Action

      def setup(position)
        position = position.map(&:to_i)
        client.log "coming to #{position.inspect}"

        available = map.available(*position, :follow)
        if !available.empty? && path = map.path(client.coords, available)
          path.each do |move|
            client.move_to(*move)
          end
        else
          client.log "can't come!"
        end
      end

    end
  end
end

