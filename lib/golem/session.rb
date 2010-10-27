module Golem
  class Session

    def self.start(host, port, opts={})
      puts "connecting to #{host}:#{port}"
      EM.run do
        EM.epoll
        trap("INT") { EM.stop }
        trap("TERM") { EM.stop }
        client = EventMachine.connect host, port, Client, opts
        console = EM.attach STDIN, Console, client
      end
    end

  end
end
