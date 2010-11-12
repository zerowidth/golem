module Golem
  class Client < EM::Connection

    def self.proxy(host, port, server_host, server_port)
      EM.run do
        puts "listening for connection on #{host}:#{port}"
        EM.start_server(host, port, self, server_host, server_port)
        trap("TERM") { EM.stop }
        trap("INT")  { EM.stop }
      end
    end

    attr_reader :proxy
    attr_reader :server_host, :server_port

    def initialize(server_host, server_port)
      puts "initializing client"
      @server_host, @server_port = server_host, server_port
      @proxy = EM.connect(server_host, server_port, Proxy, self)
    end

    def post_init
      puts "got connection from client, proxying to #{server_host}:#{server_port}"
      EM.attach STDIN, Console, proxy
    end

    def receive_data(data)
      proxy.from_client(data)
    end

    def unbind
      puts "client closed connection, shutting down"
      EM.stop
    end

  end
end
