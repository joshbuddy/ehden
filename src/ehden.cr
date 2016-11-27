require "crsfml"
require "crsfml/audio"

require "./ehden/*"
require "./ehden/maps/*"

module Ehden
  MAX_WIDTH  = 800_f32
  MAX_HEIGHT = 800_f32
end

Ehden::App.start
