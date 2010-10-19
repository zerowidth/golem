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
