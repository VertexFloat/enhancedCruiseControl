-- @author: 4c65736975, © All Rights Reserved
-- @version: 1.0.0.0, 06|04|2024
-- @filename: EnhancedCruiseControl.lua

EnhancedCruiseControl = {
  SEND_NUM_BITS = 3,
  SMART_CRUISE_CONTROL_MODE = {
    AUTO = 1,
    FRONT = 2,
    BACK = 3,
    LEFT = 4,
    RIGHT = 5,
    DEACTIVE = 0
  },
  MOD_NAME = g_currentModName,
  MOD_DIRECTORY = g_currentModDirectory
}

source(EnhancedCruiseControl.MOD_DIRECTORY .. "src/vehicles/specializations/events/SetCruiseControlLockStateEvent.lua")
source(EnhancedCruiseControl.MOD_DIRECTORY .. "src/vehicles/specializations/events/SetCruiseControlSpeedLockStateEvent.lua")
source(EnhancedCruiseControl.MOD_DIRECTORY .. "src/vehicles/specializations/events/SetSmartCruiseControlModeEvent.lua")

function EnhancedCruiseControl.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function EnhancedCruiseControl.initSpecialization()
  local schemaSavegame = Vehicle.xmlSchemaSavegame
  local key = "vehicles.vehicle(?)." .. EnhancedCruiseControl.MOD_NAME .. ".enhancedCruiseControl"

  schemaSavegame:register(XMLValueType.INT, key .. "#smartCruiseControlMode", "Current smart cruise control mode")
  schemaSavegame:register(XMLValueType.BOOL, key .. "#isCruiseControlLockActive", "Current cruise control lock state")
  schemaSavegame:register(XMLValueType.BOOL, key .. "#isCruiseControlSpeedLockActive", "Current cruise control speed lock state")
end

function EnhancedCruiseControl.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "raycastCallbackSmartCruiseControl", EnhancedCruiseControl.raycastCallbackSmartCruiseControl)
  SpecializationUtil.registerFunction(vehicleType, "setIsCruiseControlLockActive", EnhancedCruiseControl.setIsCruiseControlLockActive)
  SpecializationUtil.registerFunction(vehicleType, "setIsCruiseControlSpeedLockActive", EnhancedCruiseControl.setIsCruiseControlSpeedLockActive)
  SpecializationUtil.registerFunction(vehicleType, "setSmartCruiseControlMode", EnhancedCruiseControl.setSmartCruiseControlMode)
  SpecializationUtil.registerFunction(vehicleType, "getIsCruiseControlLockActive", EnhancedCruiseControl.getIsCruiseControlLockActive)
  SpecializationUtil.registerFunction(vehicleType, "getIsCruiseControlSpeedLockActive", EnhancedCruiseControl.getIsCruiseControlSpeedLockActive)
  SpecializationUtil.registerFunction(vehicleType, "getSmartCruiseControlMode", EnhancedCruiseControl.getSmartCruiseControlMode)
  SpecializationUtil.registerFunction(vehicleType, "getIfObjectIsValid", EnhancedCruiseControl.getIfObjectIsValid)
end

function EnhancedCruiseControl.registerOverwrittenFunctions(vehicleType)
  SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSpeedLimit", EnhancedCruiseControl.getSpeedLimit)
end

function EnhancedCruiseControl.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "onReadStream", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "onUpdate", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "onDraw", EnhancedCruiseControl)
  SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", EnhancedCruiseControl)
end

function EnhancedCruiseControl:onLoad(savegame)
  self.spec_enhancedCruiseControl = {}
  local spec = self.spec_enhancedCruiseControl

  spec.actionEvents = {}
  spec.isCruiseControlLockActive = false
  spec.cruiseControlLockTexts = {
    pos = g_i18n:getText("action_toggleCruiseControlLockPos"),
    neg = g_i18n:getText("action_toggleCruiseControlLockNeg")
  }
  spec.isCruiseControlSpeedLockActive = false
  spec.cruiseControlSpeedLockTexts = {
    pos = g_i18n:getText("action_toggleCruiseControlSpeedLockPos"),
    neg = g_i18n:getText("action_toggleCruiseControlSpeedLockNeg")
  }
  spec.currentSmartCruiseControlVehicle = nil
  spec.currentSmartCruiseControlMode = EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.DEACTIVE
  spec.currentSmartCruiseControlModeText = g_i18n:getText("action_smartCruiseControlModeSelected")
  spec.smartCruiseControlModeTexts = {
    [EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.DEACTIVE] = g_i18n:getText("action_smartCruiseControlModeDeactive"),
    [EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.AUTO] = g_i18n:getText("action_smartCruiseControlModeAuto"),
    [EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.FRONT] = g_i18n:getText("action_smartCruiseControlModeFront"),
    [EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.BACK] = g_i18n:getText("action_smartCruiseControlModeBack"),
    [EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.LEFT] = g_i18n:getText("action_smartCruiseControlModeLeft"),
    [EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.RIGHT] = g_i18n:getText("action_smartCruiseControlModeRight")
  }
  spec.raycastCollisionMask = CollisionFlag.VEHICLE
