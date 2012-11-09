class IdrisStrategy
  include Logging
  NEED_GROWTH_RATE = 2


  def under_attack? planet
    planet.incoming_hostile > 0
  end


  # Добавить проверки силы планеты и соответствующее решение
  def send_help_from_to(planets, to, needs)
    can_send = []
    planets.each do |from|
      can_send << from if from.ships > needs
    end
    can_send.each{ |p| @pw.issue_order( p, to, needs/can_send.count ) } unless can_send.empty?
  end


  def find_nearest_friends(planet, nearest_count)
    friends = @pw.planets.friendly - [planet]
    return [] if friends.empty?
    friends.each{ |e| e.distance = e.pos.distance( planet.pos ) }
    friends.sort_by{ |e| e.distance }[0..nearest_count]
  end


  def find_nearest_opponent(planet)
    hostiles = @pw.planets.hostile
    return [] if hostiles.empty?
    hostiles.each{ |e|  e.distance = e.pos.distance( planet.pos ) }
    hostiles.sort_by{ |e| e.distance }.first
  end


  # Добавить проверку силы планеты
  def attack( planet, friends, to )
    conquer_ships = to.ships - to.incoming_hostile
    step = 0
    while conquer_ships > 0 && step < 3
      step += 1
      send = planet.ships - conquer_ships / (friends.count + 1)
      send = planet.ships/4 if send < 0
      will_be = planet.ships - send
      if will_be > 1
        @pw.issue_order( planet, to, send )
        conquer_ships -= send
      end
      friends.each do |p|
        break if conquer_ships < 0
        send = p.ships - conquer_ships / (friends.count + 1)
        send = p.ships/3 if send < 0
        will_be = p.ships - send
        if will_be > 1
          @pw.issue_order( p, to, send )
          conquer_ships -= send
        end
      end
    end
  end


  def do_turn planet
    will_be_ships = planet.ships - planet.incoming_hostile + planet.incoming_friendly
    some_cost = will_be_ships / planet.ships.to_f

    if will_be_ships <= 0
      best_friends = find_nearest_friends( planet, 2 )
      send_help_from_to( best_friends, planet, will_be_ships.abs )
    else
      attack_planet = find_nearest_opponent( planet )
      best_friends = find_nearest_friends( planet, 2 )
      attack( planet, best_friends, attack_planet )
    end

  end


  def turn( pw )
    @pw = pw
    my_planents = pw.planets.friendly
    my_planents.each do |planet|
      do_turn( planet )
    end

    #available_ships = pw.planets.friendly.ships
    #
    #flying_ships = pw.fleets.friendly.size
    #
    #return if 1.5 * flying_ships > available_ships
    #
    #center = pw.planets.friendly.center
    #
    #from_planets = pw.planets.friendly.sort_by{|p| p.strength }.reverse
    #
    #if pw.planets.hostile.ships < 0.5 * pw.planets.friendly.ships
    #  target_planets = pw.planets.hostile
    #else
    #  target_planets = pw.planets.other
    #end
    #
    #to = target_planets.sort_by{|p| p.desirability(center)}.reverse
    #
    #attacking_planets = (from_planets.length.to_f / 4).ceil
    #
    #from_planets.take(attacking_planets).each do |from|
    #  count = (from.ships / 2 - from.incoming_hostile)
    #  next unless count > 0
    #  pw.issue_order from, to.length > 1 ? to.shift : to.first, count / 2
    #  pw.issue_order from, to.length > 1 ? to.shift : to.first, count / 2
    #end
  end


end
