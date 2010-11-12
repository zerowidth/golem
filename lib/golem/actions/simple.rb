module Golem
  module Actions

    # simple action that to wrap up a basic helper method,
    # e.g. equip or look_at
    class Simple < Action
      def setup(method_name, *args)
        case method_name
        when :position
          if state.position.x
            puts "current position: #{state.coords.inspect} #{state.position.inspect}"
          else
            puts "no position yet?"
          end

        when :block
          x, y, z = args
          puts "block at #{args.inspect}: #{BLOCKS[map[x, y, z]]}"

        when :move
          x, y, z = args
          puts "moving to #{args.inspect}"
          state.move_to x, y, z
          send_move_look

        when :path
          x, y, z = args
          puts "path to #{args.inspect}:"
          path = map.path(state.coords, [x, y, z])
          if path
            path.each { |p| puts "  #{p.inspect}" }
          else
            puts "no path found :("
          end

        when :dig
          x, y, z = args
          block = BLOCKS[map[x,y,z]]
          puts "digging #{block} at #{[x, y, z].inspect}"
          dig x, y, z

        when :place
          x, y, z, code = args
          block = BLOCKS[code]
          puts "placing #{block} at #{[x,y,z].inspect}"
          place x, y, z, code

        else

          if respond_to?(method_name)
            send method_name, *args
          else
            log "unknown simple command #{method_name}"
          end

        end
      rescue => e
        STDERR.puts e.inspect
        e.backtrace.each { |l| STDERR.puts l }
        STDERR.puts "continuing..."
      end
    end

  end
end