end

function EnhancedCruiseControl:onPostLoad(savegame)
  local spec = self.spec_enhancedCruiseControl

  if savegame ~= nil then
    local key = savegame.key .. "." .. EnhancedCruiseControl.MOD_NAME .. ".enhancedCruiseControl"
    local state = savegame.xmlFile:getValue(key .. "#smartCruiseControlMode", spec.currentSmartCruiseControlMode)

    self:setSmartCruiseControlMode(state, true)

    state = savegame.xmlFile:getValue(key .. "#isCruiseControlLockActive", spec.isCruiseControlLockActive)

    self:setIsCruiseControlLockActive(state, true)

    state = savegame.xmlFile:getValue(key .. "#isCruiseControlSpeedLockActive", spec.isCruiseControlSpeedLockActive)

    self:setIsCruiseControlSpeedLockActive(state, true)
  end
end

function EnhancedCruiseControl:onReadStream(streamId, connection)
  if connection:getIsServer() then
    local spec = self.spec_enhancedCruiseControl
    local isLockActive = streamReadBool(streamId)
    local isSpeedLockActive = streamReadBool(streamId)

    self:setIsCruiseControlLockActive(isLockActive, true)
    self:setIsCruiseControlSpeedLockActive(isSpeedLockActive, true)
    self:setSmartCruiseControlMode(streamReadUIntN(streamId, EnhancedCruiseControl.SEND_NUM_BITS), true)
  end
end

function EnhancedCruiseControl:onWriteStream(streamId, connection)
  if not connection:getIsServer() then
    local spec = self.spec_enhancedCruiseControl

    streamWriteBool(streamId, spec.isCruiseControlLockActive)
    streamWriteBool(streamId, spec.isCruiseControlSpeedLockActive)
    streamWriteUIntN(streamId, spec.currentSmartCruiseControlMode, EnhancedCruiseControl.SEND_NUM_BITS)
  end
end

function EnhancedCruiseControl:saveToXMLFile(xmlFile, key, usedModNames)
  local spec = self.spec_enhancedCruiseControl

  xmlFile:setValue(key .. "#smartCruiseControlMode", spec.currentSmartCruiseControlMode)
  xmlFile:setValue(key .. "#isCruiseControlLockActive", spec.isCruiseControlLockActive)
  xmlFile:setValue(key .. "#isCruiseControlSpeedLockActive", spec.isCruiseControlSpeedLockActive)
end

function EnhancedCruiseControl:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
  if self.isClient then
    local spec = self.spec_enhancedCruiseControl

    self:clearActionEventsTable(spec.actionEvents)

    if self:getIsActiveForInput(true, true) and self:getIsEntered() and not self:getIsAIActive() then
      local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CRUISE_CONTROL_LOCK, self, EnhancedCruiseControl.actionEventToggleCruiseControlLock, false, true, false, true, nil)
      g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
      g_inputBinding:setActionEventText(actionEventId, spec.isCruiseControlLockActive and spec.cruiseControlLockTexts.neg or spec.cruiseControlLockTexts.pos)

      _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CRUISE_CONTROL_SPEED_LOCK, self, EnhancedCruiseControl.actionEventToggleCruiseControlSpeedLock, false, true, false, true, nil)
      g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
      g_inputBinding:setActionEventText(actionEventId, spec.isCruiseControlSpeedLockActive and spec.cruiseControlSpeedLockTexts.neg or spec.cruiseControlSpeedLockTexts.pos)

      _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_SMART_CRUISE_CONTROL_MODE, self, EnhancedCruiseControl.actionEventToggleSmartCruiseControlMode, false, true, false, true, nil)
      g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
      g_inputBinding:setActionEventText(actionEventId, spec.currentSmartCruiseControlModeText:format(spec.smartCruiseControlModeTexts[spec.currentSmartCruiseControlMode]))
    end
  end
