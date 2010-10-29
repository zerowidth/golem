module Golem
  class Blueprint

    attr_reader :plans
    attr_reader :size # in map coords
    attr_reader :block_data
    attr_reader :offset, :center
    # attr_reader :size_x, :size_y, :size_z

    def initialize(blueprint_file, x, y, z)
      @plans = YAML.load(File.read( Golem.blueprint_path + blueprint_file) )

      start_x, start_y, start_z = plans["start"]
      @offset = [x - start_y, y - start_z, z - start_x]
      @center = [x, y, z]

      size_x, size_y, size_z = plans["size"]
      @size = [size_y, size_z, size_x] # map absolute

      load_blocks_from_layers(plans["layers"], plans["size"])
    end

    def relative(x, y, z)
      block_data[ x * size[1] * size[2] + y + z * size[1] ]
    end

    # absolute map coordinates
    def [](x, y, z)
      local_x = x - offset[0]
      local_y = y - offset[1]
      local_z = z - offset[2]
      # puts "#{[x,y,z].inspect} --> #{[local_x, local_y, local_z].inspect}"
      relative(local_x, local_y, local_z)
    end

    protected

    def load_blocks_from_layers(layers, image_size)
      files = layers.uniq.sort
      file_data = {}

      layers.uniq.sort.each do |fn|
        file_data[fn] = blocks_from_image(fn, image_size)
      end

      if plans["size"][2] != plans["layers"].size
        raise "vertical size is #{plans["size"][2]} but there are #{plans["layers"].size} layers"
      end

      size_x, size_y, size_z = image_size

      # puts "img size: #{plans["size"].inspect}"
      # puts "map size: #{size.inspect}"

      # block data in relative map coords, starting at 0, 0, 0
      @block_data = Array.new(size[0] * size[1] * size[2])

      layers = plans["layers"].map {|fn| file_data[fn]}

      0.upto(size_x - 1) do |img_x|
        0.upto(size_y - 1) do |img_y|
          0.upto(size_z - 1) do |img_z|
            # coordinate conversion to map coords, plus offset
            # so +x image space ends up not being a negative z
            # (must take this into account for offset calculation!)
            x, y, z = img_y, img_z, - img_x + size[2] - 1

            i = x * size[1] * size[2] + y + z * size[1]
            d = layers[img_z][img_x * size_y + img_y]
            # puts "#{[img_x, img_y, img_z].inspect} --> #{[x, y, z].inspect} (#{i}): #{d}"
            block_data[i] = d
          end
        end
      end
    end

    def blocks_from_image(fn, image_size)
      img = ChunkyPNG::Canvas.from_file(Golem.blueprint_path + fn)

      if img.size != image_size[0..1]
        raise "#{fn} doesn't have the right dimensions, is #{img.size.inspect}, expected #{image_size[0..1].inspect}"
      end

      blocks = []

      0.upto(img.width - 1) do |img_x|
        0.upto(img.height - 1) do |img_y|
          color = ChunkyPNG::Color.to_truecolor_alpha_bytes(img[img_x, img_y])
          block = case color

          when [0, 0, 0, 0], [255, 255, 255, 0] # fully transparent
            nil

          when [255, 255, 255, 255] # white
            :stone

          when [0, 0, 0, 255] # black
            :air

          else
            raise "unknown color in #{fn} at #{[img_x,img_y].inspect} #{color.inspect}"
          end

          blocks << block
        end
      end

      blocks
    end

    # def to_s
    #   plans["layers"].map {|fn| file_data[fn] }.each.with_index do |layer, i|
    #     puts "# #{i}"
    #     width, height = plans["size"]
    #     0.upto(height - 1) do |y|
    #       0.upto(width - 1) do |x|
    #         case layer[x * width + y]
    #         when :air
    #           print " "
    #         when :stone
    #           print "x"
    #         when nil
    #           print "-"
    #         end
    #       end
    #       puts
    #     end
    #   end
    # end

  end
end
