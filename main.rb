# Everything took me slightly under 10 hours, except the AI that was another 7 hours (argh)

# customizable settings
num_players = 2
difficulty = { easy: 2, medium: 3, hard: 7 }
num_piles = nil  # TBD per difficulty selection
pile_size_max = 5

all_players = {}  
  # elements are
    # name1:{score:#, log:[A-1, B-4, etc] }, 
    # name2:{score:#, log:[history of steps] }, etc
all_piles = {}  
  # elements are {pile1:{qty:#, drawings:[]}, pile2:{qty:#, drawings:[]}, etc}
players_array = []
  # will be populated with the key symbols of player names
  # used in whoGoesFirst() and taking turns

### HELPER FUNCTIONS ###
def whoGoesFirst (all_players)
  # shuffles & returns array of the :names from all_players
  # prints the order based on index position of players_array
  players_array = (all_players.keys.to_a).shuffle
  puts "\n#{players_array[0]} goes first"
  puts "#{players_array[1]} goes second"
  return players_array
end

def newPiles (all_piles, num_piles, pile_size_max)
  # populate new piles randomly, and resets candle drawings
  num_piles.times do |index|
    random_num = rand(2..pile_size_max)
    pile = (index+65).chr.to_sym
    all_piles[pile] = {}
    all_piles[pile][:qty] = random_num
    all_piles[pile][:drawing] = []
  end
end

ghost_art = [
"  .-.",
" (o o)  BOO!",
" | O \\",
" \\    \\",
"  `~~~'",
]

candle_art = {
  flame_top:     "   )   ",
  flame_bottom:  "  (_)  ",
  middle:        "  | |  ",
  bottom:        "__|_|__",
  label:         " < X > ",
  gone:          "_______"
}

def showCandles (all_piles, art_hash)
  puts "Don't let the lights go out on your watch!"
  tallest = 0

  # assemble each candle
  all_piles.each do |name_sym, hash|
    #puts "candle #{name_sym} has #{hash[:qty]}"
    qty = hash[:qty]
    pic = []
    if qty == 0
      pic << art_hash[:gone]
    elsif qty > 0
      pic << art_hash[:flame_top]
      pic << art_hash[:flame_bottom]
      qty.times do |segment|
        if segment < qty -1
          pic << art_hash[:middle]
        elsif segment == qty-1
          pic << art_hash[:bottom]
        else
          puts "bug, check code"
        end
      end
    elsif qty < 0
      puts "bug, check code!"
    end

    # add label and store finished candle in hash
    label = art_hash[:label]
    name = name_sym.to_s
    pic << label.sub("X", name)
    hash[:drawings] = pic

    # keep track of which candle is tallest
    if pic.length > tallest
      tallest = pic.length
    end
  end

  # pad out the top of shorter candles with blank lines
  all_piles.each do |name_sym, hash|
    height = hash[:drawings].length
    #puts "looking at #{name_sym}, candle = #{height} tall"
    if height < tallest
      new_blanks = tallest - height
      #puts "need to pad it out with #{new_blanks} newlines"

      new_blanks.times do 
        hash[:drawings].unshift ("       ")
      end
    end
  end
    
  # print out candles side by side, layer by layer
  tallest.times do |index|
    #puts "building each layer from top, now on index ##{index}"
    all_piles.each do |name_sym, hash|
      print hash[:drawings][index]
    end
    puts ""
  end
end


def showPiles (all_piles)
  puts "Super basic showing of piles..."
  p all_piles
end

def showScore (all_players)
  puts "*** SCORES ***"
  all_players.each do |name, hash|
    print "#{name.to_s}: #{hash[:score]}\n"
  end
end

def showLogs (all_players)
  puts "*** GAME LOG ***"
  all_players.each do |name, hash|
    print "#{name.to_s}'s moves: #{hash[:log]}\n"
  end
end

def roundOver? (all_piles, ghost_art)
  # prints msg & returns true when all piles have been depleted to 0
  all_zero = true
  all_piles.values.each do |hash|
    if hash[:qty] != 0
      all_zero = false
    end
  end
  
  if all_zero == true
    puts "", "*** ROUND OVER ***", ghost_art, ""
    return true
  end
  return false
end

