var lua = "local function LoadModel(modelHash)\n    RequestModel(modelHash) \n        while not HasModelLoaded(modelHash) do \n       Citizen.Wait(10) \n    end \n    return true\nend\n\nlocal function LoadAnim(animDict)\n    RequestAnimDict(animDict)\n    while not HasAnimDictLoaded(animDict) do\n        Citizen.Wait(10)\n    end\n    return true\nend\n\nlocal function CMT(text, time)\n    text = tostring(text)\n    time = tonumber(time) or 1000\n    ClearPrints()\n    SetTextEntry_2('STRING')\n    AddTextComponentString(text)\n    DrawSubtitleTimed(time, 1)\nend\n\nCitizen.CreateThread(function()"

function luaType(text) {
    if(text=='null'||text=='nil') {
        return 'nil';
    };
    if(text=='true') {
        return 'true';
    };
    if(text=='false') {
        return 'false';
    };
    return false;
};

function TranslateLua(data) {
    let dat = LuaNameList[data.substring(0, 3)];
    let res = dat+'(';
    let str = data.substring(4, data.length);
    let i=0;
    let j=1;
    let lastI = 0;
    let firstData = "";
    let secondData = "";
    let lastData = "";
    for(i;i<str.length;i++) {
        let st = str.substring(i, j);
        if(lastI==0) {
            lastI = i-1;
        };
        if(st==',') {
            let of = str.substring(lastI,j-1);
            if(Number(of)) {
                res = res+of+',';
            } else if(luaType(of)) {
                res = res+of+',';
            } else {
                res = res+'"'+of+'",';
            };
            if(firstData=="") {
                firstData = of;
            };
            if((firstData!=""&&secondData=="")&&firstData!=of) {
                secondData = of;
            };
            lastI = i+1;
        } else if(st==';') {
            let of = str.substring(lastI,j-1);
            if(Number(of)) {
                res = res+of;
            } else if(luaType(of)) {
                res = res+of;
            } else  {
                res = res+'"'+of+'"';
            };
            if(firstData=="") {
                firstData = of;
            };
            if((firstData!=""&&secondData=="")&&firstData!=of) {
                secondData = of;
            };
            lastData = of;
        };
        j++;
    };
    res = res+')';
    let p;
    if(dat.substring(0, 6)=='Create') {
        if(dat=='CreatePed') {
            p = 'local model = ' + "GetHashKey('"+secondData+"')";
            res = res.replace('"'+secondData+'"', "model")
            p = p + "\n    LoadModel(model)\n    local "+lastData+" = "+res;
        } else {
            p = 'local model = ' + "GetHashKey('"+firstData+"')";
            res = res.replace('"'+firstData+'"', "model")
            p = p + "\n    LoadModel(model)\n    local "+lastData+" = "+res;
        };
    };
    if(dat.substring(0,8)=='TaskPlay') {
        p = "RequestModel('"+secondData+"')\n"+res;
    };
    if(p) {
        p = p.replace('"self"', 'PlayerPedId()');
    };
    res = res.replace('"self"', 'PlayerPedId()');
    if(dat=='event') {
        p = "TriggerEvent('chat:addMessage', {\n        multiline = true,\n        color = {255,0,0},\n        args = {'notification','"+firstData+"'}\n    })";
    };
    return p||res;
};