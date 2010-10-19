module Golem
  class Session

    def self.start(host, port=25565)
      EM.run do

        EM.epoll
        trap("INT") { EM.stop }
        trap("TERM") { EM.stop }

        client = EventMachine.connect host, port, Client
        console = EM.attach STDIN, Console, client
      end
    end

  end
end