end

function EnhancedCruiseControl:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
  local isControlled = self.getIsControlled ~= nil and self:getIsControlled()

  if self:getIsCruiseControlLockActive() and self.isServer then
    local spec = self.spec_drivable

    if not isControlled and spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
      local cruiseControlSpeed = math.huge

      if spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
        cruiseControlSpeed = spec.cruiseControl.speed
      end

      local maxSpeed, _ = self:getSpeedLimit(true)
      maxSpeed = math.min(maxSpeed, cruiseControlSpeed)

      self:getMotor():setSpeedLimit(maxSpeed)
      self:updateVehiclePhysics(spec.axisForward, spec.axisSide, spec.doHandbrake, dt)
    end
  end
end

function EnhancedCruiseControl:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
  local spec = self.spec_enhancedCruiseControl

  if self.isClient then
    spec.currentSmartCruiseControlVehicle = nil

    local mode = spec.currentSmartCruiseControlMode

    if mode ~= EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.DEACTIVE then
      if mode == EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.AUTO then
        local closestVehicle = nil
        local closestDistance = math.huge

        for _, vehicle in pairs(g_currentMission.vehicles) do
          local validVehicle = self:getIfObjectIsValid(vehicle)

          if validVehicle then
            local distance = calcDistanceFrom(self.rootNode, vehicle.rootNode)

            if closestDistance > distance and distance <= g_currentMission.missionInfo.smartCruiseControlDistance then
              closestVehicle = vehicle
              closestDistance = distance
            end
          end
        end

        if closestVehicle ~= nil and closestVehicle.getLastSpeed then
          self:setCruiseControlMaxSpeed(closestVehicle:getLastSpeed(), nil)

          spec.currentSmartCruiseControlVehicle = closestVehicle
        end
      else
        local x, y, z = getWorldTranslation(self.rootNode)
        local dirX, dirY, dirZ = self:getVehicleWorldDirection()

        if mode == EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.BACK then
          dirX, dirY, dirZ = -dirX, dirY, -dirZ
        elseif mode == EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.LEFT then
          dirX, dirY, dirZ = dirZ, dirY, -dirX
        elseif mode == EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.RIGHT then
          dirX, dirY, dirZ = -dirZ, dirY, dirX
        end

        local vehicleHeightCenter = self.size.heightOffset + self.size.height / 2
        y = y + vehicleHeightCenter

        raycastClosest(x, y, z, dirX, dirY, dirZ, "raycastCallbackSmartCruiseControl", g_currentMission.missionInfo.smartCruiseControlDistance, self, spec.raycastCollisionMask, false, false)

        if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
          y = y + vehicleHeightCenter + 0.1

          drawDebugArrow(x, y, z, dirX, dirY, dirZ, 0.20, 0.20, 0.20, 0.80, 0, 0, true)
          Utils.renderTextAtWorldPosition(x, y + 0.1, z, "smartCruiseControlRaycast direction", getCorrectTextSize(0.012), 0)
        end
      end
    end
  end
end

