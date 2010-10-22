module Golem
  class Session

    def self.start(host, port_or_options = {})
      port = 25565
      if Hash === port_or_options
        port = port_or_options[:port] || port
      else
        port = port_or_options
      end

      EM.run do

        EM.epoll
        trap("INT") { EM.stop }
        trap("TERM") { EM.stop }

        client = EventMachine.connect host, port, Client, port_or_options
        console = EM.attach STDIN, Console, client
      end
    end

  end
end
