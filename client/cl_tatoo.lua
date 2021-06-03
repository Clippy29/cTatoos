Tattoos = Tattoos or {}

ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

Tattoos.Cam = nil
Tattoos.Current = nil
function Tattoos:CloseCamera()
    local pPed = PlayerPedId()
    ClearPedTasks(pPed)
    TriggerEvent('skinchanger:modelLoaded')
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:loadSkin', skin)
    end)
    DestroyCam(Tattoos.Cam)
    RenderScriptCams(false, 0, 1, false, false)

    for _, i in pairs(GetActivePlayers()) do
        NetworkConcealPlayer(i, false, false)
    end
end

function Tattoos:OpenCamera()
    for k, v in pairs(GetActivePlayers()) do 
		if v ~= GetPlayerIndex() then 
			NetworkConcealPlayer(v, true, true) 
		end 
	end

    local pPed = PlayerPedId()
    Tattoos.Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamRot(Tattoos.Cam, 0.0, 0.0, 270.0, true)
    local pCoords, pHeading = GetEntityCoords(pPed), GetEntityHeading(pPed)
    local cCoords = pHeading * math.pi / 180.0
    SetCamCoord(Tattoos.Cam, pCoords.x - 1.5 * math.sin(cCoords), pCoords.y + 1.5 * math.cos(cCoords), pCoords.z + .5)
    SetCamRot(Tattoos.Cam, .0, .0, 120.0, 2)
    PointCamAtEntity(Tattoos.Cam, pPed, .0, .0, .0, true)
    SetCamActive(Tattoos.Cam, true)
    RenderScriptCams(1, 0, 500, 1, 0)
end

Tattoos.ControlDisable = {24, 27, 178, 177, 189, 190, 187, 188, 202, 239, 240, 201, 172, 173, 174, 175}
function OnRenderCam()
    DisableAllControlActions(0)
    for k, v in pairs(Tattoos.ControlDisable) do
        -- Y
        EnableControlAction(0, v, true)
    end
    local Control1, Control2 = IsDisabledControlPressed(1, 44), IsDisabledControlPressed(1, 51)
    if Control1 or Control2 then
        local pPed = PlayerPedId()
        SetEntityHeading(pPed, Control1 and GetEntityHeading(pPed) - 2.0 or Control2 and GetEntityHeading(pPed) + 2.0)

        for k, v in pairs(GetActivePlayers()) do 
            if v ~= GetPlayerIndex() then 
                NetworkConcealPlayer(v, true, true) 
            end 
        end
    end
end

local function onClosetattooShop()
	local Player = PlayerPedId()

	ClearPedDecorations(Player)
	Wait(25)
	for _,k in pairs(Tattoos.Current) do
		ApplyPedOverlay(Player, k[1], k[2])
	end

	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
		TriggerEvent('skinchanger:loadSkin', skin)
	end)

    -- P
	for _, i in pairs(GetActivePlayers()) do
		NetworkConcealPlayer(i, false, false)
	end

    Tattoos:CloseCamera()
end

RegisterNetEvent("cTattoos:GetPlayerTattoos")
AddEventHandler("cTattoos:GetPlayerTattoos", function(playerTattoosList)
    local pPed = PlayerPedId()
	ClearPedDecorations(pPed)
	Wait(25)
	for _,k in pairs(playerTattoosList) do
		ApplyPedOverlay(pPed, k[1], k[2])
	end
	Tattoos.Current = playerTattoosList
end)

local function onButtonSelected(this, id, a, b)
	local Player = PlayerPedId()

	if this ~= "tattoos" then
        -- P
		if Tattoos.List[b.tid] then
			ClearPedDecorations(Player)
			for _,k in pairs(Tattoos.Current) do
				ApplyPedOverlay(Player, k[1], k[2])
			end
			local c, d = table.unpack(Tattoos.List[b.tid])
			Wait(5)
			ApplyPedOverlay(Player, c, d)
		end
	end
end

