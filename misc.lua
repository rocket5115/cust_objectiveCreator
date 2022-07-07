custPeds = {}
custLastPed = 0
custObjects = {}
custLastObject = 0
custVehicles = {}
custLastVehicle = 0

function custMissionText(text, time, await)
    text = tostring(text)
    time = tonumber(time) or 1000
    ClearPrints()
    SetTextEntry_2("STRING")
    AddTextComponentString(text)
    DrawSubtitleTimed(time, 1)
    if await then
        Citizen.Wait(time)
    end
end

local custMarkers = {}
custButtonPressedOnMarker = {}
custInMarker = {}

function custMarker(data, cb)
    local type = tonumber(data[1])
    local posX, posY, posZ = tonumber(data[2]), tonumber(data[3]), tonumber(data[4])
    local dirX, dirY, dirZ = tonumber(data[5]), tonumber(data[6]), tonumber(data[7])
    local rotX, rotY, rotZ = tonumber(data[8]), tonumber(data[9]), tonumber(data[10])
    local scaleX, scaleY, scaleZ = (tonumber(data[11])/2)*2, (tonumber(data[12])/2)*2, (tonumber(data[13])/2)*2
    local red, green, blue, alpha = tonumber(data[14]), tonumber(data[15]), tonumber(data[16]), tonumber(data[17])
    local bobUpAndDown, faceCamera = toboolean(data[18]), toboolean(data[19])
    local p19 = tonumber(data[20]) or 2
    local rotate = toboolean(data[21])
    local textureDict, textureName = tonil(data[22]), tonil(data[23])
    local drawOnEnts = toboolean(data[24])
    local onButton = toboolean(data[25])
    local key = tonumber(data[26]) or 46
    custMarkers[#custMarkers+1] = {
        type, vector3(posX, posY, posZ), dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts, onButton, key
    }
    cb(true)
end

function toboolean(val) 
    if (type(val) == 'string' and val == 'true') or (type(val) == 'boolean' and val == true) or ( type=='number' and val == 1) then
        return true
    else
        return false
    end
end

function tonil(val) 
    if type(val) == 'string' and val == 'null' or type(val) == 'nil' then
        return nil
    else
        return val
    end
end

