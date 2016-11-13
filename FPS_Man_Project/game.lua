

local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local json = require( "json" )
local utility = require( "utility" )
local physics = require( "physics" )
local myData = require( "mydata" )
local perspective = require("perspective")
-- 
-- define local variables here
--

local currentScore          -- used to hold the numeric value of the current score
local currentScoreDisplay   -- will be a display.newText() that draws the score on the screen
local levelText             -- will be a display.newText() to let you know what level you're on
local spawnTimer            -- will be used to hold the timer for the spawning engine
local timerRefresh = 1000
local fps_multiplicator = 1
local timerDelay = 0
local dt=1000/30
local player_ghost
local jumpDecrease = 0

camera = perspective.createView()
--
-- define local functions here
--

local function handleLoss( event )
    --
    -- When you tap the "I Loose" button, reset the "gameover" scene, then goto it.
    --
    -- Using a button to end the game isn't realistic, but however you determine to 
    -- end the game, the code below shows you how to call the gameover scene.
    --
    if event.phase == "ended" then
        composer.removeScene("gameover")
        composer.gotoScene("gameover", { time= 500, effect = "crossFade" })
    end
    return true
end


local function spawnPlayer( )
    -- make a local copy of the scene's display group.
    -- since this function isn't a member of the scene object,
    -- there is no "self" to use, so access it directly.
    player = display.newRect(27.5,274.5,30,60)
    local playerCollisionFilter = {categoryBits = 2, maskBits=5}
    player.alpha = 1
    player.isJumping =false
    player.prevX = 27.5
    player.prevY = 274.5
    --rect.isFixedRotation = true
    player.isDead = false;

    return player
end

local function doCam()
    player = display.newRect(27.5,274.5,30,60)
    local playerCollisionFilter = {categoryBits = 2, maskBits=5}
    player.isJumping =false
    player.prevX = 27.5
    player.prevY = 274.5

    return player
end

local function spawnPlayerGhost()

    local player_ghost = display.newRect(27.5,274.5,30,60)
    local playerGhostCollisionFilter = {categoryBits = 8, maskBits = 5}
    player_ghost.alpha = 0
    player_ghost.isJumping =false
    player_ghost.prevX = 27.5
    player_ghost.prevY = 274.5
    player_ghost.direction = nil
    physics.addBody(player_ghost,"dynamic",{bounce = 0.1, filter=playerGhostCollisionFilter})
    
    return player_ghost
end

local function getPlayerGhost()
    return player_ghost
end

local function setJumpDecrease(jd)
    jumpDecrease = jd
end

local function spawnWall(x,y,w,h)
    
    local wall = display.newRect(x,y,w,h)
    local wallCollisionFilter = {categoryBits=1, maskBits=15}
    wall.typ = "ground"
    physics.addBody(wall, "static", {bounce=0.1, filter=wallCollisionFilter})
    local wallG = wall

    return wall, wallG
end

local function spawnPlatform(x,y,w,h)

    local platform = display.newRect(x,y,w,h)
    platform.typ = "ground"
    physics.addBody(platform, "static", {bounce = 0.1})
    platform.collType = "passthru"
    physics.addBody( platform, "static", { bounce=0.0, friction=0.3 } )
    local platformG = platform

    return platform, platformG
end

local function getButton(x,y,w,h)

    local button = display.newRect(x,y,w,h)
    rect:setFillColor(255,0,0)

    return button
end

--
-- This function gets called when composer.gotoScene() gets called an either:
--    a) the scene has never been visited before or
--    b) you called composer.removeScene() or composer.removeHidden() from some other
--       scene.  It's possible (and desirable in many cases) to call this once, but 
--       show it multiple times.
local function increase_fps()
    if(fps_multiplicator < 10)then
        fps_multiplicator = fps_multiplicator*2
    end
end


local function moveLeftButton(event)
    if (event.phase == "ended") then
        getPlayerGhost().direction = "left"
    end
    return true
end
local function moveRightButton(event)
    if event.phase == "ended" then
        getPlayerGhost().direction = "right"
    end
    return true
end

local function moveUpButton(event)
    if event.phase == "ended" then
        jump()
    end
    return true
end

local function moveRight()
    player_ghost.direction = "right"
end

