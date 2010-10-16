module Golem

  require "eventmachine"

  Error = Class.new(StandardError)
  IncompletePacket = Class.new(Error)

  require "golem/field"
  require "golem/packet_definition"
  require "golem/packet"
  require "golem/packets"
  require "golem/client"

end
