local _, LTT = ...

LTT.Journey = {}

local function GetNodeIDFromSlotIndex(slotIndex)
    local taxiMapIDs = { GetTaxiMapID(), FlightMapFrame.mapID }
    for _,taxiMapID in ipairs(taxiMapIDs) do
        if taxiMapID then
            local taximapNodes = C_TaxiMap.GetAllTaxiNodes(taxiMapID)
            for _, taxiNodeData in ipairs(taximapNodes) do
                if slotIndex == taxiNodeData.slotIndex then
                    return taxiNodeData.nodeID
                end
            end
        end
    end
end

function LTT.Journey:New()
    local self = setmetatable({}, { __index = LTT.Journey })
    self.flightPointList = {}
    return self
end

function LTT.Journey:ClearAllPoints()
    table.wipe(self.flightPointList)
end

function LTT.Journey:AddPoint(flightPoint)
    self.flightPointList[flightPoint:GetNodeID()] = flightPoint
end

function LTT.Journey:AddPointsFromTaxiMap()
    local uiMapID = FlightMapFrame.mapID or GetTaxiMapID()
    for i = 1, NumTaxiNodes() do
        local flightPoint = LTT.FlightPoint:CreateFromSlotIndex(i, uiMapID)
        self:AddPoint(flightPoint)
    end
end

function LTT.Journey:AddPointsFromFlightMap()
    if not FlightMapFrame then return end
    if not FlightMapFrame.pinPools then return end
    if not FlightMapFrame.pinPools.FlightMap_FlightPointPinTemplate then return end

    local uiMapID = FlightMapFrame.mapID or GetTaxiMapID()
    for pin in FlightMapFrame.pinPools.FlightMap_FlightPointPinTemplate:EnumerateActive() do
        local flightPoint = LTT.FlightPoint:CreateFromPin(pin, uiMapID)
        self:AddPoint(flightPoint)
    end
end

function LTT.Journey:SetDestinationByNodeID(nodeID)
    local flightNode = self:GetFlightPointByNodeID(nodeID)
    self.destination = flightNode
end

function LTT.Journey:SetDestinationBySlotIndex(slotIndex, uiMapID)
    local flightNode = self:GetFlightPointBySlotIndex(slotIndex, uiMapID)
    self.destination = flightNode
end

function LTT.Journey:GetDestination()
    return self.destination
end

function LTT.Journey:GetOrigin()
    for _, flightPoint in pairs(self.flightPointList) do
        if flightPoint:IsOrigin() then
            return flightPoint
        end
    end
end

function LTT.Journey:GetFlightPointByNodeID(nodeID)
    return self.flightPointList[nodeID]
end

function LTT.Journey:GetFlightPointBySlotIndex(slotIndex, uiMapID)
    for _, flightPoint in pairs(self.flightPointList) do
        if uiMapID == flightPoint.uiMapID and slotIndex == flightPoint.slotIndex then
            return flightPoint
        end
    end
end

function LTT.Journey:GetRoute()
    local route = { }
    local destSlotIndex, destMapID = self.destination:GetSlotIndex()
    for i = 1, GetNumRoutes(destSlotIndex) + 1 do
        local hopSlotIndex = TaxiGetNodeSlot(destSlotIndex, i, true)
        table.insert(route, self:GetFlightPointBySlotIndex(hopSlotIndex, destMapID))
    end
    return route
end

function LTT.Journey:SaveDuration(seconds)
    local origin = self:GetOrigin()
    local faction = GetPlayerFactionGroup()
    local originID  = origin:GetNodeID()
    local destID  = self.destination:GetNodeID()
    LTT.db.flightTimes[faction] = LTT.db.flightTimes[faction] or {}
    LTT.db.flightTimes[faction][originID] = LTT.db.flightTimes[faction][originID] or {}
    LTT.db.flightTimes[faction][originID][destID] = seconds
end

function LTT.Journey:GetDuration()
    local origin = self:GetOrigin()
    local faction = GetPlayerFactionGroup()
    local originID  = origin:GetNodeID()
    local destID  = self.destination:GetNodeID()
    if not LTT.db.flightTimes[faction] then return end
    if not LTT.db.flightTimes[faction][originID] then return end
    return LTT.db.flightTimes[faction][originID][destID]
end

function LTT.Journey:Dump()
    local keys = GetKeysArray(self.flightPointList)
    table.sort(keys)
    for _, k in ipairs(keys) do
        self.flightPointList[k]:Dump()
    end
end
