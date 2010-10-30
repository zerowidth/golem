module Golem
  class Action

    attr_reader :client, :map

    def initialize(client, map)
      @client, @map = client, map
    end

    # for setting up the command
    def setup(*args)
    end

    # called any time the client receives a packet
    def update(packet)
    end

    # called periodically
    def tick
    end

    # is the command done and can it be cleared?
    def done?
      true
    end

  end
end
