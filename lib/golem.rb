module Golem

  require "eventmachine"

  Error = Class.new(StandardError)
  IncompletePacket = Class.new(Error)

  %w(field packet_definition packet packets client interceptor proxy).each do |lib|
    require "golem/#{lib}"
  end

end
