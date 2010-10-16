module Golem
  class Proxy

    def self.start(host, port, server_host, server_port=25565)
      EM.epoll
      EM.run do
        EM.start_server(host, port, Interceptor, server_host, server_port)

        trap("TERM") { stop }
        trap("INT")  { stop }
      end
    end

    def self.stop
      puts "shutting down"
      EM.stop
    end

  end
end
