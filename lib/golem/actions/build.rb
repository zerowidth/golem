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

        @cleared = false
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
        puts "tick: #{state.inspect}"
        case state
        when :dig
          dig
        when :place
          place
        when :move
          move
        end
      end

      def done?
        @done
      end

      def cleared?
        @cleared
      end

      def dig
        to_consider = location.available(*client.coords, :build)

        survey = blueprint.survey_coords(map)
        to_dig = to_consider.select do |dig|
          # TODO smarter about water interfering, etc.
          survey[dig] && survey[dig][0] != survey[dig][1] && map.solid?(*dig)
        end

        if to_dig.empty?
          puts "nothing left to dig, moving"
          @state = :move
        else
          puts "digging: #{to_dig.inspect}"
          to_dig.each {|where| client.dig(*where) }
        end
      end

      def place
        to_consider = location.available(*client.coords, :build)
        puts "blocks under consideration: #{to_consider.inspect}"

        survey = blueprint.survey_coords(map)

        to_place = to_consider.select do |place|
          survey[place] && survey[place][0] != survey[place][1] &&
            SOLID.include?(survey[place][1]) &&
            !map.solid?(*place) &&
            map[*place] != :torch
        end

        if to_place.empty?
          puts "nothing left to place, moving"
          @state = :move
        else
          to_place.each do |where|
            block = survey[where][1]
            code = BLOCKS.detect {|code, name| name == block}[0]

            a, b = survey[where]
            c = map[*where]
            puts "placing #{block.inspect} at #{where.inspect}, #{a} #{b} #{c}: #{code}"
            client.place(*where, code)
          end
        end

      end

      def move
        if pending_moves.nil?

          if cleared?
            next_blocks = blocks_to_place
          else
            next_blocks = blocks_to_clear
          end

          if next_blocks.empty?
            if cleared?
              puts "all done!"
              @done = true
            else
              puts "all clear, now placing blocks"
              @cleared = true
              @state = :place
            end

          else

            path = map.path(client.coords, next_blocks, :next_to)
            @pending_moves = path

          end

        else
          if move = pending_moves.shift
            puts "moving to #{move.inspect}"
            client.move_to(*move)
          end

          if pending_moves.empty?
            @pending_moves = nil
            if cleared?
              @state = :place
            else
              @state = :dig
            end
          end
        end
      end

      # list of blocks that need to be replaced still
      def blocks_to_place
        blocks = []

        # survey = blueprint.survey_coords(map, client.coords)
        # if survey.empty?
        #   puts "local survey insufficient, doing full survey"
          survey = blueprint.survey_coords(map)
        # end

        survey.each do |coords, current, needs_to_be|
          if current != needs_to_be && needs_to_be != :air
            blocks << coords
          end
        end

        puts "#{blocks.size} blocks left to place"

        blocks
      end

      def blocks_to_clear
        blocks = []

        # survey = blueprint.survey_coords(map, client.coords)
        # if survey.empty?
        #   puts "local survey insufficient, doing full survey"
          survey = blueprint.survey_coords(map)
        # end

        survey.each do |coords, current, needs_to_be|
          if current != needs_to_be && map.solid?(*coords)
            blocks << coords
          end
        end
        puts "#{blocks.size} blocks left to clear"

        blocks
      end

    end
  end
end
