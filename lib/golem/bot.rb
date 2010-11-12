module Golem
  class Bot < Session

    def self.start(host, port)
      EM.run do
        session = EM.connect(host, port, self)
        console = EM.attach STDIN, Console, session
        trap("TERM") { EM.stop }
        trap("INT")  { EM.stop }
      end
    end

    def post_init
      send_client_packet :handshake, "golem"
    rescue => e
      STDERR.puts e.inspect
      EM.stop
      raise
    end

    def handle(packet)
      case packet.kind

      when :server_handshake
        send_client_packet :login, 4, "golem", "Password"
        9.times { send_client_packet :keepalive }

        # keepalive
        EM.add_periodic_timer(1) { send_client_packet :flying_ack, state.flying if state.position.x }
        EM.add_periodic_timer(10) { send_client_packet :keepalive }

        # general action proessing
        EM.add_periodic_timer(0.25) do
          current_action_tick
        end

      when :disconnect
        EM.stop

      when :chat
        log packet.message

      when :player_move_look
        # verify our position with the server
        send_client_packet(:player_move_look, *state.move_look_values)

      when :multi_block_change
        send_client_packet :flying_ack, state.flying

      end

    end

    def disconnect
      send_client_packet :disconnect, "Quitting"
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
