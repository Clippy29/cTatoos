ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent("cTattoos:GetTattoosFromPlayer")
AddEventHandler("cTattoos:GetTattoosFromPlayer", function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll("SELECT * FROM user_tattoos WHERE identifier = @identifier", {['@identifier'] = xPlayer.identifier}, function(result)
        if(result[1] ~= nil) then
            local tattoosList = json.decode(result[1].tattoos)
            TriggerClientEvent("cTattoos:GetPlayerTattoos", _source, tattoosList)
        else
            local tattooValue = json.encode({})
            MySQL.Async.execute("INSERT INTO user_tattoos (identifier, tattoos) VALUES (@identifier, @tattoo)", {['@identifier'] = xPlayer.identifier, ['@tattoo'] = tattooValue})
            TriggerClientEvent("cTattoos:GetPlayerTattoos", _source, {})
        end
    end)
end)

RegisterServerEvent("cTattoos:Delete")
AddEventHandler("cTattoos:Delete", function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.execute('DELETE FROM user_tattoos WHERE identifier = @identifier', {
      ['@identifier'] = xPlayer.identifier
    }, function(rowsChanged)
      tattoosList = {}
      TriggerClientEvent('esx:showNotification', xPlayer.source, "~r~Vous venez de supprimer tous vos tatouages.", "danger")
    end)
end)

RegisterServerEvent("cTattoos:Save")
AddEventHandler("cTattoos:Save", function(tattoosList, value)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    table.insert(tattoosList, value)
    MySQL.Async.execute("UPDATE user_tattoos SET tattoos = @tattoos WHERE identifier = @identifier", {['@tattoos'] = json.encode(tattoosList), ['@identifier'] = xPlayer.identifier})
    TriggerClientEvent("cTattoos:BuySuccess", _source, value)
    TriggerClientEvent("esx:showNotification", _source, "~g~Vous venez de vous faire un tatouage.", "success")
end)

ESX.RegisterServerCallback("cTattoos:PayMoney", function(source, cb, money)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.getMoney() >= money then
		cb(true)
		xPlayer.removeMoney(money)
	else
		cb(false)
	end
end)