function jump()
    if(jumpDecrease<2)then
        getPlayerGhost():applyLinearImpulse(0,-0.1,getPlayerGhost().x, getPlayerGhost().y)
        jumpDecrease = jumpDecrease + 1
    end

end






function scene:create( event )                                                                                          -- CREATE FUNCTION
    --
    -- self in this case is "scene", the scene object for this level. 
    -- Make a local copy of the scene's "view group" and call it "sceneGroup". 
    -- This is where you must insert everything (display.* objects only) that you want
    -- Composer to manage for you.
    local sceneGroup = self.view

    -- 
    -- You need to start the physics engine to be able to add objects to it, but...
    --

    physics.start()
    physics.setGravity(0,9.8)
    --
    -- because the scene is off screen being created, we don't want the simulation doing
    -- anything yet, so pause it for now.
    --
    physics.pause()
    physics.setDrawMode("normal")
    local thisLevel = myData.settings.currentLevel
    player = spawnPlayer()
    player_ghost = spawnPlayerGhost()
    player_ghost.isFixedRotation = true
    wallL, wallLG = spawnWall(0,160,30,320)
    wallR, wallRG = spawnWall(750,160,30,320)
    floor, floorG = spawnWall(display.contentCenterX,320,1000,30)
    platform, platformG = spawnPlatform(60,200,80,10)
    lButton = widget.newButton({
        id = "lButton",
        label = "Move Left",
        width = 100,
        height = 50,
        onEvent = moveLeftButton
    })
    lButton.x, lButton.y = display.contentCenterX-150, 50

    rButton = widget.newButton({
        id = "rButton",
        label = "Move Right",
        width = 100,
        height = 50,
        onEvent = moveRightButton
    })
    rButton.x, rButton.y = display.contentCenterX+150, 50

    mButton = widget.newButton({
        id = "mButton",
        label = "Jump",
        width = 100,
        height = 50,
        onEvent = jump
    })
    mButton.x, mButton.y = display.contentCenterX, 50

    player_ghost:setFillColor(0.3,0.4,0.5)
    wallL:setFillColor(0,1,0)
    wallR:setFillColor(0,0,1)
    floor:setFillColor(0,0,0)
    platform:setFillColor(1,0,0)
    
    --
    -- These pieces of the app only need created.  We won't be accessing them any where else
    -- so it's okay to make it "local" here
    --
    local background = display.newRect(display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
    background:setFillColor( 0.6, 0.7, 0.3 )
    --
    -- Insert it into the scene to be managed by Composer
    --

    sceneGroup:insert(background)
    sceneGroup:insert(lButton)
    sceneGroup:insert(rButton)
    sceneGroup:insert(mButton)


    camera:add(player, 1)
    camera:add(wallLG,2)
    camera:add(wallRG,2)
    camera:add(floor,2) 
    camera:add(player_ghost,1)
    camera:add(platform,2)

    --
    -- levelText is going to be accessed from the scene:show function. It cannot be local to
    -- scene:create(). This is why it was declared at the top of the module so it can be seen 
    -- everywhere in this module
    levelText = display.newText(myData.settings.currentLevel, 0, 0, native.systemFontBold, 48 )
    levelText:setFillColor( 0 )
    levelText.x = display.contentCenterX
    levelText.y = display.contentCenterY
    --
    -- Insert it into the scene to be managed by Composer
    --
    sceneGroup:insert( levelText )

    -- 
    -- because we want to access this in multiple functions, we need to forward declare the variable and
    -- then create the object here in scene:create()
    --
    currentScoreDisplay = display.newText("000000", display.contentWidth - 50, 10, native.systemFont, 16 )
    sceneGroup:insert( currentScoreDisplay )

    --
    -- these two buttons exist as a quick way to let you test
    -- going between scenes (as well as demo widget.newButton)
    --

    local iWin = widget.newButton({
        label = "I Win!",
        onEvent = increase_fps
    })
    sceneGroup:insert(iWin)
    iWin.x = display.contentCenterX - 100
    iWin.y = display.contentHeight - 60

    local iLoose = widget.newButton({
        label = "I Loose!",
        onEvent = handleLoss
    })
    sceneGroup:insert(iLoose)
    iLoose.x = display.contentCenterX + 100
    iLoose.y = display.contentHeight - 60

end

--
-- This gets called twice, once before the scene is moved on screen and again once
-- afterwards as a result of calling composer.gotoScene()
--
function scene:show( event )                                                                                            --SCENE FUNCTION
    --
    -- Make a local reference to the scene's view for scene:show()
    --
    local sceneGroup = self.view

    function onPreCollision( self, event )
 
        local collideObject = event.other
        if ( collideObject.collType == "passthru" and self.isJumping==true) then
            event.contact.isEnabled = false  -- disable this specific collision!
        elseif((collideObject.collType == "passthru" and self.isJumping==false) or collideObject.typ=="ground")then
            setJumpDecrease(0)
        end
    end
    getPlayerGhost().preCollision = onPreCollision
    getPlayerGhost():addEventListener( "preCollision", getPlayerGhost())


    function player_ghost:enterFrame()
    
        if(getPlayerGhost().direction == nil)then 
            getPlayerGhost().x = getPlayerGhost().x
        end

        if(getPlayerGhost().direction == "right")then
            getPlayerGhost().x = getPlayerGhost().x + 1
        elseif(getPlayerGhost().direction == "left")then 
            getPlayerGhost().x = getPlayerGhost().x - 1
        end

        if getPlayerGhost().prevY ~= getPlayerGhost().y then
            if getPlayerGhost().y > getPlayerGhost().prevY then
                getPlayerGhost().isJumping = false
            elseif getPlayerGhost().y < getPlayerGhost().prevY then
                getPlayerGhost().isJumping = true
            end
        end
        
        getPlayerGhost().prevX, getPlayerGhost().prevY = getPlayerGhost().x, getPlayerGhost().y

        if(timerDelay >= timerRefresh/fps_multiplicator)then
            local middleOfScreen = 275
            local endOfLevel = 724
            -- if(player.x < (middleOfScreen))then --if player did not leave start yet or goes back to start
            --    camera:cancel()
            --elseif(player.x > (endOfLevel-middleOfScreen)+15)then --if the player gets near the end
            --    camera:cancel()
            --else --if the player leaves the end or start area and is between both of them camera will be attached
                camera.damping = 10 -- A bit more fluid tracking
                camera:setFocus(player) -- Set the focus to the player
                camera:setBounds(200,500,200,400)
                camera:track() -- Begin auto-tracking
            --end
            player.x = player_ghost.x
            player.y = player_ghost.y
            timerDelay=0
        end
        timerDelay = timerDelay +dt

    end

    Runtime:addEventListener("enterFrame", getPlayerGhost())
    
    if event.phase == "did" then
        physics.start()
        transition.to( levelText, { time = 500, alpha = 0 } )
        spawnTimer = timer.performWithDelay( 500, spawnEnemies )
    else -- event.phase == "will"
        -- The "will" phase happens before the scene transitions on screen.  This is a great
        -- place to "reset" things that might be reset, i.e. move an object back to its starting
        -- position. Since the scene isn't on screen yet, your users won't see things "jump" to new
        -- locations. In this case, reset the score to 0.
        currentScore = 0
        currentScoreDisplay.text = string.format( "%06d", currentScore )
    end


end


--
-- This function gets called everytime you call composer.gotoScene() from this module.
-- It will get called twice, once before we transition the scene off screen and once again 
-- after the scene is off screen.
function scene:hide( event )                                                                                            --HIDE FUNCTION
    local sceneGroup = self.view
    
    if event.phase == "will" then
        -- The "will" phase happens before the scene is transitioned off screen. Stop
        -- anything you started elsewhere that could still be moving or triggering such as:
        -- Remove enterFrame listeners here
        -- stop timers, phsics, any audio playing
        --
        physics.stop()
        timer.cancel( spawnTimer )
    end

end

--
-- When you call composer.removeScene() from another module, composer will go through and
-- remove anything created with display.* and inserted into the scene's view group for you. In
-- many cases that's sufficent to remove your scene. 
--
-- But there may be somethings you loaded, like audio in scene:create() that won't be disposed for
-- you. This is where you dispose of those things.
-- In most cases there won't be much to do here.
function scene:destroy( event )                                                                                         --DESTROY FUNCTION
    local sceneGroup = self.view
    
end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
return scene