function EnhancedCruiseControl:raycastCallbackSmartCruiseControl(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
  if hitActorId ~= nil then
    local spec = self.spec_enhancedCruiseControl
    local object = g_currentMission:getNodeObject(hitActorId)
    local validObject = self:getIfObjectIsValid(object)

    if validObject and object.getLastSpeed ~= nil then
      self:setCruiseControlMaxSpeed(object:getLastSpeed(), nil)

      spec.currentSmartCruiseControlVehicle = object
    end
  end
end

function EnhancedCruiseControl:actionEventToggleCruiseControlLock(actionName, inputValue, callbackState, isAnalog)
  self:setIsCruiseControlLockActive(not self.spec_enhancedCruiseControl.isCruiseControlLockActive)
end

function EnhancedCruiseControl:setIsCruiseControlLockActive(state, noEventSend)
  local spec = self.spec_enhancedCruiseControl

  if spec.isCruiseControlLockActive ~= state then
    SetCruiseControlLockStateEvent.sendEvent(self, state, noEventSend)

    local actionEvent = spec.actionEvents[InputAction.TOGGLE_CRUISE_CONTROL_LOCK]

    if actionEvent ~= nil then
      local text = state and spec.cruiseControlLockTexts.neg or spec.cruiseControlLockTexts.pos
      g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
    end

    spec.isCruiseControlLockActive = state
  end
end

function EnhancedCruiseControl:getIsCruiseControlLockActive()
  return self.spec_enhancedCruiseControl.isCruiseControlLockActive
end

function EnhancedCruiseControl:actionEventToggleCruiseControlSpeedLock(actionName, inputValue, callbackState, isAnalog)
  self:setIsCruiseControlSpeedLockActive(not self.spec_enhancedCruiseControl.isCruiseControlSpeedLockActive)
end

function EnhancedCruiseControl:setIsCruiseControlSpeedLockActive(state, noEventSend)
  local spec = self.spec_enhancedCruiseControl

  if spec.isCruiseControlSpeedLockActive ~= state then
    SetCruiseControlSpeedLockStateEvent.sendEvent(self, state, noEventSend)

    local actionEvent = spec.actionEvents[InputAction.TOGGLE_CRUISE_CONTROL_SPEED_LOCK]

    if actionEvent ~= nil then
      local text = state and spec.cruiseControlSpeedLockTexts.neg or spec.cruiseControlSpeedLockTexts.pos
      g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
    end

    spec.isCruiseControlSpeedLockActive = state
  end
end

function EnhancedCruiseControl:getIsCruiseControlSpeedLockActive()
  return self.spec_enhancedCruiseControl.isCruiseControlSpeedLockActive
end

function EnhancedCruiseControl:actionEventToggleSmartCruiseControlMode(actionName, inputValue, callbackState, isAnalog)
  local currentState = self.spec_enhancedCruiseControl.currentSmartCruiseControlMode
  local nextState = EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE.DEACTIVE
  local maxState = nextState

  for _, state in pairs(EnhancedCruiseControl.SMART_CRUISE_CONTROL_MODE) do
    maxState = math.max(maxState, state)

    if currentState + inputValue == state then
      nextState = state
      break
    end
  end

  if currentState + inputValue < 0 then
    nextState = maxState
  end

  self:setSmartCruiseControlMode(nextState)
end

function EnhancedCruiseControl:setSmartCruiseControlMode(state, noEventSend)
  local spec = self.spec_enhancedCruiseControl

  if spec.currentSmartCruiseControlMode ~= state then
    SetSmartCruiseControlModeEvent.sendEvent(self, state, noEventSend)

    local actionEvent = spec.actionEvents[InputAction.TOGGLE_SMART_CRUISE_CONTROL_MODE]

    if actionEvent ~= nil then
      local text = spec.currentSmartCruiseControlModeText:format(spec.smartCruiseControlModeTexts[state])
      g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
    end

    spec.currentSmartCruiseControlMode = state
  end
end

function EnhancedCruiseControl:getSmartCruiseControlMode()
  return self.spec_enhancedCruiseControl.currentSmartCruiseControlMode
end

function EnhancedCruiseControl:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
  local spec = self.spec_enhancedCruiseControl

  if isActiveForInputIgnoreSelection and spec.currentSmartCruiseControlVehicle ~= nil then
    g_currentMission:addExtraPrintText(g_i18n:getText("info_smartCruiseControlVehicle"):format(spec.currentSmartCruiseControlVehicle:getName()))
  end
end

function EnhancedCruiseControl:getIfObjectIsValid(object)
  local validObject = object ~= nil and object ~= self and object.spec_drivable ~= nil

  if validObject and self.getAttachedImplements ~= nil then
    local implements = self:getAttachedImplements()

    for _, implement in pairs(implements) do
      if implement.object ~= nil and implement.object == object then
        validObject = false
        break
      end
    end
  end

  return validObject
end

function EnhancedCruiseControl:getSpeedLimit(superFunc, onlyIfWorking)
  local spec = self.spec_enhancedCruiseControl
  local limit, doCheckSpeedLimit = superFunc(self, onlyIfWorking)

  if spec and spec.isCruiseControlSpeedLockActive then
    limit = math.min(self:getCruiseControlSpeed(), limit)
  end

  return limit, doCheckSpeedLimit
end