Misc = {
    ['cnt:'] = function(cb, args, check)
        if check then
            cb('notification')
            return
        end
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {'cust_objectiveCreator', args[1]}
        })
        cb('notification')
    end,
    ['cmt:'] = function(cb, args, check)
        if check then
            cb('missiontext')
            return
        end
        custMissionText(args[1], args[2], toboolean(args[3]))
        cb('missiontext')
    end,
    ['mar:'] = function(cb, args, check)
        if check then
            cb('marker', toboolean(args[25]), vector3(tonumber(args[2]), tonumber(args[3]), tonumber(args[4])))
            return
        end
        custMarker(args, function(result)
            cb('marker', toboolean(args[25]), vector3(tonumber(args[2]), tonumber(args[3]), tonumber(args[4])))
        end)
    end,
    ['cnp:'] = function(cb, args, check)
        if check then
            cb('ped')
            return
        end
        local model = GetHashKey(args[2])
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(10)
        end
        local ped = CreatePed(tonumber(args[1]) or 1, model, tonumber(args[3]), tonumber(args[4]), tonumber(args[5]), tonumber(args[6]), toboolean(args[7]), toboolean(args[8]))
        custPeds[tostring(args[9])] = ped
        if custLastPed == 0 then
            custLastPed = ped
        end
        cb('ped')
    end,
    ['cvh:'] = function(cb, args, check)
        if check then
            cb('vehicle')
            return
        end
        local model = GetHashKey(args[1])
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(10)
        end
        local veh = CreateVehicle(model, tonumber(args[2]), tonumber(args[3]), tonumber(args[4]), tonumber(args[5]), toboolean(args[6]), toboolean(args[7]))
        custVehicles[tostring(args[8])] = veh
        if custLastVehicle == 0 then
            custLastVehicle = veh
        end
        cb('vehicle')
    end,
    ['cob:'] = function(cb, args, check)
        if check then
            cb('object')
            return
        end
        local model = GetHashKey(args[1])
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(10)
        end
        local obj = CreateObject(model, tonumber(args[2]), tonumber(args[3]), tonumber(args[4]), toboolean(args[5]), toboolean(args[6]), tonumber(args[7]))
        custObjects[tostring(args[8])] = obj
        if custLastObject == 0 then
            custLastObject = obj
        end
        cb('object')
    end,
    ['ani:'] = function(cb, args, check)
        if check then
            cb('animation')
            return
        end
        RequestAnimDict(args[2])
        while not HasAnimDictLoaded(args[2]) do
            Citizen.Wait(10)
        end
        local ped
        if not ped then
            ped = (args[1]=='self' and PlayerPedId()) or (custPeds[args[1]] ~= nil and custPeds[args[1]]) or custLastPed
        end
        TaskPlayAnim(ped, args[2], args[3], tonumber(args[4]), tonumber(args[5]), tonumber(args[6]), tonumber(args[7]), tonumber(args[8]), toboolean(args[9]), toboolean(args[10]), toboolean(args[11]))
        cb('animation')
    end,
    ['sce:'] = function(cb, args, check)
        if check then
            cb('scenario')
            return
        end
        local ped
        if not ped then
            ped = (args[1]=='self' and PlayerPedId()) or (custPeds[args[1]] ~= nil and custPeds[args[1]]) or custLastPed
        end
        TaskStartScenarioInPlace(ped, args[2], tonumber(args[3]), toboolean(args[4]))
        cb('scenario')
    end,
    ['del:'] = function(cb, args, check)
        if check then
            cb('delay')
            return
        end
        Citizen.Wait(tonumber(args[1]) or 0)
        cb('delay')
    end,
    ['awa:'] = function(cb, args, check)
        if check then
            cb('await')
            return
        end
        cb('await', true)
    end,
    ['tce:'] = function(cb, args, check)
        if check then
            cb('triggerevent')
            return
        end
        local toLoad = "TriggerEvent('" .. args[1] .. "'"
        for i=1, #args, 1 do
            if i~=1 then
                args[i] = (tonumber(args[i]) and args[i]) or ("'"..args[i].."'")
                if i~=#args then
                    toLoad = toLoad..","..args[i]
                else
                    toLoad = toLoad..","..args[i]..")"
                end
            else
                if #args == 1 then
                    toLoad = toLoad..")"
                end
            end
        end
        local func, err = load(toLoad)
        if func then
            local ok, add = pcall(func)
        else
            print(err)
        end
        cb('triggerevent')
    end,
    ['tse:'] = function(cb, args, check)
        if check then
            cb('triggerserverevent')
            return
        end
        local toLoad = "TriggerServerEvent('" .. args[1]
        for i=1, #args, 1 do
            if i~=1 then
                args[i] = (tonumber(args[i]) and args[i]) or ("'"..args[i].."'")
                if i~=#args then
                    toLoad = toLoad..","..args[i]
                else
                    toLoad = toLoad..","+ args[i].."')"
                end
            else
                if #args == 1 then
                    toLoad = toLoad..")"
                end
            end
        end
        local func, err = load(toLoad)
        if func then
            local ok, add = pcall(func)
        else
            print(err)
        end
        cb('triggerserverevent')
    end,
    ['clo:'] = function(cb, args, check)
        if check then
            cb('loop')
            return
        end
        cb('loop', true, args[1])
    end,
    ['gtl:'] = function(cb, args, check)
        if check then
            cb('goto')
            return
        end
        cb('goto', true, args[1])
    end,
    ['brk:'] = function(cb, args, check)
        if check then
            cb('break')
            return
        end
        cb('break', true, args[1])
    end
}

Citizen.CreateThread(function()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5)
            if #custMarkers == 0 then
                Citizen.Wait(500)
            else
                local coords = GetEntityCoords(PlayerPedId())
                for i=1, #custMarkers, 1 do
                    local mrk = custMarkers[i]
                    local dist = Vdist2(coords, mrk[2])
                    if dist < 10.0 then
                        DrawMarker(mrk[1], mrk[2], mrk[3], mrk[4], mrk[5], mrk[6], mrk[7], mrk[8], mrk[9], mrk[10], mrk[11], mrk[12], mrk[13], mrk[14], mrk[15], mrk[16], mrk[17], mrk[18], mrk[19], nil, nil, mrk[22])
                        if mrk[23] then
                            if dist < 1.5 then
                                if IsControlJustPressed(1, mrk[24]) then
                                    custButtonPressedOnMarker[mrk[2].x] = true
                                    custMarkers[i] = nil
                                end
                            end
                        else
                            if dist < 1.5 then
                                custInMarker[mrk[2].x] = true
                                custMarkers[i] = nil
                            end
                        end
                    end
                end
            end
        end
    end)    
end)