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
      args ||= ""
      case command
      when "p", "pos", "position"
        puts "position: #{client.position.inspect}"
      when "q", "quit", "exit"
        EM.stop
        return

      when "m", "move"
        x, y, z = args.split(" ").map(&:to_i)

        unless x && y
          puts "usage: move <x> <y> <z> (integers)"
          return
        end

        # move to center of block
        if z
          client.move_to x + 0.5, y, z + 0.5
        else
          client.move_to x + 0.5, client.position.y, y + 0.5
        end

      when "b", "block"
        x, y, z = args.split(" ").map(&:to_i)
        unless x && y && z
          puts "usage: move <x> <y> <z> (integers)"
          return
        end

        puts "block at #{[x, y, z].inspect}: #{client.block_at(x, y, z).inspect}"

      when "p", "path"
        x, y, z = args.split(" ").map(&:to_i)
        unless x && y && z
          puts "usage: move <x> <y> <z> (integers)"
          return
        end
        p = client.position

        puts "path from #{[p.x.floor, p.y, p.z.floor].map(&:to_i).inspect} to #{[x, y, z].inspect}:"
        if path = client.path_to(x, y, z)
          puts "path:"
          path.each {|p| puts "  #{p.inspect}" }
        else
          puts "no path found"
        end

      when "come"
        p = client.position
        m = client.master_position
        x, y, z = m[0].to_i, m[1].to_i, m[2].to_i

        puts "path from #{[p.x.floor, p.y, p.z.floor].map(&:to_i).inspect} to #{[x, y, z].inspect}:"

        if path = client.path_to(x, y, z)
          puts "path:"
          path.each {|p| puts "  #{p.inspect}" }
        else
          puts "no path found"
        end

      when "a", "adjacent"
        p = client.position
        m = client.master_position

        puts "position: #{[p.x.floor, p.y, p.z.floor].inspect}"
        if m && m[0]
          puts "master  : #{[m[0].floor, m[1], m[2].floor].inspect}"
        else
          puts "no master :("
        end
        puts "adjacent locations:"
        client.adjacent.each {|a| puts "  - #{a.inspect}" }

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