def announceFinalWinner (all_players)
  # BUG!  if the name is super long, then it'll stick out of the box, dont' feel like fixing it right now
  max_score = 1
  winner = []
  all_players.each do |name_sym, hash|
    score = hash[:score]
    if score > max_score
      max_score = score
      winner = [name_sym.to_s]
    elsif score == max_score
      winner << name_sym.to_s
    end
  end

  header = "**** BIG HAND OF APPLAUSE ****"
  padding = "**"
  puts ""
  print padding, header, padding, "\n"
  if winner.length == 2
    print padding, "#{winner[0]}".center(header.length), padding, "\n"
    print padding, "~ tied with ~".center(header.length), padding, "\n"
    print padding, "#{winner[1]}".center(header.length), padding, "\n"
  elsif winner.length == 1
    print padding, " ".center(header.length), padding, "\n"
    print padding, "#{winner[0]} WON!".center(header.length), padding, "\n"
    print padding, " ".center(header.length), padding, "\n"
  else
    puts "what? check code!"
  end
  print padding, "******************************", padding, "\n"
end

def num_to_subtract (desired_remainder_int, starting_int)
  # used in moveByAI()
  # returns integer of the number to subtract from starting_int, in order to reach desired_remainder_int
  # otherwise return false if impossible.  ex: you can't subtract any pos int from 3 to get to 5
  if starting_int > desired_remainder_int
    return (desired_remainder_int - starting_int).abs
  else
    return false
  end
end

def moveByAI(all_piles)
  # Goal is to leave human player piles of [1] or [1,1] or [2,2] for guaranteed AI victory
  # Returns [pile_sym, qty]

  # figure out how many non-zero piles are left
    #.partition {} => new array of [ [trueElementsPer{}], [falseElementsPer{}] ]
  separated_piles = all_piles.each.partition { |name_sym, hash| hash[:qty] > 0 }
  
  piles_qtys_arrays = []
  # recompile data for easier reading
  # format is [[:pile1, qty1],[:pile2, qty2], etc]
  separated_piles[0].each do |data|
    piles_qtys_arrays << [data[0].to_s, data[1][:qty]]
  end

  #puts "### PILES_QTYS_ARRAYS ###\n #{piles_qtys_arrays.inspect}"

  num_piles_left = piles_qtys_arrays.length

  pile_chosen = nil
  qty_chosen = nil

  if num_piles_left == 1
    #AI wants to leave you with [1]
    if piles_qtys_arrays[0][1] != 1
      puts "Victory imminent"
      qty = num_to_subtract(1, piles_qtys_arrays[0][1])
      return [piles_qtys_arrays[0][0], qty]
    else 
      puts "Sigh... you win"
      return [piles_qtys_arrays[0][0], 1]
    end
    
  elsif num_piles_left == 2
    #AI wants to leave you with [2, 2] or [1,1]
    smaller_qty = 0
    pile_chosen_existing_qty = nil
    if piles_qtys_arrays[0][1] < piles_qtys_arrays[1][1]
      smaller_qty = piles_qtys_arrays[0][1]
      pile_chosen = piles_qtys_arrays[1][0]
      pile_chosen_existing_qty = piles_qtys_arrays[1][1]
    elsif piles_qtys_arrays[0][1] > piles_qtys_arrays[1][1]
      smaller_qty = piles_qtys_arrays[1][1]
      pile_chosen = piles_qtys_arrays[0][0]
      pile_chosen_existing_qty = piles_qtys_arrays[0][1]
    else
      # both piles have same quantity
      smaller_qty = piles_qtys_arrays[0][1]
      pile_chosen = [piles_qtys_arrays[0][0], piles_qtys_arrays[1][0]]
      pile_chosen_existing_qty = smaller_qty
    end

    #puts "smaller_qty is #{smaller_qty}"
    #puts "pile_chosen is #{pile_chosen}"
    #puts "pile_chosen_existing_qty is #{pile_chosen_existing_qty}\n\n"

    if smaller_qty == 1
      # if the smaller pile has 1, leave 0 for the other pile
      puts "Victory imminent"
      if pile_chosen.length == 2
        return [pile_chosen[0],1]
      else
        return [pile_chosen[0], pile_chosen_existing_qty]
      end
    elsif smaller_qty == 2 
      if pile_chosen.length == 2
        puts "Sigh... Gonna lose"
        return [piles_qtys_arrays[0][0], piles_qtys_arrays[0][1]]
      else
        # reduce the other pile to 2
        qty = num_to_subtract(2, pile_chosen_existing_qty)
        return [pile_chosen[0], qty]
      end
    else
      # if the smaller pile has 3+, leave 3 for the other pile
      qty = num_to_subtract(3, pile_chosen_existing_qty)
      if qty != false
        return [pile_chosen[0], qty]
      else  # no choice
        return [pile_chosen[0], 1]
      end
    end

  elsif num_piles_left == 3
    # AI wants to leave you with 2 piles, preferably [1,1] or [2,2]
    # be on the lookout for guaranteed winning conditions like [1,1,x] and [2,2,x], where AI would want to eliminate the x pile.
    tally_qty_1 = 0
    tally_qty_2 = 0

    piles_qty_1 = []
    piles_qty_2 = []

    # in cases where there were no pair of 1s or pair of 2s, eliminate the pile with lowest number for a fighting chance
    lowest_qty = piles_qtys_arrays[0][1]
    pile_lowest_qty = piles_qtys_arrays[0][0]
    pile_single_backup = []
    qty_single_backup = nil

    piles_qtys_arrays.each do |array|
      if array[1] == 1
        tally_qty_1 += 1
        piles_qty_1 << array[0]
      elsif array[1] == 2
        tally_qty_2 += 1
        piles_qty_2 << array[0]
      end

      if array[1] < lowest_qty
        lowest_qty = array[1]
        pile_lowest_qty = array[0]
      elsif !(piles_qty_1.include? array[0]) && !(piles_qty_2.include? array[0])
        # pile unaccounted for, use it to populate pile_single_backup.  Why? in case of piles like [2,2,3+]
        pile_single_backup = array[0]
        qty_single_backup = array[1]
      end
    end

    #puts "TESTING: single backups: #{pile_single_backup}, #{qty_single_backup}"

    if tally_qty_1 >= 2
      # "winning condition [1,1,x] reached.  Eliminate pile x"
      if tally_qty_1 == 3
        return [piles_qty_1[0], 1]
      elsif tally_qty_2 == 1
        return [piles_qty_2[0], 2]
      else
        return [pile_single_backup, qty_single_backup]
      end

    elsif tally_qty_2 >= 2
      # "winning condition [2,2,x] reached.  Eliminate pile x"
      if tally_qty_2 == 3
        return [piles_qty_2[0], 2]
      elsif tally_qty_1 == 1
        return [piles_qty_1[0], 1]
      else
        return [pile_single_backup, qty_single_backup]
      end

    else
      ### CONCERN/BUG: but human may detect the pattern of AI and use it for unfair advantage
      # "just get rid of lowest pile #{pile_lowest_qty}, #{lowest_qty}"
      return [pile_lowest_qty, lowest_qty]
    end

  else    # more than 3 piles left
    # not yet approaching ideal conditions, eliminate whole piles until then
    # puts "\n\nAI wants to whittle down to just 2 or 3 piles"
    puts "\n\nBUG HERE!", [piles_qtys_arrays[0][0], piles_qtys_arrays[0][1]]
    return [piles_qtys_arrays[0][0], piles_qtys_arrays[0][1]]
  end
