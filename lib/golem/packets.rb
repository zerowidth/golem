module Golem
  module Packets

    PROTOCOL_VERSION = 8

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
      long :map_seed # always 0, not required
      byte :dimension # always 0, not required
    end

    server_packet :accept_login, 0x01 do
      int :player_id
      string :server_name # ?
      string :motd # ?
      long :map_seed
      byte :dimension
    end

    client_packet :handshake, 0x02 do
      string :username
    end

    server_packet :handshake, 0x02 do
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

    server_packet :entity_equipment, 0x05 do
      int :entity_id
      short :slot # 0 = held, 1-4 = armor slots
      short :item_id # -1 for empty
      short :damage?
    end

    server_packet :spawn_position, 0x06 do
      int :x
      int :y
      int :z
    end

    server_packet :use_entity, 0x07 do
      int :player_id
      int :entity_id
      bool :left_click # true when pointing at an entity, false when using a block
    end
    client_packet :use_entity, 0x07 do
      int :player_id
      int :entity_id
      bool :left_click # true when pointing at an entity, false when using a block
    end

    server_packet :player_health, 0x08 do
      short :health # 0 = dead, 20 = full
    end

    server_packet :respawn, 0x09 do
    end

    client_packet :respawn, 0x09 do
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

    server_packet :player_look, 0x0c do
      float :rotation
      float :pitch
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
      int :x
      byte :y
      int :z
      byte :direction
      field :items, Field::SlotItems
    end

    client_packet :holding_change, 0x10 do
      short :slot_id # slot which player has selected, 0-8
    end

    server_packet :animation, 0x12 do
      int :entity_id
      byte :animate # 0 = no animation, 1 = swing, 2 = death? 102 = ?
    end

    client_packet :animation, 0x12 do
      int :entity_id
      byte :animate
    end

    client_packet :entity_action, 0x13 do
      int :entity_id
      byte :action # 1 crouch, 2 uncrouch?
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
      short :damage?
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
      short :damage?
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
      field :mob_data, Field::MobData
    end

    server_packet :painting, 0x19 do
      int :id
      string :title # name of the painting
      int :x
      int :y
      int :z
      int :type
    end

    server_packet :entity_velocity, 0x1c do
      int :id
      short :v_x
      short :v_y
      short :v_z
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

    server_packet :entity_damage, 0x26 do
      int :id
      byte :damage
    end

    server_packet :attach_entity, 0x27 do
      int :entity_id
      int :vehicle_id # -1 for unattach
    end

    server_packet :entity_metadata, 0x28 do
      int :entity_id
      field :metadata, Field::MobData
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
      def inspect
        "<0x33 map chunk: [#{size_x + 1}, #{size_y + 1}, #{size_x + 1}]>"
      end
    end

    server_packet :multi_block_change, 0x34 do
      int :x
      int :z
      field :block_changes, Field::MultiBlockChange

      def changes
        offset_x = x * 16
        offset_z = z * 16
        coords, types, metadata = *block_changes
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

    server_packet :play_note, 0x36 do
      int :x
      short :y
      int :z
      byte :instrument
      byte :pitch
    end

    server_packet :explosion, 0x3c do
      double :x
      double :y
      double :z
      float :radius # maybe?
      field :explosion, Field::ExplosionBlocks
    end

    server_packet :open_window, 0x64 do
      byte :window_id
      byte :inventory_type
      string :window_title
      byte :number_of_slots
    end

    server_packet :close_window, 0x65 do
      byte :window_id
    end

    client_packet :close_window, 0x65 do
      byte :window_id
    end

    client_packet :window_click, 0x66 do
      byte :window_id
      short :slot
      byte :right_click
      short :action_number
      field :items, Field::SlotItems
    end

    server_packet :set_slot, 0x67 do
      byte :window_id # 0 for inventory
      short :slot
      field :items, Field::SlotItems
    end

    server_packet :window_items, 0x68 do
      byte :type # 0 for inventory
      field :items, Field::WindowItems
    end

    server_packet :update_progress_bar, 0x69 do
      byte :window_id
      short :progress_bar # furnace: 0 is progress, 1 is fire
      short :value
    end

    server_packet :transaction, 0x6a do
      byte :window_id
      short :action_number # must be in sequence
      bool :accepted
    end

    client_packet :transaction, 0x6a do
      byte :window_id
      short :action_number
      bool :accepted
    end

    client_packet :update_sign, 0x82 do
      int :x
      short :y
      int :z
      string :text_1
      string :text_2
      string :text_3
      string :text_4
    end

    server_packet :update_sign, 0x82 do
      int :x
      short :y
      int :z
      string :text_1
      string :text_2
      string :text_3
      string :text_4
    end

    client_packet :disconnect, 0xff do
      string :message
    end

    server_packet :disconnect, 0xff do
      string :message
    end

  end
end
