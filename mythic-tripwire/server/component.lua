AddEventHandler("Tripwire:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
    Fetch = exports["mythic-base"]:FetchComponent("Fetch")
    Logger = exports["mythic-base"]:FetchComponent("Logger")
    Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
    Inventory = exports["mythic-base"]:FetchComponent("Inventory")
    Database = exports["mythic-base"]:FetchComponent("Database")
    Config.Notify.server = function(src, msg, type, time)
        TriggerClientEvent("Tripwire:Client:Notify", src, msg, type or "info", time or 5000)
    end
end

AddEventHandler("Core:Shared:Ready", function()
    exports["mythic-base"]:RequestDependencies("Tripwire", {
        "Fetch",
        "Logger",
        "Callbacks",
        "Inventory",
        "Database",
    }, function(error)
        if #error > 0 then 
            exports["mythic-base"]:FetchComponent("Logger"):Critical("Tripwire", "Failed To Load All Dependencies")
            return
        end
        RetrieveComponents()
        TriggerEvent("Tripwire:Server:Startup")
    end)
end)