end

def checkNum?(string_variable)  
  # returns True if string_variable can be converted to a number, else False and prints error msg

  # reformat numbers ending in a decimal, such as 3. or 5. otherwise they will fail the following Float() check
  if string_variable[-1] == "."
    string_variable = string_variable[0...-1]
  end
  # will print error msg if unable to convert string_variable to a float  
  begin
    Float(string_variable) 
    return true
  rescue 
    puts "\t#{string_variable} is NOT a valid number"
    return false
  end
end

def convertInt(number_str)
  # takes a numerical string that has passed checkNum?(string_variable), returns it as an integer if it can be a valid integer, otherwise return false
  if number_str.include?(".")
    decimal_index = number_str.index('.')
    #print "decimal is at index #{decimal_index}\n"
    
    if decimal_index + 1 == number_str.length
      # num_str may end in decimal    ex: 5. or 3. are ok
      #print "ending in decimal is ok"
      return number_str.to_i
    else
      # whatever follows decimal may not be 1-9
      curr_index = decimal_index + 1
      while curr_index < number_str.length
        #print "looking at index #{curr_index}, which is #{number_str[curr_index]}\n"
        if number_str[curr_index].to_i > 0
          puts "\t#{number_str} is not a valid integer"
          return false
        end
        curr_index += 1
      end
    end
  end
  return number_str.to_i
end

def spacesOnly (string)
  # returns true if string contains only whitespace
  return string.match? (/\A[\s]+\z/)
end

#### end HELPER FUNCTIONS ####
  

### SET UP players ###
num_players.times do |index|
  # get valid name
  name = nil
  while name == nil
    # will only screen for blank answers, players can use numbers & symbols
    if index == 0
      print "Hello Player ##{index+1}!  What is your name?\t>>> "
    elsif index == 1
      print "Hello Player ##{index+1}!  What is your name?\n"
      print "... Or type AI to play against the computer\t>>> "
    end
      name = gets.chomp.upcase
    if name == "AI"
      puts "You're playing against the computer AI now"
      #name = nil   # activating this line will block AI as an option
    else
      if name.length > 10
        puts "\tToo many characters, how about a shorter name?"
        name = nil
      elsif name == "" || spacesOnly(name) == true
        name = nil
      elsif all_players.keys.include? name.to_sym
        # also blocks both players being AI
        puts "\tThat name is already taken..."
        name = nil
      end
    end

  end

  # initialize player's info hash
  all_players[name.to_sym] = { score: 0, log: [] }
end
#puts "CHECKING: all_players = ", all_players.inspect, ""

### SET UP difficulty level ###
difficulty_input = nil
while difficulty_input == nil
  print "Select level of difficulty: easy, medium, or hard?\t>>> "
  difficulty_input = gets.chomp.upcase
  if difficulty_input[0] == "E"
    difficulty_input = "easy"
  elsif difficulty_input[0] == "M"
    difficulty_input = "medium"
  elsif difficulty_input[0] == "H"
    difficulty_input = "hard"
  else
    difficulty_input = nil
  end
end

# populate new piles randomly, based on difficulty
num_piles = difficulty[difficulty_input.to_sym]
newPiles(all_piles, num_piles, pile_size_max)
#puts "CHECKING all_piles: #{all_piles.inspect}", ""



########## START GAME HERE ###########

# present player order 
players_array = whoGoesFirst (all_players)

keep_playing = true
turn_counter = 0

while keep_playing == true
  index = turn_counter % 2
  curr_player = players_array[index]
  print "\n*** #{curr_player}'s turn ***\n\n"
  showCandles(all_piles, candle_art)

  
  pile_str = nil

  if curr_player != "AI".to_sym
    # prompt for and validate HUMAN player's pile input  
    while pile_str == nil
      print "\nWhich pile would you like to take from?\t>>> "
      pile_str = gets.chomp.upcase
      if pile_str == "" || spacesOnly(pile_str)
        puts "\tNo answer? Come. On."
        pile_str = nil
      elsif (all_piles.keys.to_s.include? pile_str) == false
        puts "\tPile #{pile_str} does not exist"
        pile_str = nil
      elsif all_piles[pile_str.to_sym][:qty] == 0
        puts "\tPile #{pile_str} is empty"
        pile_str = nil
      elsif all_piles[pile_str.to_sym][:qty] > 0
        # acceptable pile chosen, onwards...
        break
      else
        puts "\tunexpected bug here, check code!"
      end
    end  
  
    # prompt for and validate HUMAN player's qty input
    qty_valid = false
    qty_int = 0
    while curr_player != "AI" && qty_valid == false
      print "How many would you like to remove?\t>>> "
      qty_str = gets.chomp

      if qty_str == "" || spacesOnly(qty_str)
        puts "\tNo blank answers"
      elsif checkNum?(qty_str)
      # convertInt(qty_str) returns actual integer or false 
        qty_int = convertInt(qty_str)
        if qty_int 
          if qty_int == 0
            puts "\tZero? That's cheating..."
          elsif qty_int < 0
            puts "\tNo you can't add onto the candle, silly!"
          elsif qty_int > all_piles[pile_str.to_sym][:qty]
            puts "\tThere's not enough in pile to take..."
          else
            qty_valid = true
            break
          end
        end
      end
      # end up here if failed checkNum?() or convertInt(), or an unexpected edge case that would've failed criteria anyway
      qty_valid = false
    end
  
  elsif curr_player == "AI".to_sym
    sleep 0.75
    move = moveByAI(all_piles)
    #puts "TESTING: #{move.inspect}"
    pile_str = move[0]
    qty_int = move[1]
  
  else
    puts "bug, check code"
  end

  # log the move in the player's hash
  move = "#{pile_str}-#{qty_int}"
  all_players[curr_player][:log] << (move)
  
  # update the new qty in all_piles
  all_piles[pile_str.to_sym][:qty] -= qty_int
  

  if (roundOver?(all_piles, ghost_art)) == true
    # score +1 for other player
    winner_index = (turn_counter+1) % 2
    winner = players_array[winner_index]
    all_players[winner][:score] += 1

    # display score & log history
    showScore (all_players)
    puts ""
    showLogs (all_players)


    another_round = nil
    while another_round == nil
      print "\nDo you want another round? Y/N\t>>> "
      decision = gets.chomp.upcase
      if decision.include? "Y"
        another_round = true
        # reset all_piles
        newPiles(all_piles, num_piles, pile_size_max)
        # reset player order & counter
        players_array = whoGoesFirst (all_players)
        turn_counter = 0
        # reset player's gamelog
        all_players.each do |name_sym, hash|
          hash[:log] = []
        end
        
      elsif decision.include? "N"
        another_round = false
        keep_playing = false
        announceFinalWinner (all_players)
      else
        puts "what kind of answer is that?!"
      end
    end

  else 
    # still in the same round, rotate for next player
    turn_counter += 1
  end

  print "\n"*5
end





