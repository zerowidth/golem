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
          test_blocks.delete skip
        end

        next_block
        @state = :place

        @counts = Hash.new(0)

        @pos = client.coords
        pos[0] += 1

      end

      def done?
        test_blocks.empty? && !current_block[0]
      end

      def dig(count)
        x, y, z = pos
        client.equip map.tool_for(x, y, z)

        client.send_packet :block_dig, 0, x, y, z, 4
        client.send_packet :arm_animation, 0, true

        count.times do
          client.send_packet :block_dig, 1, x, y, z, 4
        end

        client.send_packet :block_dig, 3, x, y, z, 4
        client.send_packet :block_dig, 2, 0, 0, 0, 0
      end

      def place(block)
        code = BLOCKS.detect {|c, name| name == block}[0]
        client.equip code
        x, y, z = pos
        client.send_packet :place, code, x, y - 1, z, 1
        sleep 0.1
      end

      def next_block
        @current_block = [@test_blocks.shift, 1, 3000]
      end

      def tick
        x, y, z = pos

        case @state
        when :place
          block = current_block[0]
          puts "placing #{block}"

          place block

          @state = :dig

          client.look_at(*pos)
          client.send_look

        when :dig
          return if !SOLID.include?(map[x, y, z])

          block, min, max = current_block
          n = (max - min) / 2 + min
          print "  #{n}"
          dig n

          @wait = 0
          @state = :wait

        when :wait
          @wait += 1
          print "."
          if @wait == 2
            print " "
            @state = :test
          end

        when :test
          block, min, max = current_block

          if map[*pos] == :air
            if max - min <= 1
              puts "broke at #{max}"
              next_block
              @state = :place
            else
              current_block[2] = (max - min) / 2 + min
              puts ":)"
              place block
              @state = :dig
            end
          else
            if max - min <= 1
              puts "broke at #{max}"
              dig 3000
              next_block
              @state = :place
            else
              current_block[1] = (max - min) / 2 + min
              puts ":("
              @state = :dig
            end
          end

        end
      end

    end
  end
end
