#!/usr/bin/env ruby
require "rubygems"
$:.unshift "./lib"

require "golem"
Golem::Proxy.start("127.0.0.1", 8888, "127.0.0.1")
