module Golem
  module Console

    attr_reader :client

    def initialize(client)
      @client = client
    end

    # def post_init
    #   puts "console ready"
    # end

    # def unbind
    #   puts "console stopping"
    # end

    def receive_data(data)
      command, args = data.strip.split(/\s+/, 2)
      args = (args || "").split(/\s+/)

      case command

      # control commands

      when "q", "quit", "exit"
        EM.stop
        return

      when "d", "debug"
        if args.first == "off"
          client.debug_pattern = nil
        elsif args.first == "all"
          client.debug_pattern = "."
        else
          client.debug_pattern = args.first
        end

      when "c", "command"
        puts "current command: #{client.current_action.class}"

      when "stop"
        client.stop

      # simple / debugging commands

      when "p", "pos", "position"
        if pos = client.position
          puts "position: #{client.coords.inspect} #{pos.inspect}"
        else
          puts "no position yet?"
        end

      when "m", "move"
        if args.size == 3
          x, y, z = args.map(&:to_i)
          client.move_to(x, y, z)
        else
          puts "move x y z"
        end

      when "path"
        if args.size == 3
          x, y, z = args.map(&:to_i)

          puts "path from #{client.coords.inspect} to #{[x, y, z].inspect}:"

          if path = client.path_to(x, y, z)
            path.each {|p| puts "  #{p.inspect}" }
          else
            puts "  no path found"
          end

        else
          puts "path x y z"
        end

        puts "path from #{[p.x.floor, p.y, p.z.floor].map(&:to_i).inspect} to #{[x, y, z].inspect}:"

      when "b", "block"
        if args.size == 3
          x, y, z = args.map(&:to_i)
          puts "block at #{[x, y, z].inspect}: #{client.block_at(x, y, z).inspect}"
        else
          puts "block x y z"
        end

      when "y", "say"
        if args.empty?
          puts "say <message>"
        else
          client.say args.join(" ")
        end

      when "dig"
        if args.size == 3 || args.size == 4
          x, y, z, direction = args.map(&:to_i)
          direction ||= 0
          client.dig(x, y, z, direction)
        else
          puts "dig <x> <y> <z> [direction = 0]"
        end

      when "e", "equip"
        if args.empty?
          puts "equip <item code>"
        else
          client.equip args.first.to_i
        end

      when "x", "place"
        if args.size == 4
          x, y, z, code = args.map(&:to_i)
          client.place x, y, z, code
        else
          puts "place <x> <y> <z> <code>"
        end

      # complex commands:

      when "watch"
        if player = args.first
          client.watch(player)
        else
          puts "watch <player>"
        end

      when "follow"
        if player = args.first
          client.follow(player)
        else
          puts "follow <player>"
        end

      else
        puts "unrecognized"
      end
    end
  end
end
