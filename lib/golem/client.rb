module Golem
  class Client < ::EventMachine::Connection

    def self.run(host, port = 25565)
      EventMachine.run do
        EventMachine.connect host, port, self
      end
    end

    attr_reader :parser, :state

    def send_packet(packet)
      if packet == :disconnect
        close_connection
        EventMachine.stop_event_loop
        log "disconnecting"
      else
        log "<-- #{packet.inspect}"
        send_data packet.encode
      end
    end

    def post_init
      @parser = Parser.new
      @state = State.new
      send_response_data
    rescue => e
      puts e.inspect
      puts e.backtrace
      raise
    end

    def receive_data(data)
      parser.parse(data).each do |packet|
        log "--> #{packet.inspect}"
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

    def log(msg)
      puts Time.now.strftime("%F %H:%M:%S.%3N ") << msg
    end

  end
end
