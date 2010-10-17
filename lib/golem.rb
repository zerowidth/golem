module Golem

  require "eventmachine"

  Error = Class.new(StandardError)
  IncompletePacket = Class.new(Error)

  %w(state field packet packets client parser interceptor proxy).each do |lib|
    require "golem/#{lib}"
  end

end
