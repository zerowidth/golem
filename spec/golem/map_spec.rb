require "spec_helper"

describe Golem::Map do

  context "with a new map" do
    it "has 0 chunks" do
      Golem::Map.new.should have(0).chunks
    end
  end

  describe "#empty" do
    it "initializes an empty chunk in a map" do
      map = Golem::Map.new
      map.should have(0).chunks
      map.empty(0,0)
      map.should have(1).chunks
    end
  end

  context "with an empty chunk" do
    before :each do
      @map = Golem::Map.new
      @map.empty(0, 0)
    end

    describe "[]" do
      it "retrieves the block at the given location" do
        @map[0,0,0].should == :air
      end
    end

    describe "[]=" do
      it "sets the block at the given location" do
        @map[0,0,0] = :dirt
        @map[0,0,0].should == :dirt
      end
    end
  end


  describe "#path" do

    context "with a dirt field" do

      before :each do
        @map = Golem::Map.new
        @map.empty(0, 0)
        @map.empty(-1, 0)
        @map.empty(-1, -1)
        @map.empty(0, -1)
        0.upto(16) do |x|
          0.upto(63) do |y|
            0.upto(16) do |z|
              block = if y == 0
                        :bedrock
                      else
                        :dirt
                      end
              @map[x, y, z] = :dirt
            end
          end
        end
      end

      it "returns the shortest direct path between two points" do
        @map.path([0,64,0], [2,64,0]).should == [ [1, 64, 0], [2, 64, 0] ]
      end

      context "with ground-level blocks marked as ignored" do
        it "returns the shortest path around the ignored blocks" do
          path = @map.path([0, 64, 0], [2, 64, 0], :move_to, {[1, 64, 0] => true, [1, 64, -1] => true})
          path.should_not include([1,64,0], [1, 64, -1])
        end
      end

      context "with head-level blocks marked as ignored" do
        it "returns the shortest path around the ignored blocks" do
          path = @map.path([0, 64, 0], [2, 64, 0], :move_to, {[1, 65, 0] => true, [1, 65, -1] => true})
          path.should_not include([1,65,0], [1, 65, -1])
        end
      end

    end

  end
end
