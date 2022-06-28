local allowSave = false

local timeout = false

RegisterServerEvent('cust_objectiveCreator:exportLua', function(str, add)
    if add or timeout or not allowSave then
        CancelEvent()
        return
    end
    SaveResourceFile(GetCurrentResourceName(), 'project'..math.random(1, 999)..'.lua', str, -1)
    timeout = true
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if timeout then
            timeout = false
        else
            Citizen.Wait(2500)
        end
    end
end)