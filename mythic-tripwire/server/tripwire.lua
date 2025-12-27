if not Config.TripRope.enable then return end

local Ropes = {}
local RopeIds = {}
AddEventHandler("Tripwire:Server:Startup", function()
    CreateThread(function()
        Wait(3000) 
        
        if Database then
            print("[Tripwire] Attempting to load tripwires from database...")
            
            
            if Database.Game and Database.Game.find then
                Database.Game:find({
                    collection = "tripwires",
                    query = {}
                }, function(success, results)
                    print(string.format("[Tripwire] Find callback - Success: %s, Results type: %s", tostring(success), type(results)))
                    if success and results then
                        
                        local resultArray = {}
                        if type(results) == "table" then
                            if #results > 0 then
                                
                                resultArray = results
                            elseif next(results) then
                                
                                resultArray = {results}
                            end
                        end
                        
                        if #resultArray > 0 then
                            print(string.format("[Tripwire] Found %d tripwires in database", #resultArray))
                            for i, rope in ipairs(resultArray) do
                                if rope and rope.p1 and rope.p2 then
                                    local ropeData = {
                                        p1 = vec4(rope.p1.x, rope.p1.y, rope.p1.z, rope.p1.w or 0.0),
                                        p2 = vec4(rope.p2.x, rope.p2.y, rope.p2.z, rope.p2.w or 0.0)
                                    }
                                    Ropes[i] = ropeData
                                    RopeIds[i] = rope._id or rope.id
                                    
                                    
                                end
                            end
                            print(string.format("[Tripwire] Loaded %d tripwires from database", #resultArray))
                        else
                            print("[Tripwire] No tripwires found in database (empty result)")
                        end
                    else
                        print(string.format("[Tripwire] Find failed or returned nil. Success: %s", tostring(success)))
                    end
                end)
            
            elseif Database.find then
                Database:find({
                    collection = "tripwires",
                    query = {}
                }, function(success, results)
                    print(string.format("[Tripwire] Find callback - Success: %s, Results type: %s", tostring(success), type(results)))
                    if success and results then
                        
                        local resultArray = {}
                        if type(results) == "table" then
                            if #results > 0 then
                                
                                resultArray = results
                            elseif next(results) then
                                
                                resultArray = {results}
                            end
                        end
                        
                        if #resultArray > 0 then
                            print(string.format("[Tripwire] Found %d tripwires in database", #resultArray))
                            for i, rope in ipairs(resultArray) do
                                if rope and rope.p1 and rope.p2 then
                                    local ropeData = {
                                        p1 = vec4(rope.p1.x, rope.p1.y, rope.p1.z, rope.p1.w or 0.0),
                                        p2 = vec4(rope.p2.x, rope.p2.y, rope.p2.z, rope.p2.w or 0.0)
                                    }
                                    Ropes[i] = ropeData
                                    RopeIds[i] = rope._id or rope.id
                                    
                                    
                                end
                            end
                            print(string.format("[Tripwire] Loaded %d tripwires from database", #resultArray))
                        else
                            print("[Tripwire] No tripwires found in database (empty result)")
                        end
                    else
                        print(string.format("[Tripwire] Find failed or returned nil. Success: %s", tostring(success)))
                    end
                end)
            else
                print("[Tripwire] Database component does not have find method. Available methods:")
                
                for k, v in pairs(Database) do
                    print(string.format("[Tripwire] Database.%s = %s", tostring(k), type(v)))
                end
            end
        else
            print("[Tripwire] Database component not available - tripwires will not persist")
        end
    end)
end)

RegisterNetEvent("tripwire:server:rope:LoadRopes", function()
    local src = source
    CreateThread(function()
        Wait(1000) 
        local ropeCount = 0
        for k, v in pairs(Ropes) do
            ropeCount = ropeCount + 1
            print(string.format("[Tripwire] Loading rope %d for client %d - p1: %.2f, %.2f, %.2f | p2: %.2f, %.2f, %.2f", 
                k, src, v.p1.x, v.p1.y, v.p1.z, v.p2.x, v.p2.y, v.p2.z))
            Wait(100) 
            
            
            
            
            local Z_Offset = Config.TripRope.Z_Offset or -0.8
            local propPos1 = vec4(v.p1.x, v.p1.y, v.p1.z - Z_Offset, v.p1.w or 0.0)
            local propPos2 = vec4(v.p2.x, v.p2.y, v.p2.z - Z_Offset, v.p2.w or 0.0)
            
            TriggerClientEvent("tripwire:client:rope:CreateProp", src, propPos1)
            Wait(50)
            TriggerClientEvent("tripwire:client:rope:CreateProp", src, propPos2)
            Wait(50)
            TriggerClientEvent("tripwire:client:rope:createRope", src, v.p1, v.p2, k)
        end
        print(string.format("[Tripwire] Loaded %d ropes for client %d", ropeCount, src))
    end)
end)

RegisterNetEvent("tripwire:server:rope:syncRope", function(p1, p2)
    local RopeId = #Ropes + 1
    Ropes[RopeId] = {}
    Ropes[RopeId].p1 = vec4(p1.x, p1.y, p1.z, p1.w or 0.0)
    Ropes[RopeId].p2 = vec4(p2.x, p2.y, p2.z, p2.w or 0.0)
    
    
    if Database then
        print("[Tripwire] Attempting to save tripwire to database...")
        print(string.format("[Tripwire] Rope data - p1: %.2f, %.2f, %.2f | p2: %.2f, %.2f, %.2f", p1.x, p1.y, p1.z, p2.x, p2.y, p2.z))
        
        local insertData = {
            p1 = {
                x = p1.x,
                y = p1.y,
                z = p1.z,
                w = p1.w or 0.0
            },
            p2 = {
                x = p2.x,
                y = p2.y,
                z = p2.z,
                w = p2.w or 0.0
            },
            createdAt = os.time()
        }
        
        
        if Database.Game and Database.Game.insertOne then
            Database.Game:insertOne({
                collection = "tripwires",
                document = insertData
            }, function(success, result)
                if success then
                    
                    local id = nil
                    if type(result) == "string" or type(result) == "number" then
                        id = result
                    elseif type(result) == "table" and result._id then
                        id = result._id
                    end
                    
                    if id then
                        RopeIds[RopeId] = id
                        print(string.format("[Tripwire] Saved tripwire to database with ID: %s", tostring(id)))
                    else
                        print("[Tripwire] Failed to get ID from insertOne result. Result type: " .. type(result))
                    end
                else
                    print("[Tripwire] Failed to save tripwire - insertOne returned failure")
                end
            end)
        
        elseif Database.insertOne then
            Database:insertOne({
                collection = "tripwires",
                document = insertData
            }, function(success, result)
                if success then
                    
                    local id = nil
                    if type(result) == "string" or type(result) == "number" then
                        id = result
                    elseif type(result) == "table" and result._id then
                        id = result._id
                    end
                    
                    if id then
                        RopeIds[RopeId] = id
                        print(string.format("[Tripwire] Saved tripwire to database with ID: %s", tostring(id)))
                    else
                        print("[Tripwire] Failed to get ID from insertOne result. Result type: " .. type(result))
                    end
                else
                    print("[Tripwire] Failed to save tripwire - insertOne returned failure")
                end
            end)
        else
            print("[Tripwire] Database component does not have insertOne method. Available methods: " .. tostring(Database))
            
            for k, v in pairs(Database) do
                print(string.format("[Tripwire] Database.%s = %s", tostring(k), type(v)))
            end
        end
    else
        print("[Tripwire] Database component not available - tripwire not saved")
    end
    
    TriggerClientEvent("tripwire:client:rope:createRope", -1, p1, p2, RopeId)
end)

RegisterNetEvent("tripwire:server:rope:CreateProp", function(pos)
    TriggerClientEvent("tripwire:client:rope:CreateProp", -1, pos)
end)

RegisterNetEvent("tripwire:server:RemoveRope", function(serverID)
    local src = source
    local plyr = Fetch:Source(src)
    if plyr == nil then return end
    local char = plyr:GetData("Character")
    if char == nil then return end
    
    
    if not serverID or not Ropes[serverID] then
        print(string.format("[Tripwire] Error: Rope not found for serverID: %s", tostring(serverID)))
        return
    end
    
    if Inventory:AddItem(char:GetData("SID"), Config.TripRope.Item.Place, 2, nil, 1) then
        
        if Database and RopeIds[serverID] then
            local dbId = RopeIds[serverID]
            
            if Database.Game and Database.Game.deleteOne then
                Database.Game:deleteOne({
                    collection = "tripwires",
                    query = { _id = dbId }
                }, function(success)
                    if success then
                        print(string.format("[Tripwire] Removed tripwire %s from database", tostring(dbId)))
                    else
                        print(string.format("[Tripwire] Failed to remove tripwire %s from database", tostring(dbId)))
                    end
                end)
            
            elseif Database.deleteOne then
                Database:deleteOne({
                    collection = "tripwires",
                    query = { _id = dbId }
                }, function(success)
                    if success then
                        print(string.format("[Tripwire] Removed tripwire %s from database", tostring(dbId)))
                    else
                        print(string.format("[Tripwire] Failed to remove tripwire %s from database", tostring(dbId)))
                    end
                end)
            else
                print("[Tripwire] Database deleteOne method not available")
            end
        else
            print(string.format("[Tripwire] Warning: No database ID found for rope serverID %s", tostring(serverID)))
        end
        
        
        TriggerClientEvent("tripwire:client:rope:RemoveRopeByServerID", -1, serverID)
        
        
        Ropes[serverID] = nil
        RopeIds[serverID] = nil
    end
end)

RegisterNetEvent("tripwire:server:rope:RemoveProp", function(pos, removeItem)
    local src = source
    local plyr = Fetch:Source(src)
    if plyr == nil then return end
    local char = plyr:GetData("Character")
    if char == nil then return end
    
    if pos and Inventory:AddItem(char:GetData("SID"), Config.TripRope.Item.Place, 1, nil, 1) then
        TriggerClientEvent("tripwire:client:rope:RemoveProp", -1, pos)
    end
end)

AddEventHandler("Tripwire:Server:Startup", function()
    
    Inventory.Items:RegisterUse(Config.TripRope.Item.Place, "TripRope", function(source, item, itemData)
        local plyr = Fetch:Source(source)
        if plyr == nil then return end
        local char = plyr:GetData("Character")
        if char == nil then return end
        
        if Inventory.Items:Remove(char:GetData("SID"), 1, Config.TripRope.Item.Place, 1) then
            TriggerClientEvent('tripwire:client:rope:PlaceRope', source)
        end
    end)
end)

