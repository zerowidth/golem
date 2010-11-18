module Golem
  module Actions
    class Build < Action

      attr_reader :blueprint, :center
      attr_reader :action
      attr_reader :actions
      attr_reader :pickups

      def setup(blueprint_file, center)
        @center = center
        @blueprint = Blueprint.new(blueprint_file, center)
        @action = :dig # or :place
        @actions = []
        @pickups = {}
        @done = false
        @start_time = Time.now
        @falling_columns = {}

        log "building #{blueprint_file} centered at #{center.inspect} -- #{blueprint.range.inspect}"
        log "starting at #{Time.now.to_s}"
        # blueprint.survey_coords(map, :top_down).each do |location, change|
        #   change = change.map {|c| BLOCKS[c] }
        #   log "  #{location.inspect}: #{change.inspect}"
        # end
        # log "---"

        range = blueprint.range
        state.entities.each do |eid, entity|
          pos = entity.position.map(&:to_i)
          next unless entity.type == :pickup && blueprint.includes?(*pos.map { |v| v / 32 })
          pickups[eid] = pos
        end
        log "tracking #{pickups.size} pickups already"

      rescue Errno::ENOENT => e
        @done = true
        log "#{e.message}"
      end

      def tick
        log "-- #{action} --"
        if actions.empty?
          expire_falling_columns
          @actions = next_actions

          if actions.empty?
            if action == :cleanup
              log "done cleaning up, now digging"
              @action = :dig
            elsif action == :dig
              log "done clearing, now placing"
              @action = :place
            else
              log "all done! #{Time.now.to_s} - took #{(Time.now - @start_time)} seconds"
              @done = true
            end
          end

        else

          10.times do
            break if actions.empty?
            action, coords = actions.shift
            case action
            when :dig
              if @falling_columns[[coords[0], coords[2]]]
                log "dig #{coords[0]} #{coords[1]} #{coords[2]} (skipped, unsafe)"
              else
                above = coords.dup
                above[1] += 1
                if [13, 14].include?(map[*above])
                  @falling_columns[[coords[0], coords[2]]] = Time.now.to_i
                  log "dig #{coords[0]} #{coords[1]} #{coords[2]} (unsafe)"
                else
                  log "dig #{coords[0]} #{coords[1]} #{coords[2]}"
                end
                dig(*coords)
              end

            when :place
              log "place #{coords[0]} #{coords[1]} #{coords[2]} #{coords[3]}"
              place(*coords)
            when :move
              @last_move = coords
              if @falling_columns[[coords[0], coords[2]]]
                log "move #{coords[0]} #{coords[1]} #{coords[2]} (skipped, unsafe)"
                actions.clear # skipping unsafe moves invalidates all subsequent pathfinding
                break
              else
                log "move #{coords[0]} #{coords[1]} #{coords[2]}"
                move_to(*coords)
              end
            when :path # move this path, then stop for this tick (for pickups)
              coords.each do |where|
                log "move #{where[0]} #{where[1]} #{where[2]}"
                move_to(*where)
              end
              break
            when :empty_inventory
              send_empty_inventory
            end
          end

        end
      end

      def update(packet)
        case packet.class.kind
        when :player_move_look
          where = [packet.x, packet.y, packet.z]
          log "moved incorrectly, stopping: #{@last_move.inspect} --> #{where.inspect}"
          @done = true
        when :pickup_spawn
          pos = [packet.x, packet.y, packet.z]
          if blueprint.includes?(*pos.map { |v| v / 32 })
            pickups[packet.id] = pos
          end
        when :entity_move
          if pos = pickups[packet.id]
            deltas = [packet.x, packet.y, packet.z]
            pickups[packet.id] = pos.map.with_index { |v, i| v + deltas[i] }
          end
        when :entity_teleport
          if pos = pickups[packet.id]
            pickups[packet.id] = [packet.x, packet.y, packet.z]
          end
        when :destroy_entity
          pickups.delete packet.id
        when :add_to_inventory
          send_empty_inventory
        end
      end

      def done?
        @done
      end

      protected

      def next_actions
        if action == :cleanup
          cleanup_actions
        elsif action == :dig
          dig_actions
        else
          place_actions
        end
      end

      def cleanup_actions
        locations = pickups.values.map { |pos| pos.map { |v| v / 32 } }.uniq
        locations.delete state.coords # move somewhere other than here, always

        begin
          path_to_nearest = Timeout.timeout(5) { map.path(state.coords, locations, :move_to, @falling_columns) }
        rescue Timeout::Error
          log "no path!"
          path_to_nearest = nil
        end

        return path_to_nearest ? [[:path, path_to_nearest]] : []
      end

      def dig_actions
        if pickups.size >= 200
          log "time to clean up!"
          @action = :cleanup
          return [[:empty_inventory, nil]]
        end

        survey = next_changes

        next_actions = []
        current = state.coords

        until survey.empty? || next_actions.size >= 100
          begin
            path_to_nearest = Timeout.timeout(10) { map.path(current, survey.keys, :next_to, @falling_columns) }
          rescue Timeout::Error
            path_to_nearest = nil
          end

          break unless path_to_nearest

          path_to_nearest.each { |p| next_actions << [:move, p] }
          current = path_to_nearest.last || current

          map.available(*current, :build).each do |check|
            if survey[check]
              next_actions << [:dig, check]
              survey.delete check
            end
          end
        end

        next_actions
      end

      def place_actions
        survey = next_changes

        next_actions = []
        current = state.coords

        # if we're standing somewhere that needs to change, get out of the way
        if survey[current] || survey[[current[0], current[1] + 1, current[2]]]
          log "moving out of the way, gotta put blocks here..."
          begin
            path_to_nearest = Timeout.timeout(10) { map.path(current, survey.keys, :away_from, @falling_columns) }
          rescue Timeout::Error
            log "hmm, couldn't move? i might be stuck!"
            path_to_nearest = nil
          end

          if path_to_nearest
            log "path: #{path_to_nearest.inspect}"
            path_to_nearest.each { |p| next_actions << [:move, p] }
          else
            log "wtf? couldn't move out of the way..."
          end
        end

        until survey.empty? || next_actions.size >= 1000
          position, change = survey.shift
          block = change[1]
          next_actions << [:place, position + [block]]
        end

        next_actions
      end

      def expire_falling_columns
        now = Time.now.to_i
        @falling_columns.keys.select { |k| now - @falling_columns[k] > 10 }.map do |key|
          @falling_columns.delete key
        end
      end

      def next_changes
        survey = blueprint.survey_coords(map, action == :dig ? :top_down : :bottom_up, state.coords, 8)
        survey = changes_from_survey(survey)

        if survey.empty?
          log "using larger survey"
          survey = blueprint.survey_coords(map, action == :dig ? :top_down : :bottom_up, state.coords, 16)
          survey = changes_from_survey(survey)
        end

        if survey.empty?
          log "using full survey"
          survey = blueprint.survey_coords(map, action == :dig ? :top_down : :bottom_up)
          survey = changes_from_survey(survey)
        end

        survey
      end

      def changes_from_survey(survey)
        survey.delete_if do |position, change|
          needs_change = action == :dig ? needs_clearing?(position, change) : needs_placement?(position, change)
          !needs_change || !map.available(*position, :next_to).any? { |l| map.allowed?(*l) }
        end
      end

      def needs_clearing?(position, change)
        from, to = change
        air = CODES[:air]
        lava, still_lava = CODES[:lava], CODES[:still_lava]
        SOLID.include?(from) && (SOLID.include?(to) || to == air) && ![lava, still_lava].include?(from)
      end

      def needs_placement?(position, change)
        from, to = change
        air = CODES[:air]
        lava, still_lava = CODES[:lava], CODES[:still_lava]
        water, still_water = CODES[:water], CODES[:still_water]
        [water, still_water, lava, still_lava, air].include?(from) && SOLID.include?(to)
      end

      def send_empty_inventory
        # tell the server we have all the tools, but plenty of room for picking up things we just dug
        send_packet :player_inventory, [-3, [nil, nil, nil, nil]]
        send_packet :player_inventory, [-2, [nil, nil, nil, nil]]
        send_packet :player_inventory, [-1, [
          # main inventory slots:
          [276, 1, 1], # sword
          [277, 1, 1], # spade
          [278, 1, 1], # pickaxe
          [279, 1, 1], # axe
          nil, nil, nil, nil,
          [345, 1, 0], # compass

          nil, nil, nil, nil, nil, nil, nil, nil, nil,
          nil, nil, nil, nil, nil, nil, nil, nil, nil,
          nil, nil, nil, nil, nil, nil, nil, nil, nil
        ]]
      end

    end
  end
end
