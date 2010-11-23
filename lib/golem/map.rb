module Golem
  class Map

    MAX_PATH_SIZE = 256

    NORTH = [-1, 0, 0]
    EAST  = [0, 0, -1]
    SOUTH = [1, 0, 0]
    WEST  = [0, 0, 1]
    UP    = [0, 1, 0]
    DOWN  = [0, -1, 0]

    def initialize
      @chunks = {}
      @pending_changes = {}
      @pending_updates = {}
    end

    def chunk(x, z)
      @chunks[x / 16] && @chunks[x / 16][z / 16]
    end

    def number_of_chunks
      @chunks.values.inject(0) {|sum, list| sum + list.keys.size }
    end

    def [](x, y, z)
      c = self.chunk(x, z)
      block = c && c[x, y, z]
      puts "invalid block #{[x, y, z].inspect} is #{block.inspect}" unless block
      block
    end

    def []=(x, y, z, type)
      c = self.chunk(x, z)
      if c && c[x, y, z]
        c[x, y, z] = type
      elsif c
        puts "got chunk but not offset: #{[x,y,z].inspect}"
      else
        # puts "storing assignment #{[x, y, z].inspect} #{type.inspect}"
        (@pending_changes[[x/16, z/16]] ||= []) << [x, y, z, type]
        # puts "couldn't find chunk to assign block to: #{[x,y,z].inspect} #{type.inspect}"
      end
    end

    # generate an empty chunk
    def empty(x, z)
      @chunks[x] ||= {}
      @chunks[x][z] = Chunk.new(x * 16, 0, z * 16, 15, 127, 15, nil)
    end

    # add a chunk to the map
    def add(chunk)
      if chunk.full_chunk?
        @chunks[chunk.x / 16] ||= {}
        # if @chunks[chunk.x / 16][chunk.z / 16]
        #   puts "replacing: #{[chunk.x, chunk.z].inspect}"
        # else
        #   puts "adding   : #{[chunk.x, chunk.z].inspect}"
        # end
        @chunks[chunk.x / 16][chunk.z / 16] = chunk

        key = [chunk.x/16, chunk.z/16]

        if @pending_changes[key]
          @pending_changes[key].each do |x, y, z, block|
            # puts "applying stored change #{[x, y, z].inspect} #{block}"
            self[x, y, z] = block
          end
          @pending_changes.delete key
        end

        if @pending_updates[key]
          @pending_updates[key].each do |x, y, z, data|
            # puts "applying stored update #{[x,y,z].inspect} #{data}"
            update(x, y, z, data)
            @pending_updates.delete key
          end
        end

      else
        # puts "incremental: #{[chunk.x, chunk.y, chunk.z].inspect} #{[chunk.size_x, chunk.size_y, chunk.size_z].inspect}"
        chunk.each_column do |x, y, z, data|
          # puts "updating #{[x,y,z].inspect} #{data.size} blocks"
          update(x, y, z, data)
        end
      end
    end

    # update a section of data incrementally
    def update(x, y, z, data)
      if c = chunk(x, z)
        # puts "updating #{[x,y,z].inspect} with #{data.inspect}"
        c.update(x, y, z, data)
      else
        # puts "storing update #{[x, y, z].inspect} #{data.inspect}"
        (@pending_updates[[x/16, z/16]] ||= []) << [x, y, z, data]
      end
    end

    # drop a chunk from the map
    def drop(x, z)
      @chunks[x] && @chunks[x].delete(z)
    end

    def size
      @chunks.map { |k, v| v.size }.inject(0) {|v,m| v + m }
    end

    def solid?(x, y, z)
      SOLID.include?(self[x, y, z])
    end

    def tool_for(x, y, z)
      kind = self[x, y, z]
      if tool = TOOLS.detect {|t, l| l.include? kind }
        tool[0]
      else
        0
      end
    end

    def find(code)
      found = []
      @chunks.each do |x, row|
        row.each do |z, chunk|
          found.concat chunk.find(code)
        end
      end
      return found
    end

    # return the nearest n blocks of type code
    def nearest(coords, code, n=5)
      sorted = find(code).sort_by { |pos| (pos[0] - coords[0]).abs + (pos[1] - coords[1]).abs + (pos[2] - coords[2]).abs }
      return sorted[0..n]
    end

    def available(x, y, z, mode = :move, ignore = {})
      pos = [x, y, z]
      list = []

      transforms = []
      allow_flight = true

      case mode
      when :move # all movements allowed
        transforms = [[NORTH], [EAST], [SOUTH], [WEST], [DOWN], [UP]]
      when :build
        transforms = [
          [UP, UP], [DOWN], # two up's so it's overhead
          [NORTH], [EAST], [SOUTH], [WEST],
          [NORTH, UP], [EAST, UP], [WEST, UP], [SOUTH, UP]
        ]
      when :next_to
        transforms = [
          [UP], [DOWN, DOWN], # two up's so it's overhead
          [NORTH], [EAST], [SOUTH], [WEST],
          [NORTH, DOWN], [EAST, DOWN], [WEST, DOWN], [SOUTH, DOWN]
        ]
      when :follow # following someone, don't get up in their business
        transforms = [
          [NORTH], [EAST], [SOUTH], [WEST],
          [NORTH, DOWN], [EAST, DOWN], [WEST, DOWN], [SOUTH, DOWN],
          [NORTH, UP], [EAST, UP], [WEST, UP], [SOUTH, UP]
        ]
        allow_flight = false
      end

      transforms.map do |transform|
        test = pos
        transform.each {|xform| test = combine(test, xform) }
        if mode == :build
          # digging upward so check for sand/gravel
          unless y == (test[1] - 2) &&
            [12, 13].include?(self[test[0], test[1] + 1, test[2]])
            [12, 13].include?(self[*test])
            list << test
          # else
            # puts "skipping #{test.inspect}, it's got gravel/sand above"
          end
        else
          list << test if allowed?(*test, allow_flight, ignore)
        end
      end

      list
    end

    def allowed?(x, y, z, allow_flight = true, ignore = {})
      block = self[x, y, z]
      above = y == 127 ? CODES[:air] : self[x, y + 1, z]
      below = self[x, y - 1, z]
      # check for full x y z coord as well as x, z column
      ignored = ignore[[x,y,z]] || ignore[[x, y + 1, z]] || ignore[[x, z]]
      open = !SOLID.include?(block) && !SOLID.include?(above) && !ignored
      if allow_flight
        open
      else
        open && SOLID.include?(below) || WATER.include?(below)
      end
    end

    def combine(start, delta)
      start.zip(delta).map { |operands| operands.inject(0) { |m, v| m + v } }
    end

    # A* algorithm adapted from http://rubyquiz.com/quiz98.html
    # with hints from http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
    #
    # mode can be:
    #   :move_to --> moves to a position
    #   :next_to --> next to a position
    #   :away_from --> get away from any of the points listed
    #
    # ignore is a list of points to disregard for pathfinding
    #
    def path(start, goals, mode=:move_to, ignore={})
      start = start.map(&:to_i)
      goals = goals.flatten.size == 3 ? [goals.flatten] : goals

      if goals.reject { |goal| (start[0] - goal[0]).abs + (start[1] - goal[1]).abs + (start[2] - goal[2]).abs > MAX_PATH_SIZE }.empty?
        puts "target too far away"
        return nil
      elsif mode == :move_to && goals.select { |g| allowed?(*g) }.empty?
        puts "can't go there..."
        return nil
      # elsif mode == :next_to && goals.map { |g| available(*g, :next_to).any? { |l| allowed?(*l) } }.empty?
      #   puts "nothing to move next to anymore..."
      #   return nil
      end
      visited = {}
      next_to = {}
      examined = 0

      heap = Heap.new { |a, b| a.cost <=> b.cost }
      heap.add Path.new(start, goals, [])

      while !heap.empty?
        point = heap.next

        if point.path.size > MAX_PATH_SIZE
          puts "examined #{examined} paths before giving up"
          return nil
        end

        next if visited[point.point]
        visited[point.point] = point

        examined += 1

        case mode
        when :move_to
          if goals.include?(point.point)
            final_path = point.path + [point.point]
            final_path.shift # don't need the start point, we're already there
            # puts "examined #{examined} paths"
            return final_path
          end

        when :away_from
          above = point.point.dup
          above[1] += 1
          if !goals.include?(point.point) && !goals.include?(above)
            final_path = point.path + [point.point]
            return final_path
          end

        when :next_to
          next_to[point.point] ||= available(*point.point, :build)
          available_for_building = next_to[point.point]
          if available_for_building.any? { |a| goals.include? a }
            final_path = point.path + [point.point]
            final_path.shift # don't need the start point, we're already there
            # puts "examined #{examined} paths"
            return final_path
          end

        else
          raise "unknown pathfinding mode: #{mode.inspect}"
        end

        next_available = available(*point.point, :move, ignore).each do |test|
          next if visited[test]
          heap.add Path.new(test, goals, point.path + [point.point])
        end
      end
      nil
    end

  end

  class Path
    attr_reader :point, :goals, :path
    def initialize(point, goals, path)
      @point, @goals, @path = point, goals, path
    end

    def inspect
      "<path #{point.inspect} (#{cost}): #{path.inspect}>"
    end

    def cost
      goals.map do |goal|
        heuristic =
          (goal[0] - point[0]).abs +
          (goal[1] - point[1]).abs +
          (goal[2] - point[2]).abs
        path_cost = path.size

        # scale heuristic by 1% for better efficiency
        # favors expansion near goal over expansion from start
        # via http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html#S12
        heuristic * 101 + path_cost * 100
      end.min
    end
  end

  # from http://rubyquiz.com/quiz40.html
  class Heap
    def initialize( *elements, &comp )
      @heap = [nil]
      @comp = comp || lambda { |p, c| p <=> c }

      add(*elements)
    end

    def clear
      @heap = [nil]
    end

    def next
      case size
      when 0
        nil
      when 1
        @heap.pop
      else
        extracted = @heap[1]
        @heap[1] = @heap.pop
        sift_down
        extracted
      end
    end

    def add(*elements)
      elements.each do |element|
        @heap << element
        sift_up
      end
    end

    def size
      @heap.size - 1
    end

    def empty?
      size == 0
    end

    def inspect
      @heap[1..-1].inspect
    end

    private

    def sift_down
      i = 1
      loop do
        c = 2 * i
        break if c >= @heap.size
        c += 1 if c + 1 < @heap.size and @comp[@heap[c + 1], @heap[c]] < 0
        break if @comp[@heap[i], @heap[c]] <= 0
        @heap[c], @heap[i] = @heap[i], @heap[c]
        i = c
      end
    end

    def sift_up
      i = @heap.size - 1
      until i == 1
        p = i / 2
        break if @comp[@heap[p], @heap[i]] <= 0
        @heap[p], @heap[i] = @heap[i], @heap[p]
        i = p
      end
    end
  end

end
