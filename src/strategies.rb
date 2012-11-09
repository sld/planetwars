require 'naive_strategy'
require 'reinforce'
require 'idris_strategy'

class Strategies
  def initialize(strategies)
    @strategies = strategies
  end

  def turn(world)
    @strategies.each { |s| s.turn(world) }
  end

  class << self
    def setup
       Strategies.new [
        IdrisStrategy.new
      ]
      #Strategies.new [
      #  NaiveStrategy.new,
      #  Reinforce.new
      #]
    end
  end
end
