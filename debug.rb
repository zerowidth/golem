#!/usr/bin/env ruby
require "rubygems"
$:.unshift "./lib"

require "golem"
Golem::Session.start("127.0.0.1", :follow => "aniero")
