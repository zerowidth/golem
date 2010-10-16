#!/usr/bin/env ruby

require "rubygems"

$:.unshift "./lib"

require "golem"

Golem::Client.run("127.0.0.1")

