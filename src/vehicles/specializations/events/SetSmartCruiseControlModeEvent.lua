-- @author: 4c65736975, © All Rights Reserved
-- @version: 1.0.0.0, 06|04|2024
-- @filename: SetSmartCruiseControlModeEvent.lua

SetSmartCruiseControlModeEvent = {}

local SetSmartCruiseControlModeEvent_mt = Class(SetSmartCruiseControlModeEvent, Event)

InitEventClass(SetSmartCruiseControlModeEvent, "SetSmartCruiseControlModeEvent")

function SetSmartCruiseControlModeEvent.emptyNew()
  return Event.new(SetSmartCruiseControlModeEvent_mt)
end

function SetSmartCruiseControlModeEvent.new(vehicle, state)
  local self = SetSmartCruiseControlModeEvent.emptyNew()

  self.vehicle = vehicle
  self.state = state

  return self
end

function SetSmartCruiseControlModeEvent:readStream(streamId, connection)
  self.vehicle = NetworkUtil.readNodeObject(streamId)
  self.state = streamReadUIntN(streamId, 2)

  self:run(connection)
end

function SetSmartCruiseControlModeEvent:writeStream(streamId, connection)
  NetworkUtil.writeNodeObject(streamId, self.vehicle)

  streamWriteUIntN(streamId, self.state, 2)
end

function SetSmartCruiseControlModeEvent:run(connection)
  if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
    self.vehicle:setSmartCruiseControlMode(self.state, true)
  end

  if not connection:getIsServer() then
    g_server:broadcastEvent(SetSmartCruiseControlModeEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
  end
end

function SetSmartCruiseControlModeEvent.sendEvent(vehicle, state, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(SetSmartCruiseControlModeEvent.new(vehicle, state), nil, nil, vehicle)
    else
      g_client:getServerConnection():sendEvent(SetSmartCruiseControlModeEvent.new(vehicle, state))
    end
  end
end