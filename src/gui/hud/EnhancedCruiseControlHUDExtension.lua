-- @author: 4c65736975, © All Rights Reserved
-- @version: 1.0.0.0, 06|04|2024
-- @filename: EnhancedCruiseControlHUDExtension.lua

local modDirectory = g_currentModDirectory

local function createCruiseControlLockElement(speedMeterDisplay, hudAtlasPath, baseX, baseY)
  local offsetX, offsetY = getNormalizedScreenValues(unpack(CRUISE_CONTROL_LOCK.OFFSET))
  local posX = baseX - speedMeterDisplay.cruiseControlElement:getWidth() + offsetX
  local posY = baseY + offsetY
  local width, height = getNormalizedScreenValues(unpack(CRUISE_CONTROL_LOCK.SIZE))
  local cruiseControlLockOverlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

  cruiseControlLockOverlay:setUVs(GuiUtils.getUVs(CRUISE_CONTROL_LOCK.UV))
  cruiseControlLockOverlay:setColor(unpack(SpeedMeterDisplay.COLOR.CRUISE_CONTROL_OFF))

  local element = HUDElement.new(cruiseControlLockOverlay)

  speedMeterDisplay:addChild(element)

  return element
end

SpeedMeterDisplay.createComponents = Utils.appendedFunction(SpeedMeterDisplay.createComponents, function (self, hudAtlasPath)
  local baseX, baseY = self.cruiseControlElement:getPosition()

  self.cruiseControlLockElement = createCruiseControlLockElement(self, g_baseUIFilename, baseX, baseY)
end)

SpeedMeterDisplay.updateCruiseControl = Utils.appendedFunction(SpeedMeterDisplay.updateCruiseControl, function (self, dt)
  if self.cruiseControlLockElement ~= nil and self.vehicle.getIsCruiseControlLockActive ~= nil then
    self.cruiseControlLockElement:setVisible(self.vehicle:getIsCruiseControlLockActive())
  end

  if self.vehicle.getIsCruiseControlSpeedLockActive ~= nil and self.vehicle:getIsCruiseControlSpeedLockActive() then
    local _, isActive = self.vehicle:getCruiseControlDisplayInfo()

    if not isActive then
      self.cruiseControlColor = CRUISE_CONTROL_SPEED_LOCK.COLOR
      self.cruiseControlElement:setColor(unpack(self.cruiseControlColor))
    end
  end
end)

CRUISE_CONTROL_LOCK = {
  SIZE = {
    10,
    15
  },
  OFFSET = {
    14,
    12
  },
  UV = {
    727,
    7,
    18,
    25
  }
}

CRUISE_CONTROL_SPEED_LOCK = {
  COLOR = {
    1,
    0.08,
    0.08,
    1
  }
}