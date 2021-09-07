canStart = true
ongoing = false
robberyStarted = false

Citizen.CreateThread(function()
    hashKey = RequestModel(GetHashKey("a_m_y_business_03"))
    
	
    while not HasModelLoaded(GetHashKey("a_m_y_business_03")) do
        Wait(1)
    end
	
    local npc = CreatePed(4, 0xA1435105, 446.77, -1551.83, 28.28, 177.75, false, true)
    
    SetEntityHeading(npc, 177.75)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
end)

Citizen.CreateThread(function()
exports['qb-target']:AddTargetModel(hashKey, {
	options = {
		{
			event = "startRobbery",
			icon = "far fa-clipboard",
			label = "Ask for a location"
		}
	},
	distance = 2.5,
})
end)

RegisterNetEvent("startRobbery")
AddEventHandler("startRobbery", function()
    if canStart then
        canStart = false
        ongoing = true
        QBCore.Functions.Notify("Starting!", "success")
        local missionWait = math.random( 1000,  1001)
        Citizen.Wait(missionWait)
        SetTimeout(2000, function()
            TriggerServerEvent('qb-phone:server:sendNewMail', {
                sender =  "Mr. Mint",
                subject = "House location",
                message = "This one should be empty. Get all that juice out of there!",
                button = {
                    enabled = true,
                    buttonEvent = "getRandomHouseLoc"
                }
            })
        end)
    elseif ongoing then
        QBCore.Functions.Notify("Your robbery is still in progress.", "error")
    else
        QBCore.Functions.Notify("You cant start another robbery right now.", "error")
    end
end)

RegisterNetEvent("getRandomHouseLoc")
AddEventHandler("getRandomHouseLoc", function()
    local missionTarget = Config.Locations[math.random(#Config.Locations)]
    TriggerEvent("createBlipAndRoute", missionTarget)
    TriggerEvent("createEntry", missionTarget)
end)

RegisterNetEvent("createBlipAndRoute")
AddEventHandler("createBlipAndRoute", function(missionTarget)
    QBCore.Functions.Notify('You recived an robbery location.', "success")
    targetBlip = AddBlipForCoord(missionTarget.location.x, missionTarget.location.y, missionTarget.location.z)
    SetBlipSprite(targetBlip, 374)
    SetBlipColour(targetBlip, 1)
    SetBlipAlpha(targetBlip, 90)
    SetBlipScale(targetBlip, 0.5)
    SetBlipRoute(targetBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Robbery location")
    EndTextCommandSetBlipName(targetBlip)
end)

RegisterNetEvent("createEntry")
AddEventHandler("createEntry", function(missionTarget)
    Citizen.CreateThread(function()
	    local alreadyEnteredZone = false
	    local text = nil
	    while ongoing do
	        wait = 5
	        local ped = PlayerPedId()
	        local inZone = false
	        local dist = #(GetEntityCoords(ped)-vector3(missionTarget.location.x, missionTarget.location.y, missionTarget.location.z))
	        if dist <= 5.0 then
	            wait = 5
	            inZone  = true
	            text = '<b>Entry</b></p>Press [E] to start the robbery'

	            if IsControlJustReleased(0, 38) then
	                TriggerEvent('goInside', missionTarget)
	            end
	        else
	            wait = 2000
	        end
	        
	        if inZone and not alreadyEnteredZone then
	            alreadyEnteredZone = true
	            TriggerEvent('cd_drawtextui:ShowUI', 'show', text)
	        end

	        if not inZone and alreadyEnteredZone then
	            alreadyEnteredZone = false
	            TriggerEvent('cd_drawtextui:HideUI')
	        end
	        Citizen.Wait(wait)
	    end
	end)
end)

RegisterNetEvent("goInside")
AddEventHandler("goInside", function(missionTarget)
    robberyStarted = true
    SetEntityCoords(PlayerPedId(), missionTarget.inside.x, missionTarget.inside.y, missionTarget.inside.z)
    TriggerEvent("createExit", missionTarget)
    TriggerEvent("createLoot", missionTarget)
end)

RegisterNetEvent("createExit")
AddEventHandler("createExit", function(missionTarget)
    Citizen.CreateThread(function()
	    local alreadyEnteredZone = false
	    local text = nil
	    while ongoing do
	        wait = 5
	        local ped = PlayerPedId()
	        local inZone = false
	        local dist = #(GetEntityCoords(ped)-vector3(missionTarget.exit.x, missionTarget.exit.y, missionTarget.exit.z))
	        if dist <= 5.0 then
	            wait = 5
	            inZone  = true
	            text = '<b>Exit</b></p>Press [E] to end the robbery and leave the house.'

	            if IsControlJustReleased(0, 38) then
	                robberyStarted = false
                    ongoing = false
                    SetEntityCoords(PlayerPedId(), missionTarget.location.x, missionTarget.location.y, missionTarget.location.z)
                    cooldownNextRobbery()
                    Citizen.Wait(500)
                    TriggerEvent('cd_drawtextui:HideUI')
	            end
	        else
	            wait = 2000
	        end
	        
	        if inZone and not alreadyEnteredZone then
	            alreadyEnteredZone = true
	            TriggerEvent('cd_drawtextui:ShowUI', 'show', text)
	        end

	        if not inZone and alreadyEnteredZone then
	            alreadyEnteredZone = false
	            TriggerEvent('cd_drawtextui:HideUI')
	        end
	        Citizen.Wait(wait)
	    end
	end)
end)

RegisterNetEvent("createLoot")
AddEventHandler("createLoot", function(missionTarget)
    for i,v in ipairs(missionTarget.loot) do
        --print(i, " ", v)
        local looted = false
        Citizen.CreateThread(function()
            while ongoing do
                local wait = 5000
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                if #(v - pedCoords) < 20 then
                    wait = 1
                    DrawMarker(27, v.x, v.y, v.z - 0.5, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0001, 0, 50, 255, 150, 0, 1, 2,0)
                    if #(v - pedCoords) < 2 then
                        drawTxt3D(v.x, v.y, v.z, "Press [E] to look for stuff here")
                        if IsControlJustPressed(0, 46) then
                            if not looted then
                                beginLoot()
                                looted = true
                            else
                                QBCore.Functions.Notify('You already cheacked here.', "error")
                            end
                        end
                    end
                end
                Wait(wait)
            end
        end)
    end
end)

function drawTxt3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

function beginLoot()
    QBCore.Functions.Progressbar("loot_house", "Looking for stuff...", math.random(6000,12000), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "mini@repair",
		anim = "fixing_a_player",
		flags = 16,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        TriggerServerEvent("robbery:loot")
        ClearPedTasks(PlayerPedId())
    end, function() -- Cancel
        StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        openingDoor = false
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify("Process Canceled", "error")
    end)
end

function cooldownNextRobbery()
    RemoveBlip(targetBlip)
    TriggerEvent('cd_drawtextui:HideUI')
    Citizen.Wait(3000)
    TriggerServerEvent('qb-phone:server:sendNewMail', {
        sender =  "Mr. Mint",
        subject = "Good.",
        message = "Hope you got some good shit from that house. Comeback later and I might have another location for ya.",
        button = {
            enabled = false
        }
    })
    Citizen.Wait(600000) -- Needs a better option. So that client cant just reconnect and reset timer that way.
    canStart = true
    robberyCreated = false
    ongoing = false
end