function Tattoos:LoadMenu()
	local zoneToName = {"Torse", "Tête", "Bras gauche", "Bras droit", "Jambe gauche", "Jambe droite"}
	local niceMenu = { ["tattoos"] = { b = {} } }

	for _,v in pairs(zoneToName) do
		niceMenu["tattoos"].b[#niceMenu["tattoos"].b + 1] = { name = v }
		niceMenu[string.lower(v)] = niceMenu[string.lower(v)] or { b = {} }
	end

	for k,v in pairs(Tattoos.List) do
        -- I
		local zone = zoneToName[GetPedDecorationZoneFromHashes(v[1], v[2]) + 1]
		table.insert(niceMenu[string.lower(zone)].b, { name = ("%s #%s"):format(firstToUpper("Tatouage"), #niceMenu[string.lower(zone)].b + 1), tid = k, price = 500 })
	end

	niceMenu["tattoos"].b[#niceMenu["tattoos"].b + 1] = { name = "Supprimer vos tatouages", price = 500, reset = true }
	return niceMenu
end

RegisterNetEvent("cTattoos:BuySuccess")
AddEventHandler("cTattoos:BuySuccess", function(value)
	table.insert(Tattoos.Current, value)
end)

function Tattoos:PayMoney(money)
    local hasEnough = false
    ESX.TriggerServerCallback("cTattoos:PayMoney", function(hasMoney)
        if not hasMoney then
            ESX.ShowNotification("~r~Vous n'avez pas assez d'argent.")
        end
        hasEnough = hasMoney
    end, money)
    Wait(250)

    return hasEnough
end

Tattoos.Menu = {
    Base = { Header = {"shopui_title_tattoos2", "shopui_title_tattoos2"}, Title = "" },
    Data = { currentMenu = "tattoos" },
    Events = {
        onOpened= function()
            Tattoos:OpenCamera()

            TriggerEvent('skinchanger:getSkin', function(skin)
                if skin.sex == 0 then
                    TriggerEvent('skinchanger:loadClothes', skin, Tattoos.Clothes.naked.m)
                elseif skin.sex == 1 then
                    TriggerEvent('skinchanger:loadClothes', skin, Tattoos.Clothes.naked.f)
                end
            end)
        end,
        onRender = OnRenderCam,
        onBack = function()
            local Player = PlayerPedId()
            ClearPedDecorations(Player)
            Wait(25)
            for _,k in pairs(Tattoos.Current) do
                ApplyPedOverlay(Player, k[1], k[2])
            end
        end,
        onSelected = function(PMenu, menuData, button)
            local Player = PlayerPedId()
            if menuData.currentMenu ~= "tattoos" then
                local c, d = table.unpack(Tattoos.List[button.tid])

                local hasmoney = Tattoos:PayMoney(button.price)
                ClearPedDecorations(Player)
                if hasmoney then 
                    TriggerServerEvent("cTattoos:Save", Tattoos.Current, {c, d})
                else
                    ESX.ShowNotification("~r~Vous n'avez pas assez d'argent.", "danger")
                end

                Wait(150)
                for _,k in pairs(Tattoos.Current) do
                    ApplyPedOverlay(Player, k[1], k[2])
                end
            elseif button.reset then
                --Remove all
                local hasmoney = Tattoos:PayMoney(button.price)
                if hasmoney then 
                    Tattoos.Current = {}
                    ClearPedDecorations(Player)
                    TriggerServerEvent('cTattoos:Delete')
                    CloseMenu(true)
                    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                        TriggerEvent('skinchanger:loadSkin', skin)
                    end)
                else
                    ESX.ShowNotification("~r~Vous n'avez pas assez d'argent.", "danger")
                end
            end
        end,
        onSlide = onSlide,
        onButtonSelected = onButtonSelected,
        onExited = onClosetattooShop,
    },
    Menu = Tattoos:LoadMenu()        
}

Citizen.CreateThread(function()
    Wait(2500)
    TriggerServerEvent("cTattoos:GetTattoosFromPlayer")
    -- C
end)

function CreateBlips(vector3Pos, intSprite, intColor, stringText, boolRoad, floatScale, intDisplay, intAlpha) -- Créer un blips
    -- L
	local blip = AddBlipForCoord(vector3Pos.x, vector3Pos.y, vector3Pos.z)
	SetBlipSprite(blip, intSprite)
	SetBlipAsShortRange(blip, true)
	if intColor then 
		SetBlipColour(blip, intColor) 
	end
	if floatScale then 
		SetBlipScale(blip, floatScale) 
	end
	if boolRoad then 
		SetBlipRoute(blip, boolRoad) 
	end
	if intDisplay then 
		SetBlipDisplay(blip, intDisplay) 
	end
	if intAlpha then 
		SetBlipAlpha(blip, intAlpha) 
	end
	if stringText and (not intDisplay or intDisplay ~= 8) then
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(stringText)
		EndTextCommandSetBlipName(blip)
	end
	return blip
end

Citizen.CreateThread(function()
    Wait(5000)

    for k,v in pairs(Tattoos.Pos) do 
        CreateBlips(v.pos, 75, 46, "Magasin de tatouages", false, 0.7, nil, nil)
    end

    while true do 
        local pPed = PlayerPedId()
        local pPos = GetEntityCoords(pPed)
        local wait = 1000

        if not IsPedInAnyVehicle(pPed, false) then 
            for k,v in pairs(Tattoos.Pos) do 
                local dist = Vdist(pPos, v.pos)

                if dist <= 2.5 then 
                    wait = 5
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder au ~b~magasin~s~.")
                    if IsControlJustPressed(0, 51) then 
                        CreateMenu(Tattoos.Menu)
                    end
                end
            end
        end
        Wait(wait)
    end
end)