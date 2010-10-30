module Golem
  module Actions
    class Build < Action

      attr_reader :blueprint, :state, :pending_moves
      attr_reader :location

      def setup(blueprint_file, center)
        @center = center
        @blueprint = Blueprint.new(blueprint_file, center)
        @done = false
        @pending_moves = nil
        @location = Location.new(map)

        @state = :dig # :move, :place

        puts "building #{blueprint_file} centered at #{center.inspect}"

        puts "survey of #{blueprint_file} centered at #{center.inspect}:"
        blueprint.survey(map).each do |change|
          puts "  #{change.inspect}"
        end
        puts "---"

      rescue Errno::ENOENT => e
        puts "#{e.message}"
      end

      def tick
        case state
        when :dig
          dig_next
        when :move
          move_to_next
        end
        check_for_completion
      end

      def done?
        @done
      end

      def dig_next
        to_consider = location.available(*client.coords, :build)
        # puts "blocks under consideration: #{to_consider.inspect}"

        survey = blueprint.survey_coords(map)
        to_dig = to_consider.select do |dig|
          # TODO smarter about water interfering, etc.
          survey[dig] && survey[dig] != map[*dig]
        end.each do |dig|
          # puts "to dig: #{dig.inspect}"
        end

        if to_dig.empty?
          # puts "nothing left to dig, moving"
          @state = :move
        else
          to_dig.each {|where| client.dig(*where) }
        end
      end

      def move_to_next
        if pending_moves.nil?
          next_blocks = []
          blueprint.survey_coords(map).each do |coords, current, needs_to_be|
            if current != needs_to_be
              next_blocks << coords
            end
          end

          puts "#{next_blocks.size} blocks left to clear"

          if next_blocks.size == 0
            puts "all done!"
            @done = true
            return
          end

          path = map.path(client.coords, next_blocks, :next_to)
          # puts "path is: #{path.inspect}"
          @pending_moves = path
        else
          if move = pending_moves.shift
            # puts "moving to #{move.inspect}"
            client.move_to(*move)
          end

          if pending_moves.empty?
            # puts "done moving, now digging"
            @pending_moves = nil
            @state = :dig
          end
        end
      end

      def prepare_moves
      end

      def check_for_completion
      end

    end
  end
end
