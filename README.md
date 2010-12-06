# Golem: a Minecraft Alpha proxy and bot

## Synopsis

Golem is a transparent proxy and bot for Minecraft Alpha Survival Multiplayer.
It is a tool, not a weapon, so be nice.

## Requirements

* ruby 1.9, only tested on 1.9.2
* [bundler](http://gembundler.com)

## Install & Usage

### Install

    git clone
    git://github.com/aniero/golem.git
    cd golem
    bundle install
    bin/golem --help

### Proxy mode:

    bin/golem [servername [port [listen port]]]

### Standalone:

    bin/golem bot [servername [port]]

## Features

### Proxy

Golem functions as a completely transparent pass-through proxy for the standard
alpha Minecraft client. This allows SMP play as usual, but with a few extra
capabilities.

A few of the client commands (type via say):

* `/time <noon|midnight|dawn|sunset|<integer>>` overrides the server time
* `/gps` or `/where` lists your current coordinates in the world. Handy for
  connecting tunnels and placing things accurately (F3 does this too)
* `/[no]fastdig` allows fast digging, one click block breaking. Careful with
  this as it spams "I am digging" packets.

In addition, golem provides its own console for typing in more complex commands.

* `pos` lists the current position in the world (F3 provides the look position)
* `d[ebug] <off|all|a regular expression>` dumps packet debugs to the console
* `fly <x y z>` is a poor man's teleport. Requires view of the sky! This uses a
  position override hack to attempt to preserve health when falling, but may not
  succeed. Never teleport to y of 127, always know your destination altitude!
* `chunks` lists the number of chunks loaded so far
* `come <player name>` will walk at a reasonable pace to the given player, if a
  short enough path exists
* `follow <player name>` will follow the given player as long as a path exists
* `survey <blueprint> [x y z]` lists out the changes required to build the given
  blueprint, centered at the current location or the given x, y, z
* `build <blueprint> [x y z]` builds the given blueprint at the current location
  or centered at x, y, z. This includes automatic digging, cleanup, and
  placement.
* `nearest <blocktype>` lists the nearest 5 blocks of the given type. Try
  `nearest diamond_ore`, and see `lib/golem/blocks.rb` for a list of the block
  types
* various others, useful mainly for debugging

As falling damage is calculated server-side, golem is mostly incapable of
preventing harm due to downward motion. However, the proxy will automatically
use a golden apple any time damage is sustained. Don't fall too far and all will
be well.

### Standalone

Golem can function as a standalone bot, capable of connecting to a server on its
own. This is intended for debugging rather than full-time use.

### Blueprints

golem can build predefined structures, centered at its current coordinates or a
specified center. Blueprints are specified as a .yml file accompanied by one or
more .png files describing the layers for the given blueprint.

Blueprint PNGs describe individual layers of something to build or clear. The
color code is:

* transparent: don't care, leave it be
* white: smooth stone
* black: air (torches are ignored)
* grey: cobble
* orange: lava
* purple: obsidian
* cyan: glass

For actual RGB values consult `lib/golem/blueprint.rb`.

Blueprint coordinates are in image-local coordinate system, which is:

* image is (x, y)
* 0, 0 is top left
* x increases to the right, y increases downward
* z refers to the layer listed in the yml, 0 at the bottom and increasing upward
  vertically
* Screen-upward is used as north when converting to minecraft map coordinates

The center of a blueprint is defined as a point in image/layer coordinates,
which is converted and used based on the (x, y, z) minecraft coordinate or the
current player position when starting a build.

See `blueprints/` for examples.

### Etc.

Use the force, read the source.

## Contributing

Fork, patch, and send a pull request.
