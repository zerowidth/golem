module Golem
  module Actions
    class Clear < Action

      attr_reader :start, :pos, :state

      def setup(start_position, x1, z1, x2, z2)
        @state = :starting

        

        @start = @pos = [x, y, z]
        puts "digging a hole starting at #{@pos.inspect}"
        @state = :digging
        client.move_to x, y, z
      end

      def tick
        case state
        when :digging
          below = pos.dup
          below[1] -= 1

          if below[1] < 0
            @state = :returning
          elsif map[*below] == :bedrock
            puts "found bedrock, coming back up"
            @state = :returning
          elsif map.solid?(*below)
            # puts "digging down: #{map[*below]}"
            client.dig(below[0], below[1], below[2], 1)
          else
            # puts "moving down"
            @pos = below
            client.move_to(*pos)
          end
        when :returning
          if pos == start
            @state = :done
            puts "done with hole!"
          else
            # puts "moving back"
            pos[1] += 1
            client.move_to(*pos)
          end
        end
      end

      def done?
        @state == :done
      end

    end
  end
end
