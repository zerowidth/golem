module Golem
  module Console

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def receive_data(data)
      command, args = data.strip.split(/\s+/, 2)
      args = (args || "").split(/\s+/)

      case command

      when "q", "quit", "exit"
        if client.respond_to?(:disconnect)
          client.disconnect
        else
          EM.stop
        end
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

      when "p", "pos", "position"
        client.position

      when "m", "move"
        if args.size == 3
          x, y, z = args.map(&:to_i)
          client.move_to(x, y, z)
        else
          puts "move x y z"
        end

      when "fly"
        if args.size == 3
          x, y, z = args.map(&:to_i)
          client.fly_to(x, y, z)
        else
          puts "fly x y z"
        end

      when "path"
        if args.size == 3
          x, y, z = args.map(&:to_i)
          client.path_to(x, y, z)
        else
          puts "path x y z"
        end

      when "b", "block"
        if args.size == 3
          x, y, z = args.map(&:to_i)
          client.block_at(x, y, z)
        else
          puts "block x y z"
        end

      when "chunks"
        client.number_of_chunks

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
          client.equip(args.first.to_i)
        end

      when "x", "place"
        if args.size == 4
          x, y, z, code = args.map(&:to_i)
          client.place x, y, z, code
        else
          puts "place <x> <y> <z> <code>"
        end

      when "drop"
        if args.size > 0
          code, count = args.map(&:to_i)
          count ||= 1
          client.drop code, count
        else
          puts "drop <code> [count=1]"
        end

      when "watch"
        if player = args.first
          client.watch(player)
        else
          puts "watch <player>"
        end

      when "come"
        if player = args.first
          client.come_to(player)
        else
          puts "come <player> -- move to where the player is"
        end

      when "follow"
        if player = args.first
          client.follow(player)
        else
          puts "follow <player>"
        end

      # when "loadout"
      #   # tell the server that we have all the tools, and we're full of dirt too so we can't
      #   # pick anything else up.

      #   client.send_packet :player_inventory, [-3, [nil, nil, nil, nil]]
      #   client.send_packet :player_inventory, [-2, [nil, nil, nil, nil]]
      #   client.send_packet :player_inventory, [-1, [
      #     # main inventory slots:
      #     [276, 1, 1], # sword
      #     [277, 1, 1], # spade
      #     [278, 1, 1], # pickaxe
      #     [279, 1, 1], # axe
      #     [3, 64, 0],
      #     [3, 64, 0],
      #     [3, 64, 0],
      #     [3, 64, 0],
      #     [345, 1, 0], # compass

      #     # full of dirt!
      #     [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0],
      #     [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0],
      #     [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0], [3, 64, 0],
      #   ]]

      # when "empty"
      #   client.send_empty_inventory

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

      when "digtest"
        client.action Actions::DigTest

      when "players"
        client.list_players

      when "nearest"
        if block = args.shift
          if code = CODES[block.to_sym]
            puts "nearest #{block} to #{client.coords.inspect}:"
            client.nearest(code).each { |p| puts "  #{p.inspect}" }
          else
            puts "block #{block} not recognized"
          end
        else
          puts "nearest <block type>"
        end

      else
        puts "unrecognized"
      end
    end
  end
end
