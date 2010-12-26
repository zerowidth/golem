module Golem
  class Proxy < Session

    attr_reader :client
    attr_reader :client_parser
    attr_reader :reset_timer, :needs_reset
    attr_reader :nohands, :hide, :fastdig

    def initialize(client)
      super
      @client = client
    end

    def post_init
      @client_parser = Parser.new(false)
      @time = nil
      @nohands = false
      @needs_reset = false
      @hide = false
      @fastdig = false

      EM.add_periodic_timer(0.1) do
        if needs_reset
          reset_client_position
          @needs_reset = false
        end
      end

      EM.add_periodic_timer(0.25) do
        next unless current_action
        if hide?
          if state.players.size > 0
            if nohands?
              log "hiding from #{state.players.keys.join(", ")}"
              @nohands = false
            end
          elsif state.players.size == 0
            if nohands?
              current_action_tick
            else
              log "all clear, back to work!"
              @nohands = true
            end
          end
        else
          current_action_tick
        end
      end
    end

    alias :nohands? :nohands
    alias :hide? :hide
    alias :fastdig? :fastdig

    def handle(packet)
      if packet.kind == :update_time && @time
        send_server_packet :update_time, @time
      elsif packet.kind == :add_to_inventory && nohands? && current_action && !current_action.done?
        if COMMON.include?(packet.type)
          # ignore it, let the proxy swallow inventory adds while e.g. building
        else
          client.send_data packet.raw
        end
      elsif packet.kind == :player_health && packet.half_hearts < 20
        log "health set to #{packet.half_hearts * 0.5} hearts, using golden apple"
        send_client_packet :block_item_switch, 0, 322
        send_client_packet :place, 322, -1, -1, -1, -1
        client.send_data packet.raw
      else
        client.send_data packet.raw
      end
    end

    def from_client(data)
      client_parser.parse(data).each do |packet|
        debug "client  --> #{packet.inspect}"
        if packet.kind == :chat
          send_data packet.raw unless proxy_command(packet.message)
        elsif nohands?
          intercept_client_packet packet
        elsif fastdig? && packet.kind == :block_dig && packet.status == 1
          block = map[packet.x, packet.y, packet.z]
          if digs = DIGS[block] && tool = TOOLS.keys.detect { |k| TOOLS[k].include? block }
            # send_client_packet :block_item_switch, 0, tool
            digs.times { send_data packet.raw }
            send_client_packet :block_dig, 3, packet.x, packet.y, packet.z, packet.direction
          end
        else
          state.update packet
          send_data packet.raw
        end
      end
    end

    def intercept_client_packet(packet)
      case packet.kind
      when :player_position, :player_move_look
        @needs_reset = true
      when :player_look
        # ignore
      else
        send_data packet.raw # let it through
      end
    end

    def proxy_command(message)
      case message
      when /\/time (\d+|dawn|sunrise|dusk|sunset|noon|midnight|server)/
        case $1
        when "dawn", "sunrise"
          @time = 23000
        when "dusk", "sunset"
          @time = 13000
        when "noon"
          @time = 6000
        when "midnight"
          @time = 18000
        when "server"
          @time = nil
        else
          @time = $1.to_i
        end
        tell_client "setting time to #{$1}"
      when /\/(where|gps)/
        tell_client "current coords: #{state.coords.inspect}"
      when /\/nohands/
        @nohands = true
        tell_client "no hands!"
      when /\/me/
        @nohands = false
        tell_client "back in control"
      when /\/hide/
        tell_client "working in secret"
        @hide = true
      when /\/nohide/
        tell_client "working in public"
        @hide = false
      when /\/(fastdig|fd)/
        tell_client "fast digging enabled"
        @fastdig = true
      when /\/(nofastdig|nofd)/
        tell_client "fast digging disabled"
        @fastdig = false
      when /\/stop/
        clear_current_action
      else
        return false
      end
      true
    end

    def action(*args)
      @nohands = true
      super
    end

    def clear_current_action
      super
      @nohands = false
    end

    def send_pending_action_packets
      current_action.packets do |type, values|
        case type
        when :player_move_look
          reset_client_position
        end
        send_client_packet(type, *values)
      end
    end

    def tell_client(msg)
      send_server_packet :chat, "<proxy> #{msg}"
    end

    def fly_to(x, y, z)
      action Actions::FlyTo, x, y, z
    end

    def reset_client_position
      pos = state.position
      send_server_packet :player_position, pos.x, pos.stance, pos.y, pos.z, pos.flying
    end

    def send_server_packet(kind, *values)
      packet_class = Packet.server_packets_by_kind[kind] or raise ArgumentError, "unknown packet type #{kind.inspect}"
      packet = packet_class.new(*values)
      debug "<-- client  #{packet.inspect}"
      client.send_data packet.encode
    end

  end
end
