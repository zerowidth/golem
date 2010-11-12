module Golem

  require "yaml"
  require "zlib"
  require "pathname"
  require "timeout"

  require "eventmachine"
  require "chunky_png"

  Error = Class.new(StandardError)
  IncompletePacket = Class.new(Error)
  Actions = Module.new

  STANCE = 1.62000000476837

  %w(
    blocks

    chunk
    map
    blueprint

    field
    nbt_parser
    packet
    packets
    parser
    state

    console
    session
    proxy
    client
    bot

    action
    actions/simple
    actions/watch
    actions/follow
    actions/come
    actions/survey
    actions/build
    actions/dig_test

  ).each do |lib|
    require "golem/#{lib}"
  end

  def self.path
    @path ||= Pathname.new(File.expand_path(File.dirname(__FILE__) + "/.."))
  end

  def self.blueprint_path
    @blueprint_path ||= path + "blueprints"
  end

  class ::Numeric
    def in_degrees
      self * 180 / Math::PI
    end
  end

end
