-- @author: 4c65736975, © All Rights Reserved
-- @version: 1.0.0.0, 06|04|2024
-- @filename: SetCruiseControlLockStateEvent.lua

SetCruiseControlLockStateEvent = {}

local SetCruiseControlLockStateEvent_mt = Class(SetCruiseControlLockStateEvent, Event)

InitEventClass(SetCruiseControlLockStateEvent, "SetCruiseControlLockStateEvent")

function SetCruiseControlLockStateEvent.emptyNew()
  return Event.new(SetCruiseControlLockStateEvent_mt)
end

function SetCruiseControlLockStateEvent.new(vehicle, state)
  local self = SetCruiseControlLockStateEvent.emptyNew()

  self.vehicle = vehicle
  self.state = state

  return self
end

function SetCruiseControlLockStateEvent:readStream(streamId, connection)
  self.vehicle = NetworkUtil.readNodeObject(streamId)
  self.state = streamReadBool(streamId)

  self:run(connection)
end

function SetCruiseControlLockStateEvent:writeStream(streamId, connection)
  NetworkUtil.writeNodeObject(streamId, self.vehicle)

  streamWriteBool(streamId, self.state)
end

function SetCruiseControlLockStateEvent:run(connection)
  if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
    self.vehicle:setIsCruiseControlLockActive(self.state, true)
  end

  if not connection:getIsServer() then
    g_server:broadcastEvent(SetCruiseControlLockStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
  end
end

function SetCruiseControlLockStateEvent.sendEvent(vehicle, state, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(SetCruiseControlLockStateEvent.new(vehicle, state), nil, nil, vehicle)
    else
      g_client:getServerConnection():sendEvent(SetCruiseControlLockStateEvent.new(vehicle, state))
    end
  end
end