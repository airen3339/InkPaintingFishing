
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local Fish = require("src.app.views.Fish")
local GameConfig = require("src.app.views.GameConfig")

local shipWidth = 400
local configGame = {
	stringMin = 40,
	stringMax = 580,

	playerLeftOfferX = shipWidth * 0.5,
	playerRightOfferX = display.size.width - shipWidth * 0.5,
}


local ramCreateFishDelayTimeMin = 1 --生产鱼等待时间最小值
local ramCreateFishDelayTimeMax = 5 --生产鱼等待时间最大值

local ramFishMoveSpeedMin = 20 		--所有鱼移动的最小速度
local ramFishMoveSpeedMax = 200		--所有鱼移动的最大速度

local stringSpeed = 80				--钩子移动的速度

local CurrentLevel = 1				--当前关卡等级

local pScheduler = cc.Director:getInstance():getScheduler()

local csbFilePath = 'res/InkPaintingFishingMainLayer.csb'

function MainScene:onCreate()
	self._csbNode = cc.CSLoader:createNode(csbFilePath)
	self._csbNode:addTo(self)
	self._layout = self._csbNode:getChildByName('Layout')

	self:initMainPanel()
	self:initHelpPanel()
	self:initGamePanel()
	self:initGameOverPanel()
	AudioEngine.playMusic('res/audio/bg.mp3',true)

end
function MainScene:initMainPanel()
	self._mainPanel = self._layout:getChildByName('Main_Panel')

	-- self._mainPanel:setVisible(false)

	self._mainPanel:getChildByName('Button_Start'):addClickEventListener(function()
		self._mainPanel:setVisible(false)
		self._gamePanel:setVisible(true)
		self:resetGame()
	end)
	self._mainPanel:getChildByName('Button_Help'):addClickEventListener(function()
		self._mainPanel:setVisible(false)
		self._helpPanel:setVisible(true)
	end)
end

function MainScene:initHelpPanel()
	self._helpPanel = self._layout:getChildByName('Help_Panel')

	self._helpPanel:setVisible(false)

	self._helpPanel:getChildByName('Button_Close'):addClickEventListener(function()
		self._mainPanel:setVisible(true)
		self._helpPanel:setVisible(false)
	end)
end

function MainScene:initGameOverPanel()
	self._overPanel = self._layout:getChildByName('Over_Panel')
	self._continueGameButton = self._overPanel:getChildByName("Button_Continue")
	self._continueGameButton:addClickEventListener(function()
		self._overPanel:setVisible(false)
		self._gamePanel:setVisible(true)
		self:resetGame()
	end)
	self._overPanel:setVisible(false)
end

function MainScene:initGamePanel()
	self._gamePanel = self._layout:getChildByName('Game_Panel')
	self._gamePanel:setVisible(false)

	self._playerNode = self._gamePanel:getChildByName('Player')

	self._playerString = self._playerNode:getChildByName('Image_string')

	self._number = self._gamePanel:getChildByName('Number')

	self._remaining = self._gamePanel:getChildByName('Remaining')

	-- self._gamePanel:addTouchEventListener(handler(self,self.gamePlayerTouch))
	self._gamePanel:onTouch(handler(self,self.gamePlayerTouch))
	-- self._gamePanel:setVisible(false)

	self:UpSetLevel()
	self:playerInit()
	--循环生产鱼
	self:startCreateFish()

	self._gamePanel:getChildByName('Button_BackMain'):addClickEventListener(function()
		self._gamePanel:setVisible(false)
		self._mainPanel:setVisible(true)
	end)

end

function MainScene:resetGame()
	self._number.num = 0
	self._remaining.num = GameConfig[CurrentLevel].remaining
	self:updateShowNumber()
end

