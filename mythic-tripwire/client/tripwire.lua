if not Config.TripRope.enable then return end

local pos1, pos2 = nil, nil
local ropeIds, Props = {}, {}
local BoxZones, RemoveBoxZones = {}, {}
local placeing, ragdoll = false, false


local function GetProgress()
    
    if Progress and type(Progress) == "table" and Progress.Progress then
        return Progress
    end
    
    local success, component = pcall(function()
        return exports["mythic-base"]:FetchComponent("Progress")
    end)
    if success and component and type(component) == "table" and component.Progress then
        Progress = component
        return Progress
    end
    return nil
end


local function AddPropTargeting(prop, pos)
    CreateThread(function()
        
        Wait(1000) 
        
        local attempts = 0
        while attempts < 30 do
            
            if not DoesEntityExist(prop) then
                print(string.format("[Tripwire] Prop entity %d no longer exists, cannot add targeting", prop))
                break
            end
            
            
            if Targeting and type(Targeting) == "table" then
                
                if attempts == 0 then
                    local methods = {}
                    for k, v in pairs(Targeting) do
                        if type(v) == "function" then
                            table.insert(methods, k)
                        end
                    end
                    print(string.format("[Tripwire] Targeting component type: %s, methods: %s", type(Targeting), table.concat(methods, ", ")))
                    print(string.format("[Tripwire] Targeting.AddLocalEntity type: %s", type(Targeting.AddLocalEntity)))
                    print(string.format("[Tripwire] Targeting.AddBoxZone type: %s", type(Targeting.AddBoxZone)))
                end
                
                
                if Targeting.AddEntity then
                    local success, result = pcall(function()
                        
                        Targeting:AddEntity(prop, 'hand-point-down', {
                            {
                                text = Language.target.removerop,
                                icon = 'hand-point-down',
                                event = 'tripwire:client:rope:PlayerRemoveRope',
                                data = { pos = vec3(pos.x, pos.y, pos.z) },
                                minDist = Config.TripRope.MaxRemoveDistance,
                            }
                        }, Config.TripRope.MaxRemoveDistance)
                        return true 
                    end)
                    
                    if success then
                        RemoveBoxZones[prop] = prop 
                        print(string.format("[Tripwire] Successfully added targeting to prop entity %d", prop))
                        break
                    else
                        if attempts % 5 == 0 then
                            print(string.format("[Tripwire] AddEntity error for prop entity %d (attempt %d): %s", prop, attempts + 1, tostring(result)))
                        end
                    end
                elseif Targeting.Zones and Targeting.Zones.AddBox then
                    
                    local offset = Config.TripRope.PropOffset
                    local zoneId = 'tripwire_removezone_'..prop
                    local success = pcall(function()
                        
                        Targeting.Zones:AddBox(
                            zoneId,
                            'hand-point-down',
                            vec3(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z -.5),
                            1.0, 
                            1.0, 
                            {
                                name = zoneId,
                                heading = pos.w,
                                debugPoly = Config.Debug,
                            },
                            {
                                {
                                    text = Language.target.removerop,
                                    icon = 'hand-point-down',
                                    event = 'tripwire:client:rope:PlayerRemoveRope',
                                    data = {pos = pos.xyz},
                                    minDist = Config.TripRope.MaxRemoveDistance,
                                }
                            },
                            Config.TripRope.MaxRemoveDistance, 
                            true 
                        )
                    end)
                    
                    if success then
                        RemoveBoxZones[prop] = zoneId 
                        print(string.format("[Tripwire] Successfully added box zone targeting to prop entity %d", prop))
                        break
                    else
                        if attempts % 5 == 0 then
                            print(string.format("[Tripwire] AddBox error for prop entity %d (attempt %d)", prop, attempts + 1))
                        end
                    end
                else
                    if attempts % 5 == 0 then
                        print(string.format("[Tripwire] Targeting component missing AddEntity/AddBox methods (attempt %d)", attempts + 1))
                    end
                end
            else
                
                local success, fetched = pcall(function()
                    return exports["mythic-base"]:FetchComponent("Targeting")
                end)
                
                if success and fetched and type(fetched) == "table" then
                    
                    Targeting = fetched
                    if attempts % 5 == 0 then
                        print(string.format("[Tripwire] Fetched Targeting component (attempt %d)", attempts + 1))
                    end
                elseif attempts % 5 == 0 then
                    print(string.format("[Tripwire] Targeting component not available (attempt %d) - Targeting type: %s", attempts + 1, type(Targeting)))
                end
            end
            
            attempts = attempts + 1
            Wait(500) 
        end
        
        if attempts >= 30 then
            print(string.format("[Tripwire] Failed to add targeting to prop entity %d after %d attempts", prop, attempts))
        end
    end)
