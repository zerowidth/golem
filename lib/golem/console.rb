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
        if args.size == 3
          x, y, z = args.map(&:to_i)
          client.dig(x, y, z)
        else
          puts "dig <x> <y> <z>"
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

      when "here"
        if player = args.first
          client.come_to(player)
        else
          puts "here <player> -- move to where the player is"
        end

      when "follow"
        if player = args.first
          client.follow(player)
        else
          puts "follow <player>"
        end

      when "loadout"
        # tell the server that we have all the tools, and we're full of dirt too so we can't
        # pick anything else up.

        client.send_packet :player_inventory, [-3, [nil, nil, nil, nil]]
        client.send_packet :player_inventory, [-2, [nil, nil, nil, nil]]
        client.send_packet :player_inventory, [-1, [
          # main inventory slots:
          [276, 1, 1], # sword
          [277, 1, 1], # spade
          [278, 1, 1], # pickaxe
          [279, 1, 1], # axe
          [3, 64, 0],
          [3, 64, 0],
          [3, 64, 0],
          [3, 64, 0],
          [345, 1, 0], # compass

          # full of dirt!
          [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0],
          [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0],
          [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0],
        ]]

      when "empty"
        client.send_empty_inventory
      when "survey"
        if blueprint = args.shift
          if args.size == 3
            x, y, z = args.map(&:to_i)
            client.survey(blueprint, [x, y, z])
          elsif !args.empty?
            puts "survey <blueprint> [x y z]"
          else
            client.survey(blueprint)
          end
        else
          puts "survey <blueprint> [x y z]"
        end

      when "build"
        if blueprint = args.shift
          if args.size == 3
            x, y, z = args.map(&:to_i)
            client.build(blueprint, [x, y, z])
          elsif !args.empty?
            puts "build <blueprint> [x y z]"
          else
            client.build(blueprint)
          end
        else
          puts "build <blueprint> [x y z]"
        end

        else
          puts "build <blueprint>"
        end

      when "digtest"
        client.action Actions::DigTest

      else
        puts "unrecognized"
      end
    end
  end
end
