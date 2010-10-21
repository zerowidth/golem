module Golem
  class Map

    MAX_PATH_SIZE = 64 # travel up to 4 chunks in one direction

    def initialize
      @chunks = {}
    end

    def chunk(x, z)
      @chunks[x / 16] && @chunks[x / 16][z / 16]
    end

    def [](x, y, z)
      c = self.chunk(x, z)
      c && c[x, y, z]
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

    # add a chunk to the map
    def add(chunk)

      if chunk.full_chunk?
        @chunks[chunk.x / 16] ||= {}
        @chunks[chunk.x / 16][chunk.z / 16] = chunk
      else
        chunk.each do |location, type|
          self[*location] = type
        end
      end
    end

    # drop a chunk from the map
    def drop(x, z)
      @chunks[x/16] && @chunks[x/16].delete(z/16)
    end

    def solid?(x, y, z)
      SOLID.include?(self[x, y, z])
    end

    def available(x, y, z)
      Location.new(self).available(x, y, z)
    end

    # A* algorithm adapted from http://rubyquiz.com/quiz98.html
    # with hints from http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
    def path(start, goal)
      location = Location.new(self)
      visited = {}
      examined = 0

      heap = Heap.new { |a, b| a.cost <=> b.cost }
      heap.add Path.new(start, goal, [])

      while !heap.empty?
        point = heap.next

        if point.path.size > MAX_PATH_SIZE
          puts "examined #{examined} paths before giving up"
          return nil
        end

        next if visited[point.point]
        visited[point.point] = point

        puts point.inspect
        examined += 1

        if point.point == goal
          final_path = point.path + [point.point]
          final_path.shift # don't need the start point, we're already there
          puts "examined #{examined} paths"
          return final_path
        end

        next_available = location.available(*point.point).each do |test|
          next if visited[test]
          heap.add Path.new(test, goal, point.path + [point.point])
        end
      end
      nil
    end

  end

  class Path
    attr_reader :point, :goal, :path
    def initialize(point, goal, path)
      @point, @goal, @path = point, goal, path
    end

    def inspect
      "<path #{point.inspect} (#{cost}): #{path.inspect}>"
    end

    def cost
      heuristic =
        (goal[0] - point[0]).abs +
        (goal[1] - point[1]).abs +
        (goal[2] - point[2]).abs
      path_cost = path.size

      # scale heuristic by 1% for better efficiency
      # favors expansion near goal over expansion from start
      # via http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html#S12
      heuristic * 101 + path_cost * 100
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

    def available(x, y, z)
      pos = [x, y, z]
      list = []
      standing_on = map[x, y, z]

      # the bot can fly for now, so whatever:
      [NORTH, EAST, SOUTH, WEST, UP, DOWN].map do |transform|
        test = combine(pos, transform)
        if pass?(*test) && pass?(*(combine(test, UP)))
          list << test
        end
      end

      # up
      # down
      # change depending on what

      list
    end

    def pass?(x, y, z)
      block = map[x, y, z]
      # don't pathfind into the unknown!
      !block.nil? && !SOLID.include?(map[x, y, z])
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
