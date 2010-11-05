require "spec_helper"

# test image is:
#
# layer 0:
# - - - - -
# - - - - -
# x x x - -
#
# layer 1:
# - - x x x
# - - - - x
# - - - - x
#
# but remember, map coords:
# +z <---+
#        |
#        |
#        v
#       +x

describe Golem::Blueprint do

  describe "with a blueprint name sans .yml extension" do
    it "finds the yml file" do
      bp =  Golem::Blueprint.new("test", [0, 0, 0])
      bp.size.should == [3, 2, 5]
    end
  end

  context "with a test blueprint at 10, 20, 30" do
    before :each do
      @bp = Golem::Blueprint.new("test.yml", [10, 20, 30])
    end

    describe "#size" do
      it "returns the size in map coordinate space" do
        @bp.size.should == [3, 2, 5]
      end
    end

    describe "#center" do
      it "returns the center of the blueprint" do
        @bp.center.should == [10, 20, 30]
      end
    end

    describe "#range" do
      it "returns the ranges of x, y, z coords involved in the blueprint" do
        @bp.range.should == [9..11, 20..21, 28..32]
      end
    end

    describe "#local(x,y,z)" do
      it "returns block data using 0-originated map coords" do
        @bp.local(0, 0, 0).should == :air
        @bp.local(0, 1, 0).should == :stone

        @bp.local(1, 0, 4).should == :air
        @bp.local(1, 1, 4).should == :air

        @bp.local(2, 0, 4).should == :stone
        @bp.local(2, 1, 4).should == :air
      end
    end

    describe "#block_data" do
      it "has the block data loaded according to map coordinate system" do
        @bp.block_data.should == [
          :air, :stone,
          :air, :stone,
          :air, :stone,
          :air, :air,
          :air, :air,

          :air, :stone,
          :air, :air,
          :air, :air,
          :air, :air,
          :air, :air,

          :air, :stone,
          :air, :air,
          :stone, :air,
          :stone, :air,
          :stone, :air,
        ]
      end
    end

    describe "#offset" do
      it "returns the x, y, z offset for the blueprint relative to the map and the starting point" do
        # map coord size is 3, 2, 5
        # center is 10, 20, 30
        # starting offset inside the image (map coords) is 1, 0, 2
        # center - internal offset
        # but takes into account the width of the image, too, since
        # the z axis is reversed and the start point is in image coords.
        @bp.offset.should == [9, 20, 28]
      end
    end

    describe "#[x, y, z] using map coords" do
      it "returns :air for the center point and layer above" do
        @bp[10, 20, 30].should == :air
        @bp[10, 21, 30].should == :air
      end

      it "returns :stone, air for the lower left (image) coords" do
        @bp[11, 20, 32].should == :stone
        @bp[11, 21, 32].should == :air
      end

      it "returns :air, :stone for the lower right (image) coords" do
        @bp[11, 20, 28].should == :air
        @bp[11, 21, 28].should == :stone
      end

    end

  end
end