end

CreateThread(function()
    RopeLoadTextures()
end)

local function getBoxDimensions(p1, p2)
    local width = math.abs(p2.x - p1.x)
    local length = math.abs(p2.y - p1.y)
    local height = math.abs(p2.z - p1.z)
    return width, length, height
end

local function getHeadingFromPoints(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local heading = math.deg(math.atan2(dy, dx))
    heading = (heading - 90) % 360 
    return (heading + 360) % 360
end

RegisterNetEvent("tripwire:client:rope:PlaceRope", function()
    if #ropeIds >= Config.TripRope.MaxServerRopes then return Config.Notify.client(Language.error.maxtraps, 'error', 5000) end
    placeing = true
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    if not pos1 then
        local progress = GetProgress()
        if progress and progress.Progress then
            progress:Progress({
                name = 'place_rope_rod_1',
                duration = 1000 * Config.TripRope.ProgressTime,
                label = Language.progress.placing,
                useWhileDead = false,
                canCancel = true,
                animation = {
                    animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
                    anim = "machinic_loop_mechandplayer",
                    flags = 1,
                },
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }
            }, function(cancelled)
                if not cancelled then
                    pos1 = vec4(pos.x, pos.y, pos.z+Config.TripRope.Z_Offset, heading)
                    TriggerServerEvent('tripwire:server:rope:CreateProp', vec4(pos.x, pos.y, pos.z, heading))
                    Config.Notify.client(Language.success.placesecondrod, 'success', 5000)
                end
            end)
        else
            
            pos1 = vec4(pos.x, pos.y, pos.z+Config.TripRope.Z_Offset, heading)
            TriggerServerEvent('tripwire:server:rope:CreateProp', vec4(pos.x, pos.y, pos.z, heading))
            Config.Notify.client(Language.success.placesecondrod, 'success', 5000)
        end
    elseif not pos2 then
        local progress = GetProgress()
        if progress and progress.Progress then
            progress:Progress({
                name = 'place_rope_rod_2',
                duration = 1000 * Config.TripRope.ProgressTime,
                label = Language.progress.placing,
                useWhileDead = false,
                canCancel = true,
                animation = {
                    animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
                    anim = "machinic_loop_mechandplayer",
                    flags = 1,
                },
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }
            }, function(cancelled)
                if not cancelled then
                    pos2 = vec4(pos.x, pos.y, pos.z+Config.TripRope.Z_Offset, heading)
                    if #(vector2(pos1.x, pos1.y) - vector2(pos2.x, pos2.y)) <= Config.TripRope.MaxRopeLength then
                        TriggerServerEvent("tripwire:server:rope:syncRope", pos1, pos2)
                        TriggerServerEvent('tripwire:server:rope:CreateProp', vec4(pos.x, pos.y, pos.z, heading))
                        pos1, pos2 = nil, nil
                        placeing = false
                    else
                        pos2 = nil
                    end
                end
            end)
        else
            
            pos2 = vec4(pos.x, pos.y, pos.z+Config.TripRope.Z_Offset, heading)
            if #(vector2(pos1.x, pos1.y) - vector2(pos2.x, pos2.y)) <= Config.TripRope.MaxRopeLength then
                TriggerServerEvent("tripwire:server:rope:syncRope", pos1, pos2)
                TriggerServerEvent('tripwire:server:rope:CreateProp', vec4(pos.x, pos.y, pos.z, heading))
                pos1, pos2 = nil, nil
                placeing = false
            else
                pos2 = nil
            end
        end
    end
    CreateThread(function()
        while placeing do
            Wait(500)
            pos = GetEntityCoords(ped)
            if pos1 then
                if #(pos - pos1.xyz) >= Config.TripRope.MaxRopeLength + 3.0 then
                    TriggerServerEvent('tripwire:server:rope:RemoveProp', pos1)
                    pos1, pos2 = nil, nil
                    placeing = false
                end
            end
            if pos2 then
                if #(pos - pos2.xyz) >= Config.TripRope.MaxRopeLength + 3.0 then
                    TriggerServerEvent('tripwire:server:rope:RemoveProp', pos2)
                    pos1, pos2 = nil, nil
                    placeing = false
                end
            end
        end
    end)
end)

