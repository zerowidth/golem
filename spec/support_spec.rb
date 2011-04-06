require "spec_helper"
describe "bytes_for" do

  it "parses the given packet dump into bytes" do
    dump = <<-packet
0000 18 00 00 27 80 5f ff ff fe 70 00 00 0a a0 00 00
0001 13 70 02 00 91 00 00 00 00 10 00 52 00 00 00 00
0002 7f 32 ff ff ff
    packet

    bytes = bytes_for dump
    bytes.should have(37).items
    bytes[36].ord.should == 255
  end

  it "parses the bytes from a login packet" do
    bytes = bytes_for <<-packet
0000 02 00 06 61 6e 69 65 72 6f
    packet

    bytes.should == "\x02\x00\x06aniero"
  end

end
