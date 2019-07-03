local Fish = class("Fish", cc.Node)


local pScheduler = cc.Director:getInstance():getScheduler()

local data = {
	moveDirection = 1,
	moveSpeed = 20,
	sprite = "image/game/xiaoyu1.png",
	rotation = 180,
}

local publicConfig = {
	leftX = -100,
	reightX = display.size.width + 100,
}
--执行创建方法
function Fish:onCreate(data_)
    local obj = Fish.new()
    obj.data = data_ --or data
    obj:onInitialize()
    return obj
end

--初始化
function Fish:onInitialize()
	self.sprite = cc.Sprite:create(self.data.sprite)
	self.sprite:addTo(self)
	self.sprite:setPosition(cc.p(0,0))
	local vec3 = {
		x = 0,
		y = self.data.rotation,
		z = 0,
	}
	-- self.sprite:setRotationSkewY(self.data.rotation)
	self.sprite:setRotation3D(vec3)
	self._size = self.sprite:getContentSize()
	self._bodySize = clone(self._size)
	self._bodySize.width = self._bodySize.width - self._bodySize.width * 0.2
	self._bodySize.height = self._bodySize.height - self._bodySize.height * 0.2
	self:init_Move()
	self:initPhysics()

	self.callback = handler(self,self.removeThisSchedule)
end

function Fish:init_Move()
	self.schedule_move = pScheduler:scheduleScriptFunc(handler(self,self.update_Move), 1 / 60, false)
end

function Fish:removeThisSchedule()
	pScheduler:unscheduleScriptEntry(self.schedule_move)
end

function Fish:update_Move(dt)
	local positionX = self:getPositionX() + dt * self.data.moveDirection * self.data.moveSpeed
	self:setPositionX(positionX)
	if (positionX < publicConfig.leftX and self.data.moveDirection < 0) or (positionX > publicConfig.reightX and self.data.moveDirection > 0)then
		self:removeThisSchedule()
		self:removeSelf()
	end
end

function Fish:initPhysics()
	local body = cc.PhysicsBody:createBox(self._bodySize,cc.PhysicsMaterial(0.5, 0, 0))
	body:setCategoryBitmask(2)   	--0010
    body:setContactTestBitmask(1)	--0001
    body:setCollisionBitmask(0)
    -- body:setGravityEnable(true)
    body:setTag(2)
    -- body:setVelocity(cc.pMul(cc.pNormalize(cc.p(-1,0)), icoMoveSpeed))
    -- body:setRotationEnable(false)
    local positionOffset = cc.p(-self._size.width + 50 ,0)
    body:setPositionOffset({x = 0,y = 0})
    self:setPhysicsBody(body)

end

return Fish