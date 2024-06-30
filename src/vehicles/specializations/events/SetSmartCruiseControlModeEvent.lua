-- SetSmartCruiseControlModeEvent.lua
--
-- author: 4c65736975
--
-- Copyright (c) 2024 VertexFloat. All Rights Reserved.
--
-- This source code is licensed under the GPL-3.0 license found in the
-- LICENSE file in the root directory of this source tree.

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
  self.state = streamReadUIntN(streamId, EnhancedCruiseControl.SEND_NUM_BITS)

  self:run(connection)
end

function SetSmartCruiseControlModeEvent:writeStream(streamId, connection)
  NetworkUtil.writeNodeObject(streamId, self.vehicle)

  streamWriteUIntN(streamId, self.state, EnhancedCruiseControl.SEND_NUM_BITS)
end

function SetSmartCruiseControlModeEvent:run(connection)
  if not connection:getIsServer() then
    g_server:broadcastEvent(self, false, connection, self.vehicle)
  end

  if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
    self.vehicle:setSmartCruiseControlMode(self.state, true)
  end
end

function SetSmartCruiseControlModeEvent.sendEvent(vehicle, state, noEventSend)
  if vehicle.spec_enhancedCruiseControl.currentSmartCruiseControlMode ~= state and (noEventSend == nil or noEventSend == false) then
    if g_server ~= nil then
      g_server:broadcastEvent(SetSmartCruiseControlModeEvent.new(vehicle, state), nil, nil, vehicle)
    else
      g_client:getServerConnection():sendEvent(SetSmartCruiseControlModeEvent.new(vehicle, state))
    end
  end
end