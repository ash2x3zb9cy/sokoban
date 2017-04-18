--require 'cupid'
inspect = require 'inspect'
gamera = require 'gamera'
cam = gamera.new(0, 0, 1, 1)
--[[ sokoban.org format
 @: player
 +: player on goal
 $: box
 *: box on goal
 #: wall
.: goal
-: floor
]]
levels = {
[[
----#####----------
----#---#----------
----#$--#----------
--###--$##---------
--#--$-$-#---------
###-#-##-#---######
#---#-##-#####--..#
#-$--$----------..#
#####-###-#@##--..#
----#-----#########
----#######--------
]],
[[
############
#..  #     ###
#..  # $  $  #
#..  #$####  #
#..  - @ ##  #
#..  # #  $ ##
###### ##$ $ #
  # $  $ $ $ #
  #    #     #
  ############
]],
[[
        ########
        #     @#
        # $#$ ##
        # $  $#
        ##$ $ #
######### $ # ###
#....  ## $  $  #
##...    $  $   #
#....  ##########
########
]]
}

function trace(str)
	--table.insert(debug, 1, str)
end

function parseLevel(levelid)
	moveCount[levelid] = 0
	pushCount[levelid] = 0
	local tbl = strTo2d(levels[levelid], parseChar)
	cam:setWorld(32, 32, #tbl[1]*32, #tbl*32)
	return tbl
end

function Goal()
	return 1
end

function Box()
	return 2
end

function parseChar(char, x, y, row, tbl)
	if row.objects == nil then
		row.objects = {goals = {}, boxes = {}}
	end

	-- player or player on goal
	if char == '@' or char == '+' then
		player.x = x
		player.y = y
		cam:setPosition(x*32, y*32)
	end

	-- goal or box on goal or player on goal
	if char == '.' or char == '*' or char == '+' then
		-- goal is here
		--table.insert(row.objects.goals, x)
		row.objects.goals[x] = x
	end

	-- box or box on goal
	if char == '$' or char == '*' then
		-- box is here
		--table.insert(row.objects.boxes, x)
		row.objects.boxes[x] = x
	end

	if char == '#' then
		-- wall is here
		-- floor is NOT here
		return false
	else
		return true
	end

end

function love.load()
	debug = {}

	moveCount = {0}
	pushCount = {0}

	-- graphicsz
	sprites = {
		player = love.graphics.newImage('assets/player.png'),
		goal = love.graphics.newImage('assets/goal.png'),
		box = love.graphics.newImage('assets/box.png'),
		wall = love.graphics.newImage('assets/wall.png'),
	}

	local st2d = require 'strTo2d'
	player = {x= 0, y=0}
	currentLevel = 1
	level = parseLevel(currentLevel)
	won = false


	mode = 'menu'
end

function love.draw()
	if mode == 'menu' then
		draw_mm()
	else
		-- hud
		love.graphics.print("Move count: " .. moveCount[currentLevel], 16, 16)
		love.graphics.print("Push count: " .. pushCount[currentLevel], 16, 32)
		cam:draw(draw_level)
	end
end

function clamp(low, x, high)
	return math.max(low, math.min(x, high))
end

-- love.draw
function draw_mm()
	love.graphics.print("SOKOBAN", 80, 80)
	if won then
		local summ = 0
		for i,v in ipairs(moveCount) do
			summ = summ + v
		end
		local sump = 0
		for i, v in ipairs(pushCount) do
			sump = sump + v
		end
		love.graphics.print('You beat the game in ' .. summ .. ' moves and ' .. sump .. ' pushes!', 80, 96)
		love.graphics.print('I couldn\'t be bothered to do any more levels.', 80, 112)
	else
		love.graphics.print('WASD to move. Push the boxes onto the spots.', 80, 96)
		love.graphics.print('Esc to exit. Any other key to start the game.', 80, 128)
	end
end

-- love.draw
function draw_level()
	-- walls
	for y, row in ipairs(level) do
		for x, v in ipairs(row) do
			if not level[y][x] then
				love.graphics.draw(sprites.wall, x*32, y*32)
			end
		end

		-- this row has some objects too
		for k, x in pairs(row.objects.goals) do
			love.graphics.draw(sprites.goal, x*32, y*32)
		end
		for k, x in pairs(row.objects.boxes) do
			love.graphics.draw(sprites.box, x*32, y*32)
		end
	end

	-- player
	love.graphics.draw(sprites.player, player.x*32, player.y*32)

	for i, v in ipairs(debug) do
		love.graphics.print(v, 0, i*16)
	end

	local mx, my = love.mouse.getPosition()
	mx, my = screentoworld(mx, my)
	--love.graphics.print(player.x ..', '..player.y , 100, 16)
end

function move(x, y)
	dx = x - player.x
	dy = y - player.y
	if math.abs(dx)>1 or math.abs(dy)>1 then return false end
	local is_floor = level[y][x]
	local has_box = level[y].objects.boxes[x] ~= nil

	-- local has_goal = level[y].objects.goals[x] ~= nil
	local valid = is_floor and (not has_box or (
		level[y+dy][x+dx] -- next is floor
		and level[y+dy].objects.boxes[x+dx] == nil -- next is box
		))

	if valid then
		if has_box then
			-- push!
			level[y+dy].objects.boxes[x+dx] = x+dx
			level[y].objects.boxes[x] = nil

			pushCount[currentLevel] = pushCount[currentLevel] + 1
		end
		player.x = x
		player.y = y

		moveCount[currentLevel] = moveCount[currentLevel] + 1

		cam:setPosition(player.x*32, player.y*32)
	end

	-- gotta check for victory!
	won = true
	for y,row in ipairs(level) do
		-- numerically indexed but not really
		for x, goal in pairs(row.objects.goals) do
			if level[y].objects.boxes[x] == nil then won = false end
		end
	end

	if won then
		currentLevel = currentLevel + 1
		if currentLevel > #levels then
			-- game finish!
			mode = 'menu'
		else
			level = parseLevel(currentLevel)
			cam:setPosition(player.x*32, player.y*32)
		end
	end
end

function boolstr(x)
	return x and 'yes' or 'no'
end

function screentoworld(x, y)
	local mx = clamp( 1, math.floor(x / 32), #level[1])
	local my = clamp( 1, math.floor(y / 32), #level)
	return mx, my
end

function love.mousepressed(x, y, button, isTouch)
	x,y = screentoworld(x,y)
end

-- love.keypressed
function love.keypressed(key)
	if key == 'escape' then love.event.quit() end

	if mode == 'menu' then
		mode = 'level1'
		currentLevel = 1
		level = parseLevel(currentLevel)
		return
	end
	if key == 'r' then level = parseLevel(currentLevel) end

	if key == 'w' then
		move(player.x, player.y-1)
		return
	end
	if key == 's' then
		move(player.x, player.y+1)
		return
	end
	if key == 'a' then
		move(player.x-1, player.y)
		return
	end
	if key == 'd' then
		move(player.x+1, player.y)
		return
	end

end
