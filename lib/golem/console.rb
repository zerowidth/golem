module Golem
  module Console

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def post_init
      puts "console ready"
    end

    def unbind
      puts "console stopping"
    end

    def receive_data(data)
      command, args = data.strip.split(/\s+/, 2)
      case command
      when "p", "pos", "position"
        puts "golem position: #{client.position.inspect}"
      when "q", "quit", "exit"
        EM.stop
        return

      when "m", "move"
        x, y, z = args.split(" ").map(&:to_i)

        unless x && y && z
          puts "usage: move <x> <y> <z> (integers)"
          return
        end

        # move to center of block
        client.move_to x + 0.5, y, z + 0.5

      when "b", "block"
        x, y, z = args.split(" ").map(&:to_i)
        unless x && y && z
          puts "usage: move <x> <y> <z> (integers)"
          return
        end

        puts "block at #{[x, y, z].inspect}: #{client.block_at(x, y, z).inspect}"

      when "d", "debug"
        if !args || args.strip.empty?
          puts "usage: debug off|all|server|client|<regex>"
          return
        end

        if args.split(" ").first == "off"
          client.debug_pattern = nil
        elsif args == "all"
          client.debug_pattern = "."
        else
          client.debug_pattern = args
        end
      else
        puts "unrecognized"
      end
    end
  end
end