RegisterNetEvent("tripwire:client:rope:PlayerRemoveRope", function(data)
    if not data then
        print("[Tripwire] Error: No data provided to PlayerRemoveRope event")
        return
    end
    
    
    
    local pos = data.endCoords or data.pos or data
    
    
    if type(pos) == "table" then
        
        if pos.xyz then
            if type(pos.xyz) == "table" then
                pos = pos.xyz
            elseif type(pos.xyz) == "userdata" or type(pos.xyz) == "vector3" then
                
                pos = pos.xyz
            end
        end

        
        if type(pos) == "table" then
            
            
            local x = pos.x or pos[1]
            local y = pos.y or pos[2]
            local z = pos.z or pos[3]
            
            
            if not x and pos.coords then
                if type(pos.coords) == "table" then
                    x = pos.coords.x or pos.coords[1]
                    y = pos.coords.y or pos.coords[2]
                    z = pos.coords.z or pos.coords[3]
                end
            end

            
            if x and y and z then
                x = tonumber(x)
                y = tonumber(y)
                z = tonumber(z)
                if x and y and z then
                    pos = vector3(x, y, z)
                else
                    print(string.format("[Tripwire] Error: Could not convert position coordinates to numbers. x=%s, y=%s, z=%s", tostring(x), tostring(y), tostring(z)))
                    return
                end
            else
                
                print(string.format("[Tripwire] Error: Could not extract position from data. Type: %s", type(pos)))
                return
            end
        end
    elseif type(pos) == "userdata" or type(pos) == "vector3" then
        
        
    else
        
        print(string.format("[Tripwire] Error: Position is not a valid type. Type: %s", type(pos)))
        return
    end

    local ped = PlayerPedId()
    local closestIndex = nil
    local closestDist = nil
    for i, rope in ipairs(ropeIds) do
        local midPos = (rope.startPos + rope.endPos) / 2
        local dist = #(pos - midPos)
        
        if not closestDist or dist < closestDist then
            closestDist = dist
            closestIndex = i
        end
    end
    if closestIndex then
        local ropeToDelete = ropeIds[closestIndex]
        if closestDist-7 > Config.TripRope.MaxRemoveDistance then return Config.Notify.client(Language.error.tofar, 'error', 5000) end
        TaskTurnPedToFaceCoord(ped, ropeToDelete.startPos.x, ropeToDelete.startPos.y, ropeToDelete.startPos.z, 1000)
        Wait(1000)
        local progress = GetProgress()
        if progress and progress.Progress then
            progress:Progress({
                name = 'remove_rope',
                duration = 1000 * Config.TripRope.ProgressTime,
                label = Language.progress.taking,
                useWhileDead = false,
                canCancel = true,
                animation = {
                    animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
                    anim = "machinic_loop_mechandplayer",
                    flags = 1,
                },
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }
            }, function(cancelled)
                if not cancelled then
                    
                    TriggerServerEvent('tripwire:server:RemoveRope', ropeToDelete.serverID or closestIndex)
                end
            end)
        else
            
            
            TriggerServerEvent('tripwire:server:RemoveRope', ropeToDelete.serverID or closestIndex)
        end
    end
end)

