require "spec_helper"

describe Golem::NBTParser do

  context "with a simple test file" do

    before :each do
      @simple = File.read(Golem.path + "spec/fixtures/test.nbt")
    end

    describe "#values" do
      it "returns a nested hash containing the parsed data" do
        Golem::NBTParser.new(@simple).values.should == {
          "hello world" => {
            "name" => "Bananrama"
          }
        }
      end
    end
  end

  context "with a complex test file" do

    before :each do
      @complex = File.read(Golem.path + "spec/fixtures/bigtest.nbt")
    end

    it "returns a nested hash of the parsed data" do
      Golem::NBTParser.new(@complex).values.should == {
        "Level" => {
          "longTest" => 9223372036854775807,
          "shortTest" => 32767,
          "stringTest" => "HELLO WORLD THIS IS A TEST STRING \xC3\x85\xC3\x84\xC3\x96!",
          # "floatTest" => 0.49823147,
          "floatTest" => 0.4982314705848694,
          "intTest" => 2147483647,

          "nested compound test" => {
            "ham" => {
              "name" => "Hampus",
              "value" => 0.75
            },
            "egg" => {
              "name" => "Eggbert",
              "value" => 0.5
            }
          },

          "listTest (long)" => [11, 12, 13, 14, 15],

          "listTest (compound)" => [
            {"name" => "Compound tag #0", "created-on" => 1264099775885},
            {"name" => "Compound tag #1", "created-on" => 1264099775885}
          ],

          "byteTest" => 127,

          "byteArrayTest (the first 1000 values of (n*n*255+n*7)%100, starting with n=0 (0, 62, 34, 16, 8, ...))" =>
            (0..999).to_a.map { |n| (n * n * 255 + n * 7) % 100 },

          "doubleTest" => 0.4931287132182315
        }
      }
    end
  end

  describe ".parse" do
    it "returns the values of the parsed data" do
      data = File.read(Golem.path + "spec/fixtures/test.nbt")
      Golem::NBTParser.parse(data).should == { "hello world" => { "name" => "Bananrama" } }
    end
  end


end
