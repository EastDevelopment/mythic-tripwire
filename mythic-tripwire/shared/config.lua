Config = {}

Config.Debug = false
Config.Lang = 'en'


Config.Events = {
    unload = 'Characters:Client:Logout',
    load = 'Characters:Client:Spawn',
}


Config.Notify = {
    client = function(msg, type, time)
        
    end,
    server = function(src, msg, type, time)
        
    end,
}

