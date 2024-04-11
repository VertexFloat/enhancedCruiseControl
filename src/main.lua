-- @author: 4c65736975, © All Rights Reserved
-- @version: 1.0.0.0, 06|04|2024
-- @filename: main.lua

local modName = g_currentModName
local modDirectory = g_currentModDirectory

source(modDirectory .. "src/misc/AdditionalSpecialization.lua")
source(modDirectory .. "src/gui/hud/EnhancedCruiseControlHUDExtension.lua")

FSMissionInfo.smartCruiseControlDistance = 20
FSMissionInfo.cruiseControlLockOnlyOnField = false

local function loadMap(self)
  local missionInfo = g_currentMission.missionInfo

  if missionInfo ~= nil and missionInfo.savegameDirectory ~= nil then
    local xmlFile = loadXMLFile("careerXML", missionInfo.savegameDirectory .. "/careerSavegame.xml")

    if xmlFile ~= nil then
      missionInfo.smartCruiseControlDistance = Utils.getNoNil(getXMLInt(xmlFile, missionInfo.xmlKey .. ".settings.smartCruiseControlDistance"), 20)
      missionInfo.cruiseControlLockOnlyOnField = Utils.getNoNil(getXMLBool(xmlFile, missionInfo.xmlKey .. ".settings.cruiseControlLockOnlyOnField"), false)

      delete(xmlFile)
    end
  end
end

FSBaseMission.loadMap = Utils.appendedFunction(FSBaseMission.loadMap, loadMap)

local function update(self, dt)
  if self.missionInfo ~= nil and self.missionInfo.cruiseControlLockOnlyOnField then
    for _, vehicle in pairs(self.vehicles) do
      if vehicle ~= nil and vehicle.spec_drivable ~= nil and not vehicle:getIsEntered() and not vehicle:getIsOnField() then
        if vehicle:getIsCruiseControlLockActive() and vehicle:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF then
          vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
          vehicle:brake(1)
        end
      end
    end
  end
end

FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, update)

local function onStartMission(self)
  if self.missionInfo ~= nil then
    Logging.info("Savegame Setting 'smartCruiseControlDistance': %s", self.missionInfo.smartCruiseControlDistance)
    Logging.info("Savegame Setting 'cruiseControlLockOnlyOnField': %s", self.missionInfo.cruiseControlLockOnlyOnField)
  end
end

FSBaseMission.onStartMission = Utils.appendedFunction(FSBaseMission.onStartMission, onStartMission)

local function saveToXMLFile(self)
  if self.isValid then
    setXMLInt(self.xmlFile, self.xmlKey .. ".settings.smartCruiseControlDistance", self.smartCruiseControlDistance)
    setXMLBool(self.xmlFile, self.xmlKey .. ".settings.cruiseControlLockOnlyOnField", self.cruiseControlLockOnlyOnField)
  end
end

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, saveToXMLFile)

local isCreated = false
local distanceToIndex = {}
local indexToDistance = {}

local function onFrameOpen(self, superFunc, element)
  superFunc(self, element)

  if not isCreated then
    local headerElement = nil

    for i = 1, #self.boxLayout.elements do
      local elem = self.boxLayout.elements[i]

      if elem:isa(TextElement) then
        headerElement = elem:clone(self.boxLayout)
        headerElement:setText(self.l10n:getText("ui_enhancedCruiseControl", modName))
        break
      end
    end

    if headerElement ~= nil then
      self.boxLayout:removeElement(headerElement)

      local index = #self.boxLayout.elements + 1

      for i = 1, #self.boxLayout.elements do
        if self.boxLayout.elements[i] == self.multiFuelUsage then
          index = i + 1
          break
        end
      end

      table.insert(self.boxLayout.elements, index, headerElement)

      index = index + 1

      local multiSmartCruiseControlDistance = self.multiFuelUsage:clone(self.boxLayout)

      multiSmartCruiseControlDistance.elements[4]:setText(self.l10n:getText("setting_smartCruiseControlDistance", modName))
      multiSmartCruiseControlDistance.elements[6]:setText(self.l10n:getText("toolTip_smartCruiseControlDistance", modName))

      local j = 1
      local distances = {}

      for i = 5, 50 do
        table.insert(distances, tostring(i))

        distanceToIndex[i] = j
        indexToDistance[j] = i

        j = j + 1
      end

      multiSmartCruiseControlDistance:setTexts(distances)

      self.boxLayout:removeElement(multiSmartCruiseControlDistance)

      function multiSmartCruiseControlDistance.onClickCallback(_, ...)
        self:onClickSmartCruiseControlDistance(...)
      end

      multiSmartCruiseControlDistance:setState(distanceToIndex[self.missionInfo.smartCruiseControlDistance])

      table.insert(self.boxLayout.elements, index, multiSmartCruiseControlDistance)

      index = index + 1

      local checkCruiseControlLockOnlyOnField = self.checkAutoMotorStart:clone(self.boxLayout)

      checkCruiseControlLockOnlyOnField.elements[4]:setText(self.l10n:getText("setting_cruiseControlLockOnlyOnField", modName))
      checkCruiseControlLockOnlyOnField.elements[6]:setText(self.l10n:getText("toolTip_cruiseControlLockOnlyOnField", modName))

      self.boxLayout:removeElement(checkCruiseControlLockOnlyOnField)

      function checkCruiseControlLockOnlyOnField.onClickCallback(_, ...)
        self:onClickCruiseControlLockOnlyOnField(...)
      end

      checkCruiseControlLockOnlyOnField:setIsChecked(self.missionInfo.cruiseControlLockOnlyOnField)

      table.insert(self.boxLayout.elements, index, checkCruiseControlLockOnlyOnField)

      headerElement.parent = self.boxLayout
      checkCruiseControlLockOnlyOnField.parent = self.boxLayout
      multiSmartCruiseControlDistance.parent = self.boxLayout
    end

    self.boxLayout:invalidateLayout()

    isCreated = true
  end
end

InGameMenuGameSettingsFrame.onFrameOpen = Utils.overwrittenFunction(InGameMenuGameSettingsFrame.onFrameOpen, onFrameOpen)

InGameMenuGameSettingsFrame.onClickSmartCruiseControlDistance = function (self, state)
  state = indexToDistance[state]

  if self.missionInfo ~= nil and self.missionInfo.smartCruiseControlDistance ~= state then
    self.missionInfo.smartCruiseControlDistance = state

    Logging.info("Savegame Setting 'smartCruiseControlDistance': %s", state)
  end
end

InGameMenuGameSettingsFrame.onClickCruiseControlLockOnlyOnField = function (self, state)
  state = state == CheckedOptionElement.STATE_CHECKED

  if self.missionInfo ~= nil and self.missionInfo.cruiseControlLockOnlyOnField ~= state then
    self.missionInfo.cruiseControlLockOnlyOnField = state

    Logging.info("Savegame Setting 'cruiseControlLockOnlyOnField': %s", state)
  end
end

local function onLeaveVehicle(self, superFunc, wasEntered)
  if not self:getIsCruiseControlLockActive() then
    self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)

    if self.brake ~= nil then
      self:brake(1)
    end
  end

  if wasEntered then
    local spec = self.spec_drivable
    local forceFeedback = spec.forceFeedback

    if forceFeedback.isActive then
      forceFeedback.device:setForceFeedback(forceFeedback.axisIndex, 0, 0)

      forceFeedback.isActive = false
      forceFeedback.device = nil
    end
  end
end

Drivable.onLeaveVehicle = Utils.overwrittenFunction(Drivable.onLeaveVehicle, onLeaveVehicle)