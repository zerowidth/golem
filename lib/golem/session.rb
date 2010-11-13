module Golem
  class Session < EM::Connection

    attr_reader :state
    attr_reader :server_parser
    attr_reader :current_action

    def initialize(*args)
      @state = State.new
      @server_parser = Parser.new
    rescue => e
      STDERR.puts e.inspect
      EM.stop
      raise
    end

    # receive data from the server
    def receive_data(data)
      @server_parser.parse(data).each do |packet|
        debug "server --> #{packet.inspect}"
        state.update packet
        handle packet

        if current_action
          current_action.update(packet)
          send_pending_action_packets
        end
      end
    rescue => e
      STDERR.puts e.inspect
      EM.stop
      raise
    end

    def handle(packet)
      # implement me in subclasses!
    end

    def unbind
      puts "connection lost, shutting down"
      EM.stop
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

    def action(action_class, *args)
      @current_action = action_class.new(state, map)
      current_action.setup(*args)
      send_pending_action_packets
    end

    def stop
      @current_action = nil
    end

    def send_client_packet(kind, *values)
      packet_class = Packet.client_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new(*values)
      debug "<-- server #{packet.inspect}"
      send_data packet.encode
    end

    def map
      state.map
    end

    def current_action_tick
      if current_action
        if current_action.done?
          @current_action = nil
        else
          current_action.tick
          send_pending_action_packets
        end
      end
    end

    def send_pending_action_packets
      current_action.packets do |type, values|
        send_client_packet(type, *values)
      end
    end

    def say(msg)
      action Actions::Simple, :say, msg
    end

    def position
      action Actions::Simple, :position
    end

    def block_at(x, y, z)
      action Actions::Simple, :block, x, y, z
    end

    def move_to(x, y, z)
      action Actions::Simple, :move, x, y, z
    end

    def path_to(x, y, z)
      action Actions::Simple, :path, x, y, z
    end

    def dig(x, y, z)
      action Actions::Simple, :dig, x, y, z
    end

    def equip(code)
      action Actions::Simple, :equip, code
    end

    def place(x, y, z, code)
      action Actions::Simple, :place, x, y, z, code
    end

    def watch(player_name)
      action Actions::Watch, player_name
    end

    def come_to(player_name)
      action Actions::Come, player_name
    end

    def follow(player_name)
      action Actions::Follow, player_name
    end

    def survey(blueprint, center = nil)
      where = center || state.coords
      action Actions::Survey, blueprint, where
    end

    def build(blueprint, center = nil)
      where = center || coords
      action Actions::Build, blueprint, where
    end

  end
end
