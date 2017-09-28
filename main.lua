-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

--remove status bar
display.setStatusBar(display.HiddenStatusBar)

local background = display.newImageRect( "images/blue-sky1.jpeg", 580, 320 )
background.x = display.contentCenterX
background.y = display.contentCenterY
    
-- generate physics engine
local physics = require('physics')

--variables
--enable drawing mode for testing(can use 'normal','debug' or 'hybrid')
physics.setDrawMode("normal")

--enable multi-touch
--system.activate("multitouch")

--find device display height and width
_W = display.contentWidth
_H = display.contentHeight

--score how many balloons were popped
playerScore = 0

--number of balloons variable
balloons = 0

--balloons at the start
numBalloons = 100

--game timer,in seconds,for count-down
startTime = 30

--total amount of time
totalTime = 30

--is there any time left,boolean value
timeLeft = true

--ready to play,boolean value
playerReady = false

--generate random numbers
Random = math.random

--load audio
local music = audio.loadStream("sounds/game-beat.wav")

--pop efx
local popEfx = audio.loadSound("sounds/pop-efx.mp3") 

--text field to display player score
local playerScoreLabel = display.newText("Score: "..playerScore,420,220,native.systemFont,30)
playerScoreLabel:setFillColor(102,0,102)

-- Create a new text field using native device font
local screenText = display.newText("Loading...", 0, 0, native.systemFont, 16*2)
screenText.xScale = 0.5
screenText.yScale = 0.5
screenText.anchorX = 90
screenText.anchorY = 370
screenText.size = 50
screenText:setFillColor(0,0,0)

-- Change the center point
screenText.anchorX = 350
screenText.anchorY = 5

-- Place the text on screen
screenText.x = _W / 2 - 200
screenText.y = _H - 20

-- Create a new text field to display the timer
local timeText = display.newText("Time: "..startTime, 0, 0, native.systemFont, 40)
timeText.xScale = 0.5
timeText.yScale = 0.5

--centre point
timeText.anchorX = 250
timeText.anchorY = 360
timeText.size = 70
timeText:setFillColor(0,0,102)
--place timer display on screen
timeText.x = _W / 2
timeText.y = _H - 20

local gameTimer;

-- Did the player win or lose the game?
local function gameOver(condition)
	-- If the player pops all of the balloons they win
	if (condition == "winner") then
		screenText.text = "Amazing!"
	-- If the player pops 70 or more balloons they did okay
	elseif (condition == "notbad") then
		screenText.text = "Good!"
	-- If the player pops less than 70 balloons they didn't do so well
	elseif (condition == "loser") then
		screenText.text = "Faster!"
        
	end
end 

-- Remove balloons when touched and free up the memory they once used
local function removeBalloons(obj)
	obj:removeSelf();
	-- Subtract a balloon for each pop
	balloons = balloons - 1
    playerScore = playerScore + 1
    playerScoreLabel.text = "Score: "..playerScore
	
	-- If time isn't up then play the game
	if (timeLeft ~= false) then
		-- If all balloons were popped
		if (balloons == 0) then
			timer.cancel(gameTimer)
			gameOver("winner")
		elseif (balloons <= 70) then
			gameOver("notbad")
		elseif (balloons >=71) then
			gameOver("loser")
		end
	end
end

local function countDown(e)
	-- When the game loads, the player is ready to play
	if (startTime == totalTime) then
		-- Loop background music
		audio.play(music, {loops =- 1})
		playerReady = true
		screenText.text = "Quickly!"
	end
	-- Subtract a second from start time
	startTime = startTime - 1
	timeText.text = "Time: "..startTime
	
	-- If remaining time is 0, then timeLeft is false 
	if (startTime == 0) then
    --stop background music loop
        audio.stop()   
		timeLeft = false
        timeText:setFillColor(255,0,0)
        timeText.text = "TIME UP!"
	end
end

-- 1. Start the physics engine
physics.start()

-- 2. Set gravity to be inverted
physics.setGravity(0, -0.4)

--[[ Create "walls" on the left, right and ceiling to keep balloon on screen
	display.newRect(x coordinate, y coordinate, x thickness, y thickness)
	So the walls will be 1 pixel thick and as tall as the stage
	The ceiling will be 1 pixel thick and as wide as the stage 
--]]
local leftWall = display.newRect (0, 0, 0.5, display.contentHeight)
local rightWall = display.newRect (500, 0, 0.5, display.contentHeight)
local ceiling = display.newRect (0, 0, 1040, 0.5)

-- Add physics to the walls. They will not move so they will be "static"
physics.addBody (leftWall, "static",  { bounce = 0.1 } );
physics.addBody (rightWall, "static", { bounce = 0.1 } );
physics.addBody (ceiling, "static",   { bounce = 0.1 } )	

local function startGame()
	-- 3. Create a balloon, 25 pixels by 25 pixels
	local myBalloon = display.newImageRect("images/balloon.png", 25, 25)
	
	-- 4. Set the reference point to the center of the image
	myBalloon.anchorX = 229
    myBalloon.anchorY = 480
	
	-- 5. Generate balloons randomly on the X-coordinate
	myBalloon.x = Random(50, _W-50)
	
	-- 6. Generate balloons 10 pixels off screen on the Y-Coordinate
	myBalloon.y = (_H+10)
	
	-- 7. Apply physics engine to the balloons, set density, friction, bounce and radius
	physics.addBody(myBalloon, "dynamic", {density=0.1, friction=0.0, bounce=0.9, radius=10})
    -- Allow the user to touch the balloons
	function myBalloon:touch(e)
		-- If time isn't up then play the game
		if (timeLeft ~= false) then
			-- If the player is ready to play, then allow the balloons to be popped
			if (playerReady == true) then
				if (e.phase == "ended") then
					-- Play pop sound
					audio.play(popEfx)
					-- Remove the balloons from screen and memory
					removeBalloons(self);
				end
			end
		end
	end
	-- Increment the balloons variable by 1 for each balloon created
	balloons = balloons + 1
	
	-- Add event listener to balloon
	myBalloon:addEventListener("touch", myBalloon)
    -- If all balloons are present, start timer for totalTime (10 sec)
	if (balloons == numBalloons) then
		gameTimer = timer.performWithDelay(1000, countDown, totalTime);
	else
		-- Make sure timer won't start until all balloons are loaded
		playerReady = false;
	end
end

-- 8. Create a timer for the game at 20 milliseconds, spawn balloons up to the number we set numBalloons
gameTimer = timer.performWithDelay(20, startGame, numBalloons);