

AddEventHandler("Tripwire:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
    Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
    Progress = exports["mythic-base"]:FetchComponent("Progress")
    Targeting = exports["mythic-base"]:FetchComponent("Targeting")
    
    
    local success, notification = pcall(function()
        return exports["mythic-base"]:FetchComponent("Notification")
    end)
    if success and notification then
        Notification = notification
    else
        Notification = nil
    end
    
    
    Config.Notify.client = function(msg, type, time)
        if Notification then
            local notifType = type or "info"
            local duration = time or 5000
            if notifType == "success" then
                Notification:Success(msg, duration)
            elseif notifType == "error" then
                Notification:Error(msg, duration)
            elseif notifType == "warning" or notifType == "warn" then
                Notification:Warn(msg, duration)
            else
                Notification:Info(msg, duration)
            end
        else
            
            print("[Tripwire] " .. msg)
        end
    end
end

AddEventHandler("Core:Shared:Ready", function()
    exports["mythic-base"]:RequestDependencies("Tripwire", {
        "Callbacks",
        "Progress",
        "Targeting",
    }, function(error)
        if #error > 0 then 
            exports["mythic-base"]:FetchComponent("Logger"):Critical("Tripwire", "Failed To Load All Dependencies")
            return
        end
        
        RetrieveComponents()
        TriggerEvent("Tripwire:Client:Startup")
    end)
end)

