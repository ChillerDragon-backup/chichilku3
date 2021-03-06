# Player used by Client and Server
require_relative 'console'

SPAWN_X = 512
SPAWN_Y = 100

class Player
  attr_accessor :x, :y, :dy, :dx, :id, :name, :score, :dead, :dead_ticks
  attr_reader :collide, :collide_str, :img_index

  def initialize(id, score, x = nil, y = nil, name = 'def')
    @id = id
    # @x = x
    # @y = y
    @x = x.nil? ? SPAWN_X : x
    @y = y.nil? ? SPAWN_Y : y
    @dx = 0
    @dy = 0
    @collide = {up: false, down: false, right: false, left: false}
    @name = name
    @score = score
    @dead = false # only used by server for now
    @dead_ticks = 0

    # used by client
    @img_index = 0
    @last_x = 0
    @last_y = 0
    @tick = 0
    @not_changed_y = 0
  end

  ###############
  # client only #
  ###############

  def draw_tick
    @tick += 1
    update_img
  end

  def update_img
    return if @tick % 5 != 0
    if @x != @last_x
      new_x = true
    end
    if @y != @last_y
      new_y = true
      @not_changed_y = 0
    else
      @not_changed_y += 1
    end

    if new_x || new_y
      @img_index += 1
      @img_index = 0 if @img_index > 4
      # $console.log "img updated to: #{@img_index}"
    end
    @last_x = @x
    @last_y = @y
    # if @not_changed_y > 10
    #   $console.log "player is chillin"
    #   @img_index = 5
    # end
  end

  #####################
  # client and server #
  #####################
  def self.get_player_index_by_id(players, id)
    players.index(get_player_by_id(players, id))
  end

  def self.get_player_by_id(players, id)
    players.find { |player| id == player.id }
  end

  def self.update_player(players, id, x, y, score)
    player = get_player_by_id(players, id)
    player.x = x
    player.y = y
    player.score = score
    player
  end

  ###############
  # server only #
  ###############
  def tick
    move_x(@dx)
    move_y(@dy)
    @dx = normalize_zero(@dx)
    @dy = normalize_zero(@dy)
    check_out_of_world
  end

  def check_player_collide(other)
    # $console.log "x: #{@x} y: #{@y} ox: #{other.x} oy: #{other.y}"
    # x crash is more rare so make it the outer condition
    if other.x + TILE_SIZE > @x && other.x < @x + TILE_SIZE
      if other.y + TILE_SIZE > @y && other.y < @y + TILE_SIZE
        # $console.log "collide!"
        return @x < other.x ? -7 : 7
      end
    end
    return 0
  end

  # def check_out_of_world #die
  #   # y
  #   if @y < 0
  #     die
  #   elsif @y > WINDOW_SIZE_Y
  #     die
  #   end
  #   # x ( comment me out to add the glitch feature agian )
  #   if @x < 0
  #     die
  #   elsif @x > WINDOW_SIZE_X - TILE_SIZE - 1
  #     die
  #   end
  # end
  def check_out_of_world # swap size
    # y
    if @y < 0
      die
    elsif @y > WINDOW_SIZE_Y
      die
    end
    # x ( comment me out to add the glitch feature agian )
    if @x < 0
      @x = WINDOW_SIZE_X - TILE_SIZE - 2
    elsif @x > WINDOW_SIZE_X - TILE_SIZE - 1
      @x = 0
    end
  end

  def die
    $console.log("[death] name=#{@name} id=#{@id}")
    @x = SPAWN_X
    @y = SPAWN_Y
  end

  #TODO: check for collision before update
  # if move_left or move_right set u on a collided field
  # dont update the position or slow down speed
  # idk make sure to not get stuck in walls
  def move_left
    # @dx = -8
    @x -= 8
  end

  def move_right
    # @dx = 8
    @x += 8
  end

  def apply_force(x, y)
    @dx += x
    @dy += y
  end

  def do_jump
    return if !@collide[:down]

    if @dead 
      @dy = -5
    else
      @dy = -30
    end
  end

  def add_score
    @score += 1 if @score < 9
  end

  def collide_string
    str = "collide:\n"
    str += "down: #{@collide[:down]} up: #{@collide[:up]}\n"
    str += "left: #{@collide[:left]} right: #{@collide[:right]}"
    str
  end

  def do_collide(position, value)
    if position == :right && @dx > 0
      @dx = 0
    elsif position == :left && @dx < 0
      @dx = 0
    elsif position == :down && @dy > 0
      @dy = 0
    elsif position == :up && @dy < 0
      @dy = 0
    end
    @collide[position] = value
  end

  def reset_collide
    @collide = {up: false, down: false, right: false, left: false}
  end

  # create name package str
  def to_n_pck
    name = @name.ljust(5, '_')
    # format("%02d#{name}", @id) # old 2 byte ids
    "#{@id}#{@score}#{name}" # new 1 byte id
  end

  def to_s
    # "#{'%02d' % @id}#{'%03d' % @x}#{'%03d' % @y}" # old 2 byte ids
    "#{@id}#{@score}#{'%03d' % @x}#{'%03d' % @y}" # new 1 byte id
  end

  private

  def move_x(x)
    return if x < 0 && @collide[:left]
    return if x > 0 && @collide[:right]

    @x += x
  end

  def move_y(y)
    return if y < 0 && @collide[:up]
    return if y > 0 && @collide[:down]

    @y += y
  end

  private

  # This method puts the value towards zero
  # used to normalize speed
  def normalize_zero(x)
    return x if x.zero?

    return x - 1 if x > 0
    x + 1
  end
end
