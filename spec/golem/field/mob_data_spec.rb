require "spec_helper"

describe Golem::Field::MobData do

  it "parases a wolf mob correctly" do

    # for reference -- the wolf mob data is in this
    # packet further on (starting with '91')
    mob_packet = bytes_for <<-packet
0000 18 00 00 27 80 5f ff ff fe 70 00 00 0a a0 00 00
0001 13 70 02 00 91 00 00 00 00 10 00 52 00 00 00 00
0002 7f 32 ff ff ff ff 00 00 00 09 01 32 ff ff ff ff
0003 00 00 00 08 01 32 ff ff ff ff 00 00 00 07 01 32
0004 ff ff ff ff 00 00 00 06 01 32 ff ff ff ff 00 00
0005 00 05 01 32 ff ff ff ff 00 00 00 04 01 32 ff ff
0006 ff ff 00 00 00 03 01 32 ff ff ff ff 00 00 00 02
0007 01 32 ff ff ff ff 00 00 00 01 01 32 ff ff ff ff
0008 00 00 00 00 01 32 ff ff ff ff ff ff ff ff 01 32
0009 00 00 00 00 ff ff ff ff 01 32 00 00 00 01 ff ff
000a ff ff 01 32 00 00 00 02 ff ff ff ff 01 32 00 00
000b 00 03 ff ff ff ff 01 32 00 00 00 04 ff ff ff ff
000c 01 32 00 00 00 05 ff ff ff ff 01 32 00 00 00 06
000d ff ff ff ff 01 32 00 00 00 07 ff ff ff ff 01 32
000e 00 00 00 08 ff ff ff ff 01 32 00 00 00 09 ff ff
000f ff ff 01 32 00 00 00 0a ff ff ff ff 01 32 00 00
0010 00 0b ff ff ff ff 01 32 00 00 00 0c ff ff ff ff
0011 01 32 00 00 00 0d ff ff ff ff 01 32 00 00 00 0e
0012 ff ff ff ff 01 32 00 00 00 0e 00 00 00 00 01 32
0013 00 00 00 0e 00 00 00 01 01 32 00 00 00 0e 00 00
0014 00 02 01 32 00 00 00 0e 00 00 00 03 01 32 00 00
    packet

    mob_data = bytes_for <<-mob_data
0000 91 00 00 00 00 10 00 52 00 00 00 00 7f 32 ff ff
0001 ff ff 00 00 00 09 01 18 00 00 28 94 33 ff ff fe
0002 15 00 00 04 60 00 00 10 ed ff 00 00 00 7f 32 ff
0003 ff ff ff 00 00 00 08 01 18 00 00 28 98 32 ff ff
0004 ff 03 00 00 08 e0 00 00 0e 9e 04 00 00 00 10 ff
0005 7f 32 ff ff ff ff 00 00 00 07 01 32 ff ff ff ff
0006 00 00 00 06 01 32 ff ff ff ff 00 00 00 05 01 32
0007 ff ff ff ff 00 00 00 04 01 32 ff ff ff ff 00 00
0008 00 03 01 32 ff ff ff ff 00 00 00 02 01 32 ff ff
0009 ff ff 00 00 00 01 01 32 ff ff ff ff 00 00 00 00
000a 01 32 ff ff ff ff ff ff ff ff 01 32 00 00 00 00
000b ff ff ff ff 01 32 00 00 00 01 ff ff ff ff 01 32
    mob_data

    # Golem::Packet.parse(data)
    Golem::Field::MobData.new.parse(mob_data)

  end



end
