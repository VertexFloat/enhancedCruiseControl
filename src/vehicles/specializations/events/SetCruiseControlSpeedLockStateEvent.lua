-- SetCruiseControlSpeedLockStateEvent.lua
--
-- author: 4c65736975
--
-- Copyright (c) 2024 VertexFloat. All Rights Reserved.
--
-- This source code is licensed under the GPL-3.0 license found in the
-- LICENSE file in the root directory of this source tree.

SetCruiseControlSpeedLockStateEvent = {}

local SetCruiseControlSpeedLockStateEvent_mt = Class(SetCruiseControlSpeedLockStateEvent, Event)

InitEventClass(SetCruiseControlSpeedLockStateEvent, "SetCruiseControlSpeedLockStateEvent")

function SetCruiseControlSpeedLockStateEvent.emptyNew()
  return Event.new(SetCruiseControlSpeedLockStateEvent_mt)
end

function SetCruiseControlSpeedLockStateEvent.new(vehicle, state)
  local self = SetCruiseControlSpeedLockStateEvent.emptyNew()

  self.vehicle = vehicle
  self.state = state

  return self
end

function SetCruiseControlSpeedLockStateEvent:readStream(streamId, connection)
  self.vehicle = NetworkUtil.readNodeObject(streamId)
  self.state = streamReadBool(streamId)

  self:run(connection)
end

function SetCruiseControlSpeedLockStateEvent:writeStream(streamId, connection)
  NetworkUtil.writeNodeObject(streamId, self.vehicle)

  streamWriteBool(streamId, self.state)
end

function SetCruiseControlSpeedLockStateEvent:run(connection)
  if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
    self.vehicle:setIsCruiseControlSpeedLockActive(self.state, true)
  end

  if not connection:getIsServer() then
    g_server:broadcastEvent(SetCruiseControlSpeedLockStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
  end
end

function SetCruiseControlSpeedLockStateEvent.sendEvent(vehicle, state, noEventSend)
  if vehicle.spec_enhancedCruiseControl.isCruiseControlSpeedLockActive ~= state and (noEventSend == nil or noEventSend == false) then
    if g_server ~= nil then
      g_server:broadcastEvent(SetCruiseControlSpeedLockStateEvent.new(vehicle, state), nil, nil, vehicle)
    else
      g_client:getServerConnection():sendEvent(SetCruiseControlSpeedLockStateEvent.new(vehicle, state))
    end
  end
end