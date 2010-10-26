module Golem
  class Client < ::EventMachine::Connection

    attr_reader :parser, :state, :packet_channel

    def initialize(opts={})
      @packet_channel = EM::Channel.new
      @state = State.new @packet_channel, opts
    end

    def post_init
      @parser = Parser.new
      puts "client connected"

      packet_channel.subscribe do |packet|
        debug "<-- client  #{packet.inspect}"
        send_data packet.encode
      end

    rescue => e
      puts e.inspect
      puts e.backtrace
      raise
    end

    def unbind
      puts "client disconnected"
      EM.stop
    end

    def receive_data(data)
      parser.parse(data).each do |packet|
        debug "server --> #{packet.inspect}"
        state.update(packet)
      end
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise
    end

    attr_reader :debug_pattern
    def debug_pattern=(pattern)
      @debug_pattern = pattern ? Regexp.new(pattern) : nil
    rescue RegexpError => e
      log "invalid regex: #{e.message}: #{pattern.inspect}"
    end

    def debug(msg)
      log msg if debug_pattern && msg =~ debug_pattern
    end

    def log(msg)
      puts Time.now.strftime("%F %H:%M:%S.%3N ") << msg
    end

    # delegators

    def position
      state.position
    end

    # def move_to(x, y, z)
    #   state.move_to(x, y, z)
    # end

    def block_at(x, y, z)
      state.block_at(x, y, z)
    end

    def adjacent
      state.adjacent
    end

    def path_to(x, y, z)
      state.path_to(x, y, z)
    end

    def follow(flag)
      state.follow_mode = flag ? :follow : :watch
    end

    def follow_position
      state.follow_position
    end

    def equip(code)
      state.equip(code.to_i)
    end

    def dig(x, y, z, direction)
      state.dig(x, y, z, direction)
    end

    def place(x, y, z, code)
      state.place(x, y, z, code)
    end

    def say(msg)
      state.say(msg)
    end

  end
end
