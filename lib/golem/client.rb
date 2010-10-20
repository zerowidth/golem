module Golem
  class Client < ::EventMachine::Connection

    attr_reader :parser, :state

    def initialize
      @state = State.new
    end

    def send_packet(packet)
      if packet == :disconnect
        close_connection
      else
        debug "<-- client  #{packet.inspect}"
        send_data packet.encode
      end
    end

    def post_init
      @parser = Parser.new
      puts "client connected"
      send_response_data
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
      send_response_data
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise
    end

    def send_response_data
      state.respond do |packet|
        if Symbol === :packet || packet.wait == 0
          send_packet packet
        else
          EM.add_timer(packet.wait) { send_packet packet }
        end
      end
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

    def master_position
      state.master_position
    end

    def move_to(x, y, z)
      state.move(x, y, z)
    end

    def block_at(x, y, z)
      state.block_at(x, y, z)
    end

    def adjacent
      state.adjacent
    end

    def path_to(x, y, z)
      state.path_to(x, y, z)
    end

  end
end
