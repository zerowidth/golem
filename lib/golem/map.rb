module Golem
  class Map

    MAX_PATH_SIZE = 32

    def initialize
      @chunks = {}
    end

    def chunk(x, z)
      @chunks[x / 16] && @chunks[x / 16][z / 16]
    end

    def [](x, y, z)
      c = self.chunk(x, z)
      block = c && c[x, y, z]
      raise "invalid block #{[x, y, z].inspect} is #{block}" unless block
      block
    end

    def []=(x, y, z, type)
      c = self.chunk(x, z)
      if c && c[x, y, z]
        c[x, y, z] = type
      elsif c
        puts "got chunk but not offset: #{[x,y,z].inspect}"
      else
        puts "couldn't find chunk to assign block to: #{[x,y,z].inspect} #{type.inspect}"
      end
    end

    def preinitialize(x, z)
      @chunks[x] ||= {}
      @chunks[x][z] = Chunk.new(x * 16, 0, z * 16, 15, 127, 15, nil)
    end

    # add a chunk to the map
    def add(chunk)

      if chunk.full_chunk?
        @chunks[chunk.x / 16] ||= {}
        @chunks[chunk.x / 16][chunk.z / 16] = chunk
      else
        chunk.each do |location, type|
          self[*location] = type
        end
        validate
      end
    end

    # drop a chunk from the map
    def drop(x, z)
      @chunks[x] && @chunks[x].delete(z)
    end

    def size
      @chunks.map { |k, v| v.size }.inject(0) {|v,m| v + m }
    end

    def validate
      bad = nil
      if bad = @chunks.detect {|x, chunks_x| chunks_x.detect { |y, c| !c.valid?} }
        puts "bad chunk: #{c.x} #{c.z}"
      end
      bad.nil?
    end

    def solid?(x, y, z)
      SOLID.include?(self[x, y, z])
    end

    def available(x, y, z, mode = :move)
      Location.new(self).available(x, y, z, mode)
    end

    # A* algorithm adapted from http://rubyquiz.com/quiz98.html
    # with hints from http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
    def path(start, goals)
      goals = goals.flatten.size == 3 ? [goals.flatten] : goals

      location = Location.new(self)
      if goals.reject { |goal| (start[0] - goal[0]).abs + (start[1] - goal[1]).abs + (start[2] - goal[2]).abs > MAX_PATH_SIZE }.empty?
        puts "target too far away"
        return nil
      elsif goals.select { |g| location.allowed?(*g) }.empty?
        puts "can't follow, nowhere to go"
        return nil
      end
      visited = {}
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

        if goals.include? point.point
          final_path = point.path + [point.point]
          final_path.shift # don't need the start point, we're already there
          puts "examined #{examined} paths"
          return final_path
        end

        next_available = location.available(*point.point).each do |test|
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

  class Location
    NORTH = [-1, 0, 0]
    EAST  = [0, 0, -1]
    SOUTH = [1, 0, 0]
    WEST  = [0, 0, 1]
    UP    = [0, 1, 0]
    DOWN  = [0, -1, 0]

    attr_reader :map

    def initialize(map)
      @map = map
    end

    def available(x, y, z, mode = :move)
      pos = [x, y, z]
      list = []

      transforms = []
      allow_flight = true

      case mode
      when :move # all movements allowed
        transforms = [[NORTH], [EAST], [SOUTH], [WEST], [DOWN], [UP]]
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
        list << test if allowed?(*test, allow_flight)
      end

      list
    end

    def allowed?(x, y, z, allow_flight = true)
      block = map[x, y, z]
      above = y == 127 ? :air : map[x, y + 1, z]
      below = map[x, y - 1, z]
      open = !SOLID.include?(block) && !SOLID.include?(above)
      if allow_flight
        open
      else
        open && SOLID.include?(below) || WATER.include?(below)
      end
    end

    def combine(start, delta)
      start.zip(delta).map { |operands| operands.inject(0) { |m, v| m + v } }
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
