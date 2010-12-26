module Golem
  class NBTParser

    def self.parse(bytes)
      new(bytes).values
    end

    attr_reader :bytes, :values

    def initialize(bytes)
      @bytes = Zlib::GzipReader.new(StringIO.new(bytes)).read
      @values = parse :with_name => true
    end

    protected

    def read(pattern)
      *values, remainder = bytes.unpack pattern + "a*"
      @bytes = remainder
      values.size > 1 ? values : values[0]
    end

    # opts are :type => int to specify what to parse as,
    # and :with_name => true/false to read a name after the type
    def parse(opts = {})
      type = opts[:type] || read("c")

      if type != 0 && opts[:with_name]
        name = read_string
      end

      value = case type
      when 0 # TAG_End
        :end
      when 1 # TAG_Byte
        read "C"
      when 2 # TAG_Short
        value = read "n"
        value & 0x4000 > 0 ? -((value ^ 0xFFFF) & 0x7FFF) - 1 : value
      when 3 # TAG_Int
        value = read "N"
        value & 0x40000000 > 0 ? -((value ^ 0xFFFFFFFF) & 0x7FFFFFFF) - 1 : value
      when 4 # TAG_Long
        big, little = read "NN"
        (big << 32) + little
      when 5 # TAG_Float
        read "g"
      when 6 # TAG_Double
        read "G"
      when 7 # TAG_Byte_Array
        size = read "N"
        read "C#{size}"
      when 8 # TAG_String
        read_string
      when 9 # TAG_List
        list_type = read "c"
        size = read "N"
        list = []
        size.times do
          list << parse(:type => list_type)
        end
        list
      when 10 # TAG_Compound
        values = {}

        while !bytes.empty? && parsed = parse(:with_name => true)
          break if parsed == :end
          values.merge! parsed
        end

        values
      else
        raise "wtf? unknown NBT type #{type}"
      end

      opts[:with_name] && type != 0 ? {name => value} : value
    end

    def read_string
      length = read "n"
      read("a#{length}")
    end

  end
end
