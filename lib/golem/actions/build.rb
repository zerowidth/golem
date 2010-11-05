module Golem
  module Actions
    class Build < Action

      attr_reader :blueprint, :center
      attr_reader :state
      attr_reader :actions, :placed

      def setup(blueprint_file, center)
        @center = center
        @blueprint = Blueprint.new(blueprint_file, center)
        @state = :dig # or :place
        @actions = []
        @placed = {}
        @done = false

        puts "building #{blueprint_file} centered at #{center.inspect} -- #{blueprint.range.inspect}"
        # blueprint.survey_coords(map, :top_down).each do |*change|
        #   puts "  #{change.inspect}"
        # end
        # puts "---"

      rescue Errno::ENOENT => e
        @done = true
        puts "#{e.message}"
      end

      def tick
        if actions.empty?
          @actions = next_actions

          if actions.empty?
            if state == :dig
              puts "done clearing, now placing"
              @state = :place
            else
              puts "all done!"
              @done = true
            end
          end

        else

          10.times do
            break if actions.empty?
            action, coords = actions.shift
            case action
            when :dig
              puts "dig #{coords[0]} #{coords[1]} #{coords[2]}"
              client.dig(*coords)
            when :place
              puts "place #{coords[0]} #{coords[1]} #{coords[2]} #{coords[3]}"
              client.place(*coords)
            when :move
              @last_move = coords
              puts "move #{coords[0]} #{coords[1]} #{coords[2]}"
              client.move_to(*coords)
            end
          end

        end
      end

      def update(packet)
        if packet.class.kind == :player_move_look
          where = [packet.x, packet.y, packet.z]
          puts "crap! moved incorrectly! #{@last_move.inspect} --> #{where.inspect}"
        end
      end

      def done?
        @done
      end

      protected

      def location
        @location ||= Location.new(map)
      end

      def next_actions

        survey = next_changes

        next_actions = []
        current = client.coords

        until survey.empty? || next_actions.size >= 100
          begin
            path_to_nearest = Timeout.timeout(10) { map.path(current, survey.keys, :next_to, placed) }
          rescue Timeout::Error
            path_to_nearest = nil
          end

          break unless path_to_nearest

          path_to_nearest.each { |p| next_actions << [:move, p] }
          current = path_to_nearest.last || current

          location.available(*current, :build).each do |check|
            if survey[check]
              if state == :dig
                next_actions << [:dig, check]
              else
                block = survey[check][1]
                code = BLOCKS.detect {|c, name| name == block}[0]
                next_actions << [:place, check + [code]]
                placed[check] = true # don't use this for pathfinding anymore!
              end
              survey.delete check
            end
          end
        end

        next_actions
      end

      def next_changes
        survey = blueprint.survey_coords(map, state == :dig ? :top_down : :bottom_up, client.coords, 8)
        survey = changes_from_survey(survey)

        if survey.empty?
          puts "using bigger survey"
          survey = blueprint.survey_coords(map, state == :dig ? :top_down : :bottom_up, client.coords, 16)
          survey = changes_from_survey(survey)
        end

        if survey.empty?
          puts "using full survey"
          survey = blueprint.survey_coords(map, state == :dig ? :top_down : :bottom_up)
          survey = changes_from_survey(survey)
        end

        survey
      end

      def changes_from_survey(survey)
        survey.delete_if do |position, change|
          needs_change = state == :dig ? needs_clearing?(position, change) : needs_placement?(position, change)
          !needs_change || !location.available(*position, :next_to).any? { |l| location.allowed?(*l) }
        end
      end


      def needs_clearing?(position, change)
        from, to = change
        SOLID.include?(from) && (SOLID.include?(to) || to == :air)
      end

      def needs_placement?(position, change)
        from, to = change
        SOLID.include?(to)
      end

    end
  end
end
