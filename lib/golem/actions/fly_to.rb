module Golem
  module Actions
    class FlyTo < Action
      def setup(x, y, z)
        log "flying to #{[x, y, z].inspect}"
        current = state.coords

        current[1] = 127
        move_to(*current)

        step = current[0] < x ? 128 : -128
        current[0].step(x, step) do |new_x|
          current[0] = new_x
          move_to(*current)
        end
        current[0] = x
        move_to(*current)

        step = current[2] < z ? 128 : -128
        current[2].step(z, step) do |new_z|
          current[2] = new_z
          move_to(*current)
        end
        current[2] = z
        move_to(*current)

        # mitigate falling damage by warping to the correct y position
        send_packet :player_position, x.to_f, y.to_f, y + STANCE, z.to_f, true
        move_to x, y, z
      end

      def move(coords)
        state.move_to(*coords)
        send_move_look
      end
    end
  end
end