RegisterNetEvent("tripwire:client:rope:CreateProp", function(pos)
    
    CreateThread(function()
        Wait(500) 
        local offset = Config.TripRope.PropOffset
        local propHash = GetHashKey(Config.TripRope.PlaceProp)
        
        
        RequestModel(propHash)
        while not HasModelLoaded(propHash) do
            Wait(10)
        end
        
        local prop = CreateObject(propHash, pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, false, true, true)
        if prop and prop ~= 0 then
            Props[#Props+1] = prop
            SetEntityHeading(prop, pos.w)
            FreezeEntityPosition(prop, true)
            SetEntityAsMissionEntity(prop, true, true)
            
            
            SetEntityCanBeDamaged(prop, false)
            SetEntityInvincible(prop, true)
            SetBlockingOfNonTemporaryEvents(prop, true)
            
            print(string.format("[Tripwire] Created prop at %.2f, %.2f, %.2f (Entity: %d, Heading: %.2f)", pos.x + offset.x, pos.y + offset.y, pos.z + offset.z, prop, pos.w))
            
            
            
            AddPropTargeting(prop, pos)
            print(string.format("[Tripwire] Called AddPropTargeting for prop entity %d", prop))
        else
            print("[Tripwire] Failed to create prop!")
        end
    end)
end)


local function RemoveRopeByData(ropeToDelete, ropeIndex)
    if not ropeToDelete then 
        print("[Tripwire] Error: ropeToDelete is nil")
        return 
    end
    
    print(string.format("[Tripwire] Removing rope ID %d, serverID %s", ropeToDelete.id, tostring(ropeToDelete.serverID)))
    
    
    if DoesRopeExist(ropeToDelete.id) then
        DeleteRope(ropeToDelete.id)
        print(string.format("[Tripwire] Deleted rope ID %d", ropeToDelete.id))
    end
    
    
    local offset = Config.TripRope.PropOffset
    local p1 = vec3(ropeToDelete.startPos.x + offset.x, ropeToDelete.startPos.y + offset.y, ropeToDelete.startPos.z + offset.z)
    local p2 = vec3(ropeToDelete.endPos.x + offset.x, ropeToDelete.endPos.y + offset.y, ropeToDelete.endPos.z + offset.z)
    
    
    local obj1, obj2 = nil, nil
    
    
    if ropeToDelete.prop1 and DoesEntityExist(ropeToDelete.prop1) then
        obj1 = ropeToDelete.prop1
        print(string.format("[Tripwire] Found prop1 from stored ID: %d", obj1))
    end
    if ropeToDelete.prop2 and DoesEntityExist(ropeToDelete.prop2) then
        obj2 = ropeToDelete.prop2
        print(string.format("[Tripwire] Found prop2 from stored ID: %d", obj2))
    end
    
    
    if not obj1 then
        for k = 1, #Props do
            local v = Props[k]
            if v and DoesEntityExist(v) then
                local propPos = GetEntityCoords(v)
                local dist = #(propPos.xyz - p1)
                if dist <= 2.0 then 
                    obj1 = v
                    print(string.format("[Tripwire] Found prop1 in Props table at index %d: %d (distance: %.2f)", k, obj1, dist))
                    break
                end
            end
        end
    end
    
    if not obj2 then
        for k = 1, #Props do
            local v = Props[k]
            if v and DoesEntityExist(v) then
                local propPos = GetEntityCoords(v)
                local dist = #(propPos.xyz - p2)
                if dist <= 2.0 then 
                    obj2 = v
                    print(string.format("[Tripwire] Found prop2 in Props table at index %d: %d (distance: %.2f)", k, obj2, dist))
                    break
                end
            end
        end
    end
    
    
    if not obj1 or obj1 == 0 then
        obj1 = GetClosestObjectOfType(p1.x, p1.y, p1.z, 2.0, GetHashKey(Config.TripRope.PlaceProp), false, false, false)
        if obj1 and obj1 ~= 0 then
            print(string.format("[Tripwire] Found prop1 via GetClosestObjectOfType: %d", obj1))
        end
    end
    
    if not obj2 or obj2 == 0 then
        obj2 = GetClosestObjectOfType(p2.x, p2.y, p2.z, 2.0, GetHashKey(Config.TripRope.PlaceProp), false, false, false)
        if obj2 and obj2 ~= 0 then
            print(string.format("[Tripwire] Found prop2 via GetClosestObjectOfType: %d", obj2))
        end
    end
    
    
    if obj1 and obj1 ~= 0 and DoesEntityExist(obj1) then
        print(string.format("[Tripwire] Removing prop1: %d", obj1))
        if Targeting then
            if Targeting.RemoveEntity then
                Targeting:RemoveEntity(obj1)
            elseif Targeting.Zones and Targeting.Zones.RemoveZone and RemoveBoxZones[obj1] then
                Targeting.Zones:RemoveZone(RemoveBoxZones[obj1])
            end
        end
        DeleteEntity(obj1)
        
        for k = #Props, 1, -1 do
            if Props[k] == obj1 then
                table.remove(Props, k)
                RemoveBoxZones[obj1] = nil
                print(string.format("[Tripwire] Removed prop1 from Props table at index %d", k))
                break
            end
        end
    else
        print(string.format("[Tripwire] Warning: Could not find or delete prop1. obj1=%s, exists=%s", tostring(obj1), tostring(obj1 and DoesEntityExist(obj1))))
    end
    
    if obj2 and obj2 ~= 0 and DoesEntityExist(obj2) then
        print(string.format("[Tripwire] Removing prop2: %d", obj2))
        if Targeting then
            if Targeting.RemoveEntity then
                Targeting:RemoveEntity(obj2)
            elseif Targeting.Zones and Targeting.Zones.RemoveZone and RemoveBoxZones[obj2] then
                Targeting.Zones:RemoveZone(RemoveBoxZones[obj2])
            end
        end
        DeleteEntity(obj2)
        
        for k = #Props, 1, -1 do
            if Props[k] == obj2 then
                table.remove(Props, k)
                RemoveBoxZones[obj2] = nil
                print(string.format("[Tripwire] Removed prop2 from Props table at index %d", k))
                break
            end
        end
    else
        print(string.format("[Tripwire] Warning: Could not find or delete prop2. obj2=%s, exists=%s", tostring(obj2), tostring(obj2 and DoesEntityExist(obj2))))
    end
    
    
    if BoxZones[ropeToDelete.id] then
        BoxZones[ropeToDelete.id]:destroy()
        BoxZones[ropeToDelete.id] = nil
        print(string.format("[Tripwire] Destroyed box zone for rope ID %d", ropeToDelete.id))
    end
    
    
    if ropeIndex then
        table.remove(ropeIds, ropeIndex)
        print(string.format("[Tripwire] Removed rope from ropeIds table at index %d", ropeIndex))
    end
end

RegisterNetEvent("tripwire:client:rope:RemoveRope", function(closestIndex)
    if closestIndex then
        local ropeToDelete = ropeIds[closestIndex]
        if ropeToDelete then
            RemoveRopeByData(ropeToDelete, closestIndex)
        end
    end
end)

RegisterNetEvent("tripwire:client:rope:RemoveRopeByServerID", function(serverID)
    
    local ropeIndex = nil
    for i, rope in ipairs(ropeIds) do
        if rope.serverID == serverID then
            ropeIndex = i
            break
        end
    end
    
    if ropeIndex then
        local ropeToDelete = ropeIds[ropeIndex]
        if ropeToDelete then
            RemoveRopeByData(ropeToDelete, ropeIndex)
        end
    else
        print(string.format("[Tripwire] Warning: Could not find rope with serverID %s", tostring(serverID)))
    end
end)

RegisterNetEvent("tripwire:client:rope:RemoveProp", function(p)
    for k, v in pairs(Props) do
        local pos = GetEntityCoords(v)
        if #(pos.xyz - p.xyz) <= 1.0 then
            
            if Targeting then
                if Targeting.RemoveEntity then
                    Targeting:RemoveEntity(v)
                elseif Targeting.Zones and Targeting.Zones.RemoveZone and RemoveBoxZones[v] then
                    Targeting.Zones:RemoveZone(RemoveBoxZones[v])
                end
            end
            DeleteEntity(v)
            table.remove(Props, k)
            RemoveBoxZones[v] = nil
            break
        end
    end
end)

RegisterNetEvent("tripwire:client:rope:createRope", function(p1, p2, serverID)
    local ropeLength = #(vector3(p1.x, p1.y, p1.z) - vector3(p2.x, p2.y, p2.z))
    local ropeCenter = (p1.xyz + p2.xyz) / 2
    local ropeLength2D = #(vector2(p1.x, p1.y) - vector2(p2.x, p2.y))
    local zoneWidth = 0.3
    local zoneLength = ropeLength2D
    local heading = getHeadingFromPoints(p1.xyz, p2.xyz)
    local ropeType = 4
    local numSegments = 20

    local ropeId = AddRope(p1.x, p1.y, p1.z, 0.0, 0.0, 0.0, ropeLength, ropeType, ropeLength, numSegments * 1.0, false, false, true, 1.0, false, false )
    Wait(100)
    local vertexCount = GetRopeVertexCount(ropeId)
    PinRopeVertex(ropeId, 0, p1.x, p1.y, p1.z)
    PinRopeVertex(ropeId, vertexCount - 1, p2.x, p2.y, p2.z)
    StartRopeUnwindingFront(ropeId)
    ActivatePhysics(ropeId)
    
    
    local offset = Config.TripRope.PropOffset
    local prop1Pos = vec3(p1.x + offset.x, p1.y + offset.y, p1.z + offset.z)
    local prop2Pos = vec3(p2.x + offset.x, p2.y + offset.y, p2.z + offset.z)
    
    local prop1 = GetClosestObjectOfType(prop1Pos.x, prop1Pos.y, prop1Pos.z, 1.0, GetHashKey(Config.TripRope.PlaceProp), false, false, false)
    local prop2 = GetClosestObjectOfType(prop2Pos.x, prop2Pos.y, prop2Pos.z, 1.0, GetHashKey(Config.TripRope.PlaceProp), false, false, false)
    
    
    if (not prop1 or prop1 == 0) then
        for k, v in pairs(Props) do
            if DoesEntityExist(v) then
                local propPos = GetEntityCoords(v)
                if #(propPos.xyz - prop1Pos) <= 1.0 then
                    prop1 = v
                    break
                end
            end
        end
    end
    
    if (not prop2 or prop2 == 0) then
        for k, v in pairs(Props) do
            if DoesEntityExist(v) then
                local propPos = GetEntityCoords(v)
                if #(propPos.xyz - prop2Pos) <= 1.0 then
                    prop2 = v
                    break
                end
            end
        end
    end
    
    ropeIds[#ropeIds + 1] = {
        serverID = serverID,
        id = ropeId,
        startPos = vector3(p1.x, p1.y, p1.z),
        endPos = vector3(p2.x, p2.y, p2.z),
        prop1 = (prop1 and prop1 ~= 0) and prop1 or nil,
        prop2 = (prop2 and prop2 ~= 0) and prop2 or nil
    }
    BoxZones[ropeId] = BoxZone:Create(ropeCenter, zoneLength, zoneWidth+3.0, {
        name = "rope-" .. ropeId,
        debugPoly = Config.Debug,
        heading = heading,
        minZ = ropeCenter.z - 0.3,
        maxZ = ropeCenter.z + .9,
    })
    BoxZones[ropeId]:onPlayerInOut(function(isPointInside)
        local ped = PlayerPedId()
        if isPointInside then
            ragdoll = true
            CreateThread(function()
                while ragdoll do
                    local FallRepeat = math.random(2, 4)
                    local RagdollTimeout = FallRepeat * 750
                    if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                        SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                        ragdoll = false
                    end
                    Wait(1000)
                end
            end)
        else
            ragdoll = false
        end
    end)
end)

local function UnloadEvent()
    for _, rope in ipairs(ropeIds) do
        if DoesRopeExist(rope.id) then
            DeleteRope(rope.id)
        end
    end
    for k, v in pairs(Props) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
    for k, v in pairs(ropeIds) do
        BoxZones[v.id]:destroy()
    end
    if Targeting then
        for k, v in pairs(RemoveBoxZones) do
            if Targeting.RemoveEntity then
                Targeting:RemoveEntity(k)
            elseif Targeting.Zones and Targeting.Zones.RemoveZone then
                Targeting.Zones:RemoveZone(v)
            end
        end
    end
    BoxZones = {}
    Props = {}
    ropeIds = {}
    RemoveBoxZones = {}
end

RegisterNetEvent(Config.Events.unload, function()
    UnloadEvent()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        UnloadEvent()
    end
end)


AddEventHandler("Tripwire:Shared:DependencyUpdate", function()
    
    if Targeting and type(Targeting) == "table" then
        print("[Tripwire] Components updated, checking for props without targeting...")
        CreateThread(function()
            Wait(2000) 
            for i, prop in ipairs(Props) do
                if DoesEntityExist(prop) then
                    
                    local hasTargeting = false
                    for k, v in pairs(RemoveBoxZones) do
                        if k == prop then
                            hasTargeting = true
                            break
                        end
                    end
                    if not hasTargeting then
                        
                        local pos = GetEntityCoords(prop)
                        local heading = GetEntityHeading(prop)
                        local propPos = vec4(pos.x, pos.y, pos.z, heading)
                        print(string.format("[Tripwire] Adding targeting to existing prop entity %d", prop))
                        AddPropTargeting(prop, propPos)
                    end
                end
            end
        end)
    end
end)

AddEventHandler("Tripwire:Client:Startup", function()
    CreateThread(function()
        
        local attempts = 0
        while attempts < 20 do
            if Targeting and type(Targeting) == "table" then
                
                local testSuccess = pcall(function()
                    return type(Targeting.AddLocalEntity) == "function"
                end)
                if testSuccess and Targeting.AddLocalEntity then
                    print("[Tripwire] Targeting component is ready, requesting rope data from server")
                    TriggerServerEvent('tripwire:server:rope:LoadRopes')
                    break
                end
            end
            attempts = attempts + 1
            Wait(500)
        end
        
        if attempts >= 20 then
            print("[Tripwire] Warning: Targeting component not ready, but requesting rope data anyway")
            print(string.format("[Tripwire] Targeting type: %s, value: %s", type(Targeting), tostring(Targeting)))
            TriggerServerEvent('tripwire:server:rope:LoadRopes')
        end
    end)
end)

