module Golem

  require "eventmachine"

  Error = Class.new(StandardError)

  require "golem/field"
  require "golem/packet_definition"
  require "golem/packet"
  require "golem/packets"
  require "golem/client"

end
