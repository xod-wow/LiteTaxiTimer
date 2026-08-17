local _, LTT = ...

LTT.FlightPoint = {}

function LTT.FlightPoint:CreateFromTaxiNodeInfo(taxiNodeInfo, uiMapID)
    local self = setmetatable({}, { __index = LTT.FlightPoint } )
    self.nodeID = taxiNodeInfo.nodeID
    self.name = taxiNodeInfo.name
    self.isOrigin = ( taxiNodeInfo.state == Enum.FlightPathState.Current )
    self.uiMapID = uiMapID
    self.slotIndex = taxiNodeInfo.slotIndex
    return self
end

function LTT.FlightPoint:CreateFromPin(pin, uiMapID)
    return self:CreateFromTaxiNodeInfo(pin.taxiNodeData, uiMapID)
end

function LTT.FlightPoint:GetName()
    return self.name
end

function LTT.FlightPoint:GetNodeID()
    return self.nodeID
end

function LTT.FlightPoint:GetSlotIndex()
    return self.slotIndex, self.uiMapID
end

function LTT.FlightPoint:IsOrigin()
    return self.isOrigin
end

function LTT.FlightPoint:Dump()
    print(self.nodeID, self.name, self.isOrigin)
end
