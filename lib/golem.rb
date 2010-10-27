module Golem

  require "eventmachine"
  require "zlib"

  Error = Class.new(StandardError)
  IncompletePacket = Class.new(Error)

  %w(
    session
    console
    client
    action
    actions/watch
    actions/follow
    field
    packet
    packets
    parser
    interceptor
    proxy
    chunk
    map
  ).each do |lib|
    require "golem/#{lib}"
  end

  class ::Numeric
    def in_degrees
      self * 180 / Math::PI
    end
  end

end
