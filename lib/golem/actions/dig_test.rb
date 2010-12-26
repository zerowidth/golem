module Golem
  module Actions
    class DigTest < Action

      attr_reader :test_blocks, :counts, :current_block, :pos

      def setup
        @test_blocks = SOLID.dup
        [ :bedrock,
          :lava, :still_lava, :fire,
          :mob_spawner,
          :tnt, # hoo boy that was a fun mistake
          :wood_door, :iron_door, # buggy in SMP?
          :snow, # need to improve look_at code for this to work
          :cactus # requires special placement
        ].each do |skip|
          test_blocks.delete CODES[skip]
        end

        next_block
        @action = :place

        @counts = Hash.new(0)

        @pos = state.coords
        pos[0] += 1

      end

      def done?
        test_blocks.empty? && !current_block[0]
      end

      def dig(count)
        x, y, z = pos
        equip map.tool_for(x, y, z)

        send_packet :block_dig, 0, x, y, z, 4
        # send_packet :arm_animation, 0, true

        count.times do
          send_packet :block_dig, 1, x, y, z, 4
        end

        send_packet :block_dig, 3, x, y, z, 4
        send_packet :block_dig, 2, 0, 0, 0, 0
      end

      def place(block)
        equip block
        x, y, z = pos
        send_packet :place, block, x, y - 1, z, 1
        sleep 0.1
      end

      def next_block
        @current_block = [@test_blocks.shift, 1, 3000]
      end

      def tick
        x, y, z = pos

        case @action
        when :place
          block = current_block[0]
          log "placing #{block}"

          place block

          @action = :dig

          state.look_at(*pos)
          send_look

        when :dig
          return if !SOLID.include?(map[x, y, z])

          block, min, max = current_block
          n = (max - min) / 2 + min
          print "  #{n}"
          dig n

          @wait = 0
          @action = :wait

        when :wait
          @wait += 1
          print "."
          if @wait == 2
            print " "
            @action = :test
          end

        when :test
          block, min, max = current_block

          if map[*pos] == CODES[:air]
            if max - min <= 1
              log "broke at #{max}"
              next_block
              @action = :place
            else
              current_block[2] = (max - min) / 2 + min
              log ":)"
              place block
              @action = :dig
            end
          else
            if max - min <= 1
              log "broke at #{max}"
              dig 3000
              next_block
              @action = :place
            else
              current_block[1] = (max - min) / 2 + min
              log ":("
              @action = :dig
            end
          end

        end
      end

    end
  end
end
