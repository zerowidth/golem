module Golem
  class Action

    attr_reader :state, :map

    def initialize(state, map)
      @state, @map = state, map
      @packets = []
    end

    # for setting up the command, if required
    def setup(*args)
      # reimplement in subclasses
    end

    # called any time the client receives a packet
    def update(packet)
      # reimplement in subclasses
    end

    # called repeatedly at intervals until done? is true
    def tick
      # reimplement in subclasses
    end

    # called at intervals to get the list of packets to send
    def packets
      while @packets.size > 0
        yield @packets.shift
      end
    end

    # is the command done and can it be cleared?
    def done?
      true # reimplement in subclasses
    end

    protected

    # convenience method to queue up packets that need to be sent
    def send_packet(type, *values)
      @packets << [type, values]
    end

    def send_look
      send_packet :player_look, *state.look_values
    end

    def send_move_look
      send_packet :player_move_look, *state.move_look_values
    end

    def say(msg)
      send_packet :chat, msg
    end

    def move_to(x, y, z)
      state.move_to(x, y, z)
      send_move_look
    end

    def equip(code)
      send_packet :block_item_switch, 0, code
    end

    def dig(x, y, z)
      state.look_at(x, y, z)
      send_look

      equip map.tool_for(x, y, z)

      # favor x, z directionality over y, since
      # digging to the side could mean y + 1 or y + 0
      if state.coords[0] < x
        face = 4
      elsif state.coords[0] > x
        face = 5
      elsif state.coords[2] < z
        face = 2
      elsif state.coords[2] > z
        face = 3
      elsif state.coords[1] < y
        face = 0
      elsif state.coords[1] > y
        face = 1
      end

      send_packet :block_dig, 0, x, y, z, face
      send_packet :arm_animation, 0, true

      # an extra 5 packets for good measure seems to make it work better
      count = (DIGS[map[x, y, z]] || 3000) + 5
      count.times do
        send_packet :block_dig, 1, x, y, z, face
      end

      send_packet :block_dig, 3, x, y, z, face
      send_packet :block_dig, 2, 0, 0, 0, 0
    end

    def place(x, y, z, code)
      state.look_at(x, y, z)
      send_look
      equip code
      send_packet :place, code, x, y - 1, z, 1
    end

    def log(msg)
      puts Time.now.strftime("%F %H:%M:%S.%3N ") << msg
    end

  end
end
