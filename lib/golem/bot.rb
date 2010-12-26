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

      when :handshake
        send_client_packet :login, Packets::PROTOCOL_VERSION, "golem", "Password"
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

      when :map_chunk
        send_client_packet :flying_ack, state.flying

      end

    end

    def disconnect
      send_client_packet :disconnect, "Quitting"
    end

  end
end
