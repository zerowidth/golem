module Golem
  module Field
    class Base
      attr_reader :value, :raw

      def initialize(value=nil)
        @value = value
        @raw = ""
      end

      # sets the value based on type and returns the remaining data
      def parse(data)
        raise "don't know how to parse a #{self.class}"
      end

      # encode the value appropriately, returns a string
      # (must override in subclasses)
      def encode
        raise "don't know how to encode a #{self.class} with values #{values.inspect}"
      end

      protected

      def consume(data, pattern)
        results = data.unpack(pattern + "a*")
        raise IncompletePacket if results.any? {|r| r.nil?}

        bytes = data.length - results.last.length
        raw << data[0...bytes]

        results
      end
    end

    class String < Base
      def parse(data)
        size, data = consume data, "n"
        *bytes, data = consume data, "C#{size}"
        value = bytes.map { |b| b.chr }.join("")
        [value, data]
      end

      def encode
        [value.size, value].pack("na*")
      end
    end

    class Integer < Base
      def parse(data)
        value, data = consume data, "N"
        value = value & 0x40000000 > 0 ? -((value ^ 0xFFFFFFFF) & 0x7FFFFFFF) - 1 : value
        [value, data]
      end

      def encode
        [value].pack("N")
      end
    end

    class Long < Base
      def parse(data)
        big, little, remainder = consume data, "NN"
        [(big << 32) + little, remainder]
      end

      def encode
        big = value >> 32
        little = value - (value >> 32 << 32)
        [big, little].pack("NN")
      end
    end

    class Short < Base
      def parse(data)
        value, data = consume data, "n"
        value = value & 0x4000 > 0 ? -((value ^ 0xFFFF) & 0x7FFF) - 1 : value
        [value, data]
      end

      def encode
        [value].pack("n")
      end
    end

    class Boolean < Base
      def parse(data)
        flag, remainder = consume data, "C"
        flag = flag == 1
        [flag, remainder]
      end

      def encode
        value = value.kind_of?(Integer) ? value : (value ? 1 : 0)
        [value].pack("C")
      end
    end

    class Double < Base
      def parse(data)
        value, remainder = consume data, "G"
      end

      def encode
        [value].pack("G")
      end
    end

    class Float < Base
      def parse(data)
        value, remainder = consume data, "g"
      end
      def encode
        [value].pack("g")
      end
    end

    class Byte < Base
      def parse(data)
        value, remainder = consume data, "c"
      end

      def encode
        [value].pack("C")
      end
    end

    class SlotItems < Base
      def parse(data)
        item_id, data = consume data, "n"
        if item_id == 0xFFFF
          count, uses = 0, 0
        else
          count, uses, data = consume data, "CC"
        end

        [item_id, count, uses, data]
      end

      def encode
        slot, count, uses = *value
        if slot && count && uses
          return [slot, count, uses].pack("nCC")
        else
          return [-1].pack("n")
        end
      end
    end

    class WindowItems < Base
      def parse(data)
        count, data = consume data, "n"
        slots = Array.new(count)
        count.times do |n|
          item_id, data = consume data, "n"
          # 2's complement
          # item_id = item_id & 0x4000 > 0 ? -((item_id ^ 0xFFFF) & 0x7FFF) - 1 : item_id
          # puts "    slot #{n} item id #{item_id}"
          unless item_id == 0xFFFF
            item_count, uses, data = consume data, "Cn"
            slots[n] = [item_id, item_count, uses]
          end
        end

        [slots, data]
      end
    end

    class MapChunk < Base
      def parse(data)
        chunk_size, data = consume data, "N"
        if data.size >= chunk_size
          chunk_data = data[0...chunk_size]
          raw << chunk_data
          class << chunk_data
            def inspect
              "chunk data - #{size} bytes"
            end
          end
          data = data[chunk_size..-1]
        else
          raise IncompletePacket
        end
        [chunk_data, data]
      end
    end

    class EntityPayload < Base
      def parse(data)
        size, data = consume data, "n"
        *bytes, data = consume data, "C#{size}"
        payload = bytes.map {|b| b.chr }.join("")
        [size, payload, data]
      end
    end

    class MultiBlockChange < Base
      def parse(data)
        array_size, data = consume data, "n"
        *coords, data = consume data, "n#{array_size}"
        *types, data = consume data, "C#{array_size}"
        *metadata, data = consume data, "C#{array_size}"
        [coords, types, metadata, data]
      end
    end

    class ExplosionBlocks < Base
      def parse(data)
        count, data = consume data, "N"
        affected = []
        count.times do
          *coords, data = consume data, "ccc"
          affected << coords
        end
        return [affected, data]
      end
    end

  end
end
