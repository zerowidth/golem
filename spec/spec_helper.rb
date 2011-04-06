require "rubygems"
require "bundler/setup"
Bundler.require :development

require "golem"

RSpec.configure do |rspec|

  def bytes_for(packet_dump)
    hex = packet_dump.split("\n").reject { |line| line.strip.empty? }.map do |line|
      line.split(" ")[1..-1]
    end.join("")
    [hex].pack("H*")
  end

end