function MainScene:UpSetLevel()
	ramCreateFishDelayTimeMin = GameConfig[CurrentLevel].ramCreateFishDelayTimeMin --生产鱼等待时间最小值
	ramCreateFishDelayTimeMax = GameConfig[CurrentLevel].ramCreateFishDelayTimeMax --生产鱼等待时间最大值
	ramFishMoveSpeedMin = GameConfig[CurrentLevel].ramFishMoveSpeedMin 		--所有鱼移动的最小速度
	ramFishMoveSpeedMax = GameConfig[CurrentLevel].ramFishMoveSpeedMax		--所有鱼移动的最大速度
	stringSpeed = GameConfig[CurrentLevel].stringSpeed				--钩子移动的速度

	self._number.num = 0
	if not self._number.oldNum then
		self._number.oldNum = self._number.num
	end
	self._number.oldNum = self._number.oldNum + GameConfig[CurrentLevel].nextCountFish
	self._remaining.oldNumber = GameConfig[CurrentLevel].remaining
	self._remaining.num = GameConfig[CurrentLevel].remaining
	-- self._remaining:setString('.' .. self._remaining.num)
	self:updateShowNumber()
end


function MainScene:updateShowNumber()
	local str = string.format("%s/%s",self._number.num,self._number.oldNum)
	print(str)
	self._number:setString(str)

	self._remaining:setString('.' .. self._remaining.num)
	if self._remaining.num == 0 then
		print('失败了-----------')
		self:gameOver()
	elseif self._number.num == self._number.oldNum then
		CurrentLevel = CurrentLevel + 1
		self:UpSetLevel()
	end
end

function MainScene:playerInit()
	-- local size = self._playerString:getContentSize()
	-- dump(size,'size')
	self._playerString:setContentSize({height = 50,width = 15})
	self:initUpdateInfo()
	self:initGouPhysics()


   local playerSpineShip = sp.SkeletonAnimation:create("action/fishing_wave/fishing_wave.json", "action/fishing_wave/fishing_wave.atlas", 1.0)
   playerSpineShip:addTo(self._playerNode)
   :setPosition(cc.p(0,-110 * 0.5))
   playerSpineShip:setAnimation(0,"animation",true)

	self.isDownGou = true --是否可以下勾
end

function MainScene:initGouPhysics()
	self._gouNode = self._playerString:getChildByName('Node_')
	local goubody = cc.PhysicsBody:createBox({width = 5, height = 10}, cc.PhysicsMaterial(1, 0, 0))
    goubody:setCategoryBitmask(1)    --	0001
    goubody:setContactTestBitmask(2) -- 0010
    goubody:setCollisionBitmask(0)
    -- goubody:setDynamic(false)
    -- goubody:setRotationEnable(false)
    goubody:setTag(1)
    -- goubody:setGravityEnable(false)
    goubody:setPositionOffset(cc.p(0,0))
    -- goubody:setDynamic(false)

    self._gouNode:setPhysicsBody(goubody)
    print(self._gouNode:getPhysicsBody())

    local contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(handler(self,self.onCollisionHandling), cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)

    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(contactListener,self)
end

function MainScene:onCollisionHandling(contact)
	if self._haveFish then
		return
	end
	print("onCollisionHandling --------")
	local pBodyA = contact:getShapeA():getBody()
    local pBodyB = contact:getShapeB():getBody()

    local aTag = pBodyA:getTag()
    local bTag = pBodyB:getTag()

    local fishBody = pBodyB
    if aTag == 2 then
    	fishBody = pBodyA
    end

    self:catchFIsh(fishBody:getOwner())
end

function MainScene:catchFIsh(fish)
	if not fish then return end
	    --起钩 不要勾住任何鱼 并且不能再次下勾
    fish:removeThisSchedule()
    fish:retain()
    fish:removeFromParent()
    fish:addTo(self._gouNode)
    -- local pos = self._gouNode:convertToNodeSpaceAR(fish:convertToWorldSpaceAR(cc.p(0,0)))
    fish:setPosition(cc.p(0,0))

    self._haveFish = fish
    self.stringDirection = -1
	AudioEngine.playEffect('res/audio/gou.mp3')

	-- self.isDownGou = false
end

