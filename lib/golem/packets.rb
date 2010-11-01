module Golem
  module Packets

    def self.client_packet(kind, code, &blk)
      p = Class.new(Packet)
      p.kind = kind
      p.code = code
      p.module_eval(&blk) if blk
      Packet.client_packet p
    end

    def self.server_packet(kind, code, &blk)
      p = Class.new(Packet)
      p.kind = kind
      p.code = code
      p.module_eval(&blk) if blk
      Packet.server_packet p
    end

    client_packet :keepalive, 0x00

    server_packet :keepalive, 0x00

    client_packet :login, 0x01 do
      int :protocol_version
      string :username
      string :password
    end

    server_packet :accept_login, 0x01 do
      int :player_id
      string :unused_1
      string :unused_2
      long :map_seed
      byte :dimension
    end

    client_packet :handshake, 0x02 do
      string :username
    end

    server_packet :server_handshake, 0x02 do
      string :server_id
    end

    server_packet :chat, 0x03 do
      string :message
    end

    client_packet :chat, 0x03 do
      string :message
    end

    server_packet :update_time, 0x04 do
      long :time
    end

    client_packet :player_inventory, 0x05 do
      field :inventory, Field::PlayerInventory
    end

    server_packet :player_inventory, 0x05 do
      field :inventory, Field::PlayerInventory
    end

    server_packet :spawn_position, 0x06 do
      int :x
      int :y
      int :z
    end

    client_packet :flying_ack, 0x0a do
      bool :flying
    end

    server_packet :flying, 0x0a do
      bool :flying
    end

    client_packet :player_position, 0x0b do
      double :x
      double :y
      double :stance
      double :z
      bool :flying
    end

    server_packet :player_position, 0x0b do
      double :x
      double :y
      double :stance
      double :z
      bool :flying
    end

    client_packet :player_look, 0x0c do
      float :rotation
      float :pitch
      bool :flying
    end

    client_packet :player_move_look, 0x0d do
      double :x
      double :y
      double :stance
      double :z
      float :rotation
      float :pitch
      bool :flying
    end

    server_packet :player_move_look, 0x0d do
      double :x
      # yes, this is reversed from the packet the client sends.
      double :stance
      double :y
      double :z
      float :rotation
      float :pitch
      bool :flying
    end

    client_packet :block_dig, 0x0e do
      byte :status
      int :x
      byte :y
      int :z
      byte :direction
    end

    client_packet :place, 0x0f do
      short :type
      int :x
      byte :y
      int :z
      byte :direction
    end

    server_packet :block_item_switch, 0x10 do
      int :entity_id
      short :item_code
    end

    client_packet :block_item_switch, 0x10 do
      int :entity_id
      short :item_code
    end

    server_packet :add_to_inventory, 0x11 do
      short :type
      byte :amount
      short :life
    end

    client_packet :arm_animation, 0x12 do
      int :entity_id
      bool :forward # on to other clients
    end

    server_packet :arm_animation, 0x12 do
      int :entity_id
      bool :forward # on to other clients
    end

    server_packet :named_entity_spawn, 0x14 do
      int :id
      string :name
      int :x
      int :y
      int :z
      byte :rotation
      byte :pitch
      short :current_item
    end

    # client drops something
    client_packet :pickup_spawn, 0x15 do
      int :id
      short :item
      byte :count
      int :x
      int :y
      int :z
      byte :rotation
      byte :pitch
      byte :roll
    end

    server_packet :pickup_spawn, 0x15 do
      int :id
      short :item
      byte :count
      int :x
      int :y
      int :z
      byte :rotation
      byte :pitch
      byte :roll
    end

    server_packet :collect_item, 0x16 do
      int :item_id
      int :collector_id
    end

    server_packet :vehicle_spawn, 0x17 do
      int :id
      byte :type
      int :x
      int :y
      int :z
    end

    server_packet :mob_spawn, 0x18 do
      int :id
      byte :type
      int :x
      int :y
      int :z
      byte :rotation
      byte :pitch
    end

    server_packet :destroy_entity, 0x1d do
      int :id
    end

    server_packet :entity, 0x1e do
      int :id
    end

    server_packet :entity_move, 0x1f do
      int :id
      byte :x
      byte :y
      byte :z
    end

    server_packet :entity_look, 0x20 do
      int :id
      byte :rotation
      byte :pitch
    end

    server_packet :entity_move_look, 0x21 do
      int :id
      byte :x
      byte :y
      byte :z
      byte :rotation
      byte :pitch
    end

    server_packet :entity_teleport, 0x22 do
      int :id
      int :x
      int :y
      int :z
      byte :rotation
      byte :pitch
    end

    server_packet :pre_chunk, 0x32 do
      int :x # multiply by 16
      int :z # multiply by 16
      bool :add
    end

    server_packet :map_chunk, 0x33 do
      int :x
      short :y
      int :z
      byte :size_x
      byte :size_y
      byte :size_z
      field :chunk, Field::MapChunk
    end

    server_packet :multi_block_change, 0x34 do
      int :x
      int :z
      field :block_changes, Field::MultiBlockChange

      def changes
        offset_x = x * 16
        offset_z = z * 16
        coords = values[2]
        types = values[3]
        coords.map.with_index do |num, i|
          change_x = ((num & 0xF000) >> 12) + offset_x
          change_z = ((num & 0x0F00) >> 8) + offset_z
          change_y = num & 0xFF
          [[change_x, change_y, change_z], types[i]]
        end
      end
    end

    server_packet :block_change, 0x35 do
      int :x
      byte :y
      int :z
      byte :type
      byte :metadata
    end

    server_packet :complex_entity, 0x3b do
      int :x
      short :y
      int :z
      field :payload, Field::EntityPayload
    end

    client_packet :disconnect, 0xff do
      string :message
    end

    server_packet :disconnect, 0xff do
      string :message
    end

  end
end
