module Golem
  module Packets

    def self.client_packet(kind, code, description="", &blk)
      p = Class.new(Packet)
      p.kind = kind
      p.code = code
      # p.description = description
      p.module_eval(&blk) if blk
      Packet.by_kind[kind] = p
    end

    def self.server_packet(kind, code, description="", &blk)
      p = Class.new(Packet)
      p.kind = kind
      p.code = code
      # p.description = description
      p.module_eval(&blk) if blk
      Packet.by_code[code] = p
    end

    client_packet :keepalive, 0x00, "client keepalive"
    server_packet :server_keepalive, 0x00, "server keepalive"

    client_packet :login, 0x01, "client login" do
      int :protocol_version
      string :username
      string :password
    end

    server_packet :accept_login, 0x01, "server accepts login" do
      int :player_id
      string :unused_1
      string :unused_2
    end

    client_packet :handshake, 0x02, "client handshake" do
      string :username
    end

    server_packet :server_handshake, 0x02, "handshake" do
      string :server_id
    end

    server_packet :server_chat, 0x03, "server chat" do
      string :message
    end

    client_packet :chat, 0x03, "chat" do
      string :message
    end

    server_packet :update_time, 0x04, "update time" do
      long :time
    end

    server_packet :player_inventory, 0x05, "player inventory" do
      fields << Field::PlayerInventory
    end

    server_packet :spawn_position, 0x06, "spawn position update" do
      int :x
      int :y
      int :z
    end

    server_packet :flying, 0x0a, "flying" do
      bool :flying
    end

    client_packet :flying_ack, 0x0a, "client ack" do
      bool :flying
    end

    server_packet :player_position, 0x0b, "player position" do
      double :x
      double :y
      double :stance
      double :z
      bool :flying
    end

    server_packet :player_move_look, 0x0d, "player move and look" do
      double :x
      double :y
      double :stance
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

    server_packet :named_entity_spawn, 0x14, "named entity spawn" do
      int :id
      string :name
      int :x
      int :y
      int :z
      byte :rotation
      byte :pitch
      short :current_item
    end

    server_packet :pickup_spawn, 0x15, "pickup spawn" do
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

    server_packet :mob_spawn, 0x18, "mob/entity spawn" do
      int :id
      byte :type
      int :x
      int :y
      int :z
      byte :rotation
      byte :pitch
    end

    server_packet :destroy_entity, 0x1d, "destroy entity" do
      int :id
    end

    server_packet :entity, 0x1e, "entity" do
      int :id
    end

    server_packet :entity_move, 0x1f, "entity move" do
      int :id
      byte :x
      byte :y
      byte :z
    end

    server_packet :entity_look, 0x20, "entity look" do
      int :id
      byte :rotation
      byte :pitch
    end

    server_packet :relative_entity_move_look, 0x21, "relative entity move and look" do
      int :id
      byte :x
      byte :y
      byte :z
      byte :rotation
      byte :pitch
    end

    server_packet :pre_chunk, 0x32, "prepare for a chunk" do
      int :x
      int :z
      bool :mode
    end

    server_packet :map_chunk, 0x33, "map chunk data" do
      int :x
      short :y
      int :z
      fields << Field::MapChunk
    end

    server_packet :block_change, 0x35, "block change" do
      int :x
      byte :y
      int :z
      byte :type
      byte :metadata
    end

    server_packet :complex_entity, 0x3b, "complex entity" do
      int :x
      short :y
      int :z
      fields << Field::EntityPayload
    end

    server_packet :disconnect, 0xff, "server disconnect" do
      string :message
    end

  end
end
