-- @author: 4c65736975, © All Rights Reserved
-- @version: 1.0.0.0, 07|07|2022
-- @filename: AdditionalSpecialization.lua

local modName = g_currentModName

local function finalizeTypes(self)
  if self.typeName == "vehicle" then
    for typeName, typeEntry in pairs(self:getTypes()) do
      if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) then
        local specialization = modName .. ".enhancedCruiseControl"

        if not SpecializationUtil.hasSpecialization(specialization, typeEntry.specializations) then
          self:addSpecialization(typeName, specialization)
        end
      end
    end
  end
end

TypeManager.finalizeTypes = Utils.appendedFunction(TypeManager.finalizeTypes, finalizeTypes)