module Golem

  require "yaml"
  require "zlib"
  require "pathname"

  require "eventmachine"
  require "chunky_png"

  Error = Class.new(StandardError)
  IncompletePacket = Class.new(Error)

  %w(
    session
    console
    client
    action
    actions/watch
    actions/follow
    actions/hole
    field
    packet
    packets
    parser
    interceptor
    proxy
    chunk
    map
    blueprint
  ).each do |lib|
    require "golem/#{lib}"
  end

  def self.blueprint_path
    @blueprint_path ||= Pathname.new(File.expand_path(File.dirname(__FILE__) + "/../blueprints"))
  end

  class ::Numeric
    def in_degrees
      self * 180 / Math::PI
    end
  end

end