local time = 0
function MainScene:gamePlayerTouch(event)
	if event.name == 'began' then
		self._playerNode.beganPosX = self._playerNode:getPositionX()
		time = os.clock()
	elseif event.name == 'moved' then
		local offsetX = event.target:getTouchMovePosition().x - event.target:getTouchBeganPosition().x
		self:movePlayer(offsetX)
	elseif event.name == 'ended' then
		--是否可以下勾
		if math.abs(event.target:getTouchEndPosition().x - event.target:getTouchBeganPosition().x) <= 5 and self.isDownGou then
			local ofTime = os.clock() - time
			if ofTime < 0.025 then
				print('点击')
				self.stringRun = true
				self.stringDirection = 1
				self.isDownGou = false
				AudioEngine.playEffect('res/audio/gou.mp3')
			end
		end
	end
end

function MainScene:movePlayer(offsetX)
	local offset = self._playerNode.beganPosX + offsetX
	if offset < configGame.playerLeftOfferX or offset > configGame.playerRightOfferX then
		return
	end
	self._playerNode:setPositionX(self._playerNode.beganPosX + offsetX)
end

-- pScheduler:unscheduleScriptEntry(self.schedule_Jackpot_Player_Info)
-- self.schedule_Jackpot_Player_List = pScheduler:scheduleScriptFunc(update, 3, false)

function MainScene:initUpdateInfo()
	self.schedule_string = pScheduler:scheduleScriptFunc(handler(self,self.updateString), 1 / 60, false)
end

function MainScene:updateString(dt)
	if not self.stringRun then
		return
	end
	local sizeString = self._playerString:getContentSize()
	sizeString.height = sizeString.height + stringSpeed * self.stringDirection * dt
	self._playerString:setContentSize(sizeString)
	if sizeString.height >= configGame.stringMax then
		self.stringDirection = -1
		AudioEngine.playEffect('res/audio/gou.mp3')

	elseif sizeString.height <= configGame.stringMin then
		self.stringDirection = 0
		self.stringRun = false
		self.isDownGou = true
		self:checkFish()

	end

end

function MainScene:checkFish()
	if self._haveFish then
		if self._haveFish.data.enemy == 1 then
			print('勾住了大鱼')
			self._remaining.num = self._remaining.num - 1
		else
			self._number.num = (self._number.num or 0) + 1
		end
		self:updateShowNumber()

		self._haveFish:removeSelf()
		self._haveFish = nil
	end
end

function MainScene:startCreateFish()
	local actions = {}
	local delayTime = math.random(ramCreateFishDelayTimeMin,ramCreateFishDelayTimeMax)
	actions[#actions + 1] = cc.DelayTime:create(delayTime)
	actions[#actions + 1] = cc.CallFunc:create(function()
		self:startCreateFish()
	end)
	self._gamePanel:runAction(cc.Sequence:create(actions))
	self:randomCreateFish()
end

function MainScene:randomCreateFish()
	local birthPointYMin = 40     	--出生的最低位置
	local birthPointYMax = 450		--出生的最高位置

	local enemy = math.random(1,2) 	--大雨还是小鱼  1 大鱼 2 小鱼

	local maxId = 0
	if enemy == 1 then
		maxId = 4
	else
		maxId = 6
	end
	local fishId = math.random(1,maxId) --随机鱼的id
	local birthPointY = math.random(birthPointYMin,birthPointYMax) --随机出生的Y坐标
	local birthDirection = math.random(1,2) --随机出生的x. 是左还是右 1左。2右


	-- local data = {
	-- 	moveDirection = 1,
	-- 	moveSpeed = 20,
	-- 	sprite = "image/game/xiaoyu1.png",
	-- 	rotation = 180,
	-- }
	local data = {}
	data.moveDirection = birthDirection == 1 and 1 or -1
	data.sprite = string.format("image/game/%s%s.png",enemy == 1 and 'dayu' or 'xiaoyu',fishId)
	data.rotation = birthDirection == 1 and 180 or 0
	data.moveSpeed = math.random(ramFishMoveSpeedMin,ramFishMoveSpeedMax)
	data.enemy = enemy
	local fish = Fish:onCreate(data)
	fish:addTo(self._gamePanel)
	local pos = {
		x = birthDirection == 1 and -fish._size.width or display.size.width + fish._size.width,
		y = birthPointY,
	}
	fish:setPosition(pos)
	-- fish:init_Move()
end

function MainScene:gameOver()
	self._overPanel:setVisible(true)
	self._gamePanel:setVisible(false)
end


return MainScene
