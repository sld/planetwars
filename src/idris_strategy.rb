class IdrisStrategy
  include Logging
  @need_growth_rate = nil
  MIN_DISTANCE = 6


  def under_attack? planet
    planet.incoming_hostile > 0
  end


  def hostiles_dead?
    @pw.planets.hostile.empty?
  end


  # Добавить проверки силы планеты и соответствующее решение
  def send_help_from_to(planets, to, needs)
    can_send = []
    planets.each do |from|
      can_send << from if (from.ships - from.incoming_hostile) > needs
    end
    can_send.each do |p|
      have = p.ships - 1
      @pw.issue_order( p, to, have/can_send.count )
    end unless can_send.empty?
  end


  def find_nearest_friends(planet, nearest_count)
    friends = @pw.planets.friendly - [planet]
    return [] if friends.empty?
    friends.each{ |e| e.distance = e.pos.distance( planet.pos ) }
    friends.sort_by{ |e| e.distance }[0..nearest_count]
  end


  def find_nearest_opponent(planet)
    hostiles = @pw.planets.hostile
    return nil if hostiles.empty?
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
      send = planet.ships/3 if send < 0
      will_be = planet.ships - planet.incoming_hostile - send
      if will_be > 1
        @pw.issue_order( planet, to, send )
        conquer_ships -= send
      end
      friends.each do |p|
        break if conquer_ships < 0
        send = p.ships - conquer_ships / (friends.count + 1)
        send = p.ships/3 if send < 0
        will_be = p.ships - p.incoming_hostile - send
        if will_be > 1
          @pw.issue_order( p, to, send )
          conquer_ships -= send
        end
      end
    end
  end


  def find_nearest_passive_and_growthest planet
    passives = @pw.planets.neutral
    return nil if passives.empty?
    passives.each{ |e| e.distance = e.pos.distance( planet.pos ) }
    passives = passives.find_all{ |e| e.growth_rate >= @need_growth_rate }
    passives.empty? ? nil : passives.sort_by{ |e| e.distance }.first
  end


  def conquer_passive_planet(planets, goal_planet)
    need_ships = goal_planet.ships
    planets.each do |p|
      have = p.ships - p.incoming_hostile
      if have > 0
        send = (have - need_ships).abs
        send = have/2 if send > p.ships
        @pw.issue_order( p, goal_planet, send )
      end
    end
  end


  def send_to_most_weak_planet(planet)
    have = planet.ships - planet.incoming_hostile
    if have > 0
      goal = @pw.planets.sort_by{ |e| e.ships }.first
      send = have - goal.ships
      send = have/2 if send < 0
      @pw.issue_order( planet, goal, send )
    end
  end


  # НАДО УЧИТЫВАТЬ СКОЛЬКО ПОСЫЛАТЬ!
  def do_turn planet
    @waiting += 1
    return if hostiles_dead?
    will_be_ships = planet.ships - planet.incoming_hostile + planet.incoming_friendly
    some_cost = will_be_ships / planet.ships.to_f

    nearest_passive_planet = find_nearest_passive_and_growthest( planet )
    attack_planet = find_nearest_opponent( planet )
    my_strength, opponent_strength = [0, 0]
    my_strength = 0
    @pw.planets.friendly.each{|e| my_strength += e.strength}
    @pw.fleets.friendly.each{|e| my_strength += e.size }
    opponent_strength = 0
    @pw.planets.hostile.each{|e| opponent_strength += e.strength}
    @pw.fleets.hostile.each{ |e| opponent_strength += e.size }
    if will_be_ships <= 0
      best_friends = find_nearest_friends( planet, 2 )
      send_help_from_to( best_friends, planet, will_be_ships.abs )
      @waiting = 0
    elsif nearest_passive_planet && nearest_passive_planet.distance < attack_planet.distance && !@opponent_near  && my_strength <= opponent_strength
      planets = find_nearest_friends( planet, 2 ) + [planet]
      conquer_passive_planet( planets, nearest_passive_planet )
      @waiting = 0
    elsif planet.ships >= planet.incoming_hostile
      best_friends = find_nearest_friends( planet, 20 )
      attack( planet, best_friends, attack_planet )
      @waiting = 0
    elsif @waiting == 5
      send_to_most_weak_planet( planet )
      @waiting = 0
    end

  end


  def turn( pw )
    @waiting ||= 0
    @pw = pw
    my_planents = @pw.planets.friendly
    my_planents.each do |mp|
      break if @opponent_near
      @pw.planets.hostile.each do |hp|
        if hp.pos.distance(mp.pos) <= MIN_DISTANCE
          @opponent_near = true
          break
        end
      end
    end


    @need_growth_rate ||= my_planents.first.growth_rate-1
    my_planents.each do |planet|
      do_turn( planet )
    end
    @opponent_near = false
  end


end



# Сравнить с Жанной и гринтеа
# Отчет 1 2 лаба 
#Total rounds: 100  - Захватываем ближайшую планету противника с 2м подкреплением и также защищаем в случае возможности потери своей планеты
#Bot          Wins  Turns
#MyBot.rb       44    103
#DualBot.jar    55     60
#Draw            0      0

#Total rounds: 100   - добавили захват пассивных планет
#Bot          Wins  Turns
#MyBot.rb       50    115
#DualBot.jar    49     69
#Draw            0      0


#Total rounds: 102    - добавили учет силы планеты и близости планеты
#Bot          Wins  Turns
#MyBot.rb       57    184
#DualBot.jar    42    165
#Draw            0      0


# Total rounds: 102    - добавили обязательный ход, если долгое время не было хода
# Bot          Wins  Turns
# MyBot.rb       59    200
# DualBot.jar    40    168
# Draw            0      0


#Total rounds: 102 - добавили проверку близости оппонента - если любая наша планета достаточно близка к оппоненту, то идем на абордаж, иначе пассивная стратегия
#Bot          Wins  Turns
#MyBot.rb       66    162
#DualBot.jar    33    129
#Draw            0      0


#Total rounds: 102 - добавили проверку силы и проверку количества посылаемых корбалей( например учитываем что на нас нападают и если мы пошелм то потеряем планету)
#Bot          Wins  Turns
#MyBot.rb       72    152
#DualBot.jar    27    151
#Draw            0      0


# Total rounds: 102
# Bot              Wins  Turns
# MyBot.rb            0      0
# ZerlingRush.jar    97     52
# Draw                2    301


# Total rounds: 102
# Bot          Wins  Turns
# MyBot.rb       91    206
# bot4.06.jar     8    120
# Draw            0      0
