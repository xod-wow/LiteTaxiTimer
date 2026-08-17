--[[----------------------------------------------------------------------------

  LiteTaxiTimer

  Copyright 2024 Mike Battersby

  LiteTaxiTimer is free software: you can redistribute it and/or modify it
  under the terms of the GNU General Public License, version 2, as published
  by the Free Software Foundation.

  LiteMount is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
  more details.

  The file LICENSE.txt included with LiteMount contains a copy of the
  license. If the LICENSE.txt file is missing, you can find a copy at
  http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt

----------------------------------------------------------------------------]]--

local addonName, LTT = ...

LTT.addon = CreateFrame('Frame')

local defaults = {
    flightTimes = {}
}

local function MergeTableRecursive(t, other)
    for k, v in pairs(other) do
        if not t[k] then
            if type(v) == 'table' then
                t[k] = CopyTable(v)
            else
                t[k] = v
            end
        elseif type(v) == 'table' then
            MergeTableRecursive(t[k], v)
        end
    end
    return t
end

function LTT.addon:Initialize()
    LiteTaxiTimerDB = MergeTableRecursive(LiteTaxiTimerDB or {}, defaults)
    LTT.db = LiteTaxiTimerDB
    self:RegisterEvent('ADDON_LOADED')
    self:RegisterEvent('TAXIMAP_OPENED')
    self:RegisterEvent("PLAYER_CONTROL_LOST")
end

function LTT.addon:StartTaxiFlight()
    print('Starting taxi flight')
    self.flightStartTime = GetTime()
    self:RegisterEvent("LFG_PROPOSAL_DONE")
    self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
    self:RegisterEvent("PLAYER_CONTROL_GAINED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_LEAVING_WORLD")
    C_Timer.After(0.5,
        function ()
            if not UnitOnTaxi('player') then
                self:EndTaxiFlight(true)
            end
        end)
end

function LTT.addon:EndTaxiFlight(isAborted)
    if not isAborted then
        local ft = GetTime() - self.flightStartTime
        print('Flight time: ' .. tostring(ft))
        self.journey:SaveDuration(ft)
    end

    self.flightStartTime = nil
    self.journey = nil
    self:UnregisterEvent("LFG_PROPOSAL_DONE")
    self:UnregisterEvent("LFG_PROPOSAL_SUCCEEDED")
    self:UnregisterEvent("PLAYER_CONTROL_GAINED")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:UnregisterEvent("PLAYER_LEAVING_WORLD")
end

function LTT.addon:HookFlightMap()
    hooksecurefunc(FlightMapFrame, 'OnMapChanged',
        function ()
            if self.journey then
                self.journey:AddPointsFromFlightMap()
            end
        end)
end

local DurationFormatter = CreateFromMixins(SecondsFormatterMixin)
DurationFormatter:Init(0, SecondsFormatter.Abbreviation.OneLetter)
DurationFormatter:SetStripIntervalWhitespace(true)

function LTT.addon:AnnotateTooltip()
    local origin = self.journey:GetOrigin()
    local dest = self.journey:GetDestination()
    if origin:GetNodeID() ~= dest:GetNodeID() then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(format("Origin: %s (%d)", origin:GetName(), origin:GetNodeID()))
        GameTooltip:AddLine(format("Dest: %s (%d)", dest:GetName(), dest:GetNodeID()))
        local duration = self.journey:GetDuration()
        local durationText = duration and DurationFormatter:Format(duration) or UNKNOWN
        GameTooltip:AddDoubleLine("Duration", durationText)
        GameTooltip:Show()
    end
end

function LTT.addon:PinOnEnter(pin)
    self.journey:SetDestinationByNodeID(pin.taxiNodeData.nodeID)
    self:AnnotateTooltip()
end

function LTT.addon:HookFlightMapPins()
    self.hookedPins = self.hookedPins or {}
    for pin in FlightMapFrame.pinPools.FlightMap_FlightPointPinTemplate:EnumerateActive() do
        if not self.hookedPins[pin] then
            pin:HookScript("OnEnter", function (pin) self:PinOnEnter(pin) end)
            self.hookedPins[pin] = true
        end
    end
end

function LTT.addon:ButtonOnEnter(button)
    local slotIndex = button:GetID()
    local uiMapID = GetTaxiMapID()
    self.journey:SetDestinationBytSlotIndex(slotIndex, uiMapID)
    self:AnnotateTooltip()
end

function LTT.addon:HookTaxiMapButtons()
    self.hookedButtons = self.hookedButtons or {}
    for i = 1, NumTaxiNodes(), 1 do
        local tb = _G["TaxiButton"..i]
        if tb and not self.hookedButtons[tb] then
            pin:HookScript("OnEnter", function (button) self:ButtonOnEnter(button) end)
            self.hookedbuttons[tb] = true
        end
    end
end

function LTT.addon:NewJourney(uiMapSystem)
    self.journey = LTT.Journey:New()
    if uiMapSystem == Enum.UIMapSystem.Taxi then
        self.journey:AddPointsFromTaxiMap()
        self:HookTaxiMapButtons()
    else
        self.journey:AddPointsFromFlightMap()
        self:HookFlightMapPins()
    end
end

function LTT.addon:OnEvent(event, ...)
    print(event)
    if event == 'PLAYER_LOGIN' then
        self:Initialize()
    elseif event == 'TAXIMAP_OPENED' then
        local uiMapSystem = ...
        self:NewJourney(uiMapSystem)
    elseif event == 'ADDON_LOADED' then
        local addonName = ...
        if addonName == 'Blizzard_FlightMap' then
            self:HookFlightMap()
        end
    elseif event == 'PLAYER_CONTROL_GAINED' then
        self:EndTaxiFlight()
    elseif event == 'PLAYER_CONTROL_LOST' then
        self:StartTaxiFlight()
    else
        self:EndTaxiFlight(true)
    end
end

LTT.addon:SetScript('OnEvent', LTT.addon.OnEvent)
LTT.addon:RegisterEvent('PLAYER_LOGIN')

_G.LTT = LTT.addon
