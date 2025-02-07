local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local config = Config
local UIConfig = UIConfig
--local speedMultiplier = config.UseMPH and 2.23694 or 3.6
local speedMultiplier = config.UseMPH and 1.8589 or 3.0
local seatbeltOn = false
local cruiseOn = false
local showAltitude = false
local showSeatbelt = false
local next = next
local nos = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0
local nitroActive = 0
local harness = 0
local hp = 100
local armed = 0
local parachute = -1
local oxygen = 100
local engine = 0
local dev = false
local admin = false
local playerDead = false
local showMenu = false
local showCircleB = false
local showSquareB = false
local CinematicHeight = 0.2
local w = 0
local radioTalking = false
local Menu = {
    isOutMapChecked = true, -- isOutMapChecked
    isOutCompassChecked = true, -- isOutCompassChecked
    isCompassFollowChecked = true, -- isCompassFollowChecked
    isOpenMenuSoundsChecked = true, -- isOpenMenuSoundsChecked
    isResetSoundsChecked = true, -- isResetSoundsChecked
    isListSoundsChecked = true, -- isListSoundsChecked
    isMapNotifChecked = true, -- isMapNotifChecked
    isLowFuelChecked = true, -- isLowFuelChecked
    isCinematicNotifChecked = true, -- isCinematicNotifChecked
    isMapEnabledChecked = false, -- isMapEnabledChecked
    isToggleMapBordersChecked = true, -- isToggleMapBordersChecked
    isDynamicEngineChecked = true, -- isDynamicEngineChecked
    isDynamicNitroChecked = true, -- isDynamicNitroChecked
    isChangeCompassFPSChecked = true, -- isChangeCompassFPSChecked
    isCompassShowChecked = true, -- isShowCompassChecked
    isShowStreetsChecked = true, -- isShowStreetsChecked
    isPointerShowChecked = true, -- isPointerShowChecked
    isDegreesShowChecked = true, -- isDegreesShowChecked
    isCineamticModeChecked = false, -- isCineamticModeChecked
    isToggleMapShapeChecked = 'square', -- isToggleMapShapeChecked
}

DisplayRadar(false)

local function CinematicShow(bool)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    if bool then
        for i = CinematicHeight, 0, -1.0 do
            Wait(10)
            w = i
        end
    else
        for i = 0, CinematicHeight, 1.0 do
            Wait(10)
            w = i
        end
    end
end

local function loadSettings()
    QBCore.Functions.Notify(Lang:t("notify.hud_settings_loaded"), "success")
    Wait(1000)
    TriggerEvent("hud:client:LoadMap")
end

local function SendAdminStatus()
    SendNUIMessage({
        action = 'menu',
        topic = 'adminonly',
        adminOnly = Config.AdminOnly,
        isAdmin = admin,
    })
end

local function sendUIUpdateMessage(data)
    SendNUIMessage({
        action = 'updateUISettings',
        icons = data.icons,
        layout = data.layout,
        colors = data.colors,
    })
end

local function HandleSetupResource()
    QBCore.Functions.TriggerCallback('hud:server:getRank', function(isAdminOrGreater)
        if isAdminOrGreater then
            admin = true
        else
            admin = false
        end
        SendAdminStatus()
    end)
    if Config.AdminOnly then
        -- Send the client what the saved ui config is (enforced by the server)
        if next(UIConfig) then
            sendUIUpdateMessage(UIConfig)
        end
    end
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(2000)
    HandleSetupResource()
    -- local hudSettings = GetResourceKvpString('hudSettings')
    -- if hudSettings then loadSettings(json.decode(hudSettings)) end
    loadSettings()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    PlayerData = {}
    admin = false
    SendAdminStatus()
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(val)
    PlayerData = val
end)

-- Event Handlers
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000)

    HandleSetupResource()
    -- local hudSettings = GetResourceKvpString('hudSettings')
    -- if hudSettings then loadSettings(json.decode(hudSettings)) end
    loadSettings()
end)

AddEventHandler("pma-voice:radioActive", function(isRadioTalking)
    radioTalking = isRadioTalking
end)

-- Callbacks & Events
RegisterCommand('menu', function()
    Wait(50)
    if showMenu then return end
    TriggerEvent("hud:client:playOpenMenuSounds")
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
    showMenu = true
end)

RegisterNUICallback('closeMenu', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playCloseMenuSounds")
    showMenu = false
    SetNuiFocus(false, false)
end)

RegisterKeyMapping('menu', Lang:t('info.open_menu'), 'keyboard', Config.OpenMenu)

-- Reset hud
local function restartHud()
    TriggerEvent("hud:client:playResetHudSounds")
    QBCore.Functions.Notify(Lang:t("notify.hud_restart"), "error")
    Wait(1500)
    if IsPedInAnyVehicle(PlayerPedId()) then
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = false,
            seatbelt = false,
        })
        Wait(500)
        SendNUIMessage({
            action = 'car',
            topic = 'display',
            show = true,
            seatbelt = false,
        })
    end
    SendNUIMessage({
        action = 'hudtick',
        topic = 'display',
        show = false,
    })
    Wait(500)
    SendNUIMessage({
        action = 'hudtick',
        topic = 'display',
        show = true,
    })
    Wait(500)
    QBCore.Functions.Notify(Lang:t("notify.hud_start"), "success")
    SendNUIMessage({
        action = 'menu',
        topic = 'restart',
    })
end

RegisterNUICallback('restartHud', function(_, cb)
    cb({})
    Wait(50)
    restartHud()
end)

RegisterCommand('resethud', function()
    Wait(50)
    restartHud()
end)

RegisterNUICallback('resetStorage', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:resetStorage")
end)

RegisterNetEvent("hud:client:resetStorage", function()
    Wait(50)
    if Menu.isResetSoundsChecked then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "airwrench", 0.1)
    end
    QBCore.Functions.TriggerCallback('hud:server:getMenu', function(menu) loadSettings(menu); SetResourceKvp('hudSettings', json.encode(menu)) end)
end)

-- Notifications
RegisterNUICallback('openMenuSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isOpenMenuSoundsChecked = true
    else
        Menu.isOpenMenuSoundsChecked = false
    end 
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playOpenMenuSounds", function()
    Wait(50)
    if not Menu.isOpenMenuSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "monkeyopening", 0.5)
end)

RegisterNetEvent("hud:client:playCloseMenuSounds", function()
    Wait(50)
    if not Menu.isOpenMenuSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "catclosing", 0.05)
end)

RegisterNUICallback('resetHudSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isResetSoundsChecked = true
    else
        Menu.isResetSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playResetHudSounds", function()
    Wait(50)
    if not Menu.isResetSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "airwrench", 0.1)
end)

RegisterNUICallback('checklistSounds', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isListSoundsChecked = true
    else
        Menu.isListSoundsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNetEvent("hud:client:playHudChecklistSound", function()
    Wait(50)
    if not Menu.isListSoundsChecked then return end
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "shiftyclick", 0.5)
end)

RegisterNUICallback('showOutMap', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isOutMapChecked = true
    else
        Menu.isOutMapChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('saveUISettings', function(data, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
    TriggerServerEvent("hud:server:saveUIData", data)
end)

RegisterNUICallback('showOutCompass', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isOutCompassChecked = true
    else
        Menu.isOutCompassChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showFollowCompass', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isCompassFollowChecked = true
    else
        Menu.isCompassFollowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showMapNotif', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isMapNotifChecked = true
    else
        Menu.isMapNotifChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showFuelAlert', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isLowFuelChecked = true
    else
        Menu.isLowFuelChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showCinematicNotif', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isCinematicNotifChecked = true
    else
        Menu.isCinematicNotifChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Status
RegisterNUICallback('dynamicChange', function(_, cb)
    cb({})
    Wait(50)
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Vehicle
RegisterNUICallback('HideMap', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        Menu.isMapEnabledChecked = true
    else
        Menu.isMapEnabledChecked = false
    end
    DisplayRadar(Menu.isMapEnabledChecked)
    TriggerEvent("hud:client:playHudChecklistSound")
end)

-- Compass
RegisterNUICallback('showCompassBase', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isCompassShowChecked = true
    else
        Menu.isCompassShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showStreetsNames', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isShowStreetsChecked = true
    else
        Menu.isShowStreetsChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showPointerIndex', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isPointerShowChecked = true
    else
        Menu.isPointerShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('showDegreesNum', function(data, cb)
    cb({})
	Wait(50)
    if data.checked then
        Menu.isDegreesShowChecked = true
    else
        Menu.isDegreesShowChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('changeCompassFPS', function(data, cb)
    cb({})
	Wait(50)
    if data.fps == "optimized" then
        Menu.isChangeCompassFPSChecked = true
    else
        Menu.isChangeCompassFPSChecked = false
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('cinematicMode', function(data, cb)
    cb({})
    Wait(50)
    if data.checked then
        CinematicShow(true)
        if Menu.isCinematicNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.cinematic_on"))
        end
    else
        CinematicShow(false)
        if Menu.isCinematicNotifChecked then
            QBCore.Functions.Notify(Lang:t("notify.cinematic_off"), 'error')
        end
        local player = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(player)
        if (IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle)) or not Menu.isOutMapChecked then
            DisplayRadar(true)
        end
    end
    TriggerEvent("hud:client:playHudChecklistSound")
end)

RegisterNUICallback('updateMenuSettingsToClient', function(data, cb)
    Menu.isOutMapChecked = data.isOutMapChecked
    Menu.isOutCompassChecked = data.isOutCompassChecked
    Menu.isCompassFollowChecked = data.isCompassFollowChecked
    Menu.isOpenMenuSoundsChecked = data.isOpenMenuSoundsChecked
    Menu.isResetSoundsChecked = data.isResetSoundsChecked
    Menu.isListSoundsChecked = data.isListSoundsChecked
    Menu.isMapNotifChecked = data.isMapNotifyChecked
    Menu.isLowFuelChecked = data.isLowFuelAlertChecked
    Menu.isCinematicNotifChecked = data.isCinematicNotifyChecked
    Menu.isMapEnabledChecked = data.isMapEnabledChecked
    Menu.isToggleMapShapeChecked = data.isToggleMapShapeChecked
    Menu.isToggleMapBordersChecked = data.isToggleMapBordersChecked
    Menu.isCompassShowChecked = data.isShowCompassChecked
    Menu.isShowStreetsChecked = data.isShowStreetsChecked
    Menu.isPointerShowChecked = data.isPointerShowChecked
    CinematicShow(data.isCineamticModeChecked)
    cb({})
end)

RegisterNetEvent("hud:client:EngineHealth", function(newEngine)
    engine = newEngine
end)

RegisterNetEvent('hud:client:ToggleAirHud', function()
    showAltitude = not showAltitude
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst) -- Triggered in qb-core
    hunger = newHunger
    thirst = newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress) -- Add this event with adding stress elsewhere
    stress = newStress
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showSeatbelt = not showSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- Triggered in smallresources
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent('seatbelt:client:ToggleCruise', function() -- Triggered in smallresources
    cruiseOn = not cruiseOn
end)

RegisterNetEvent('hud:client:UpdateNitrous', function(hasNitro, nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent("qb-admin:client:ToggleDevmode", function()
    dev = not dev
end)

RegisterNetEvent('hud:client:UpdateUISettings', function(data)
    UIConfig = data
    sendUIUpdateMessage(data)
end)

--- Send player buff infomation to nui
--- @param data table - Buff data
--  {
--      display: boolean - Whether to show buff or not
--      iconName: string - which icon to use
--      name: string - buff name used to identify buff
--      progressValue: number(0 - 100) - current progress of buff shown on icon
--      progressColor: string (hex #ffffff) - progress color on icon
--  }
RegisterNetEvent('hud:client:BuffEffect', function(data)
    if data.progressColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            display = data.display,
            iconColor = data.iconColor,
            iconName = data.iconName,
            buffName = data.buffName,
            progressValue = data.progressValue,
            progressColor = data.progressColor,
        })
    elseif data.progressValue ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            progressValue = data.progressValue,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "buff",
            buffName = data.buffName,
            display = data.display,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:BuffEffect")
    end
end)

RegisterNetEvent('hud:client:EnhancementEffect', function(data)
    if data.iconColor ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            iconColor = data.iconColor,
            enhancementName = data.enhancementName,
        })
    elseif data.display ~= nil then
        SendNUIMessage({
            action = "externalstatus",
            topic = "enhancement",
            display = data.display,
            enhancementName = data.enhancementName,
        })
    else
        print("PS-Hud error: data invalid from client event call: hud:client:EnhancementEffect")
    end
end)

RegisterCommand('+engine', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then return end
    if GetIsVehicleEngineRunning(vehicle) then
        QBCore.Functions.Notify(Lang:t("notify.engine_off"))
    else
        QBCore.Functions.Notify(Lang:t("notify.engine_on"))
    end
    SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
end)

RegisterKeyMapping('+engine', Lang:t('info.toggle_engine'), 'keyboard', 'G')

local function IsWhitelistedWeaponArmed(weapon)
    if weapon then
        for _, v in pairs(config.WhitelistedWeaponArmed) do
            if weapon == v then
                return true
            end
        end
    end
    return false
end

local prevPlayerStats = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }

local function updateShowPlayerHud(show)
    if prevPlayerStats['show'] ~= show then
        prevPlayerStats['show'] = show
        SendNUIMessage({
            action = 'hudtick',
            topic = 'display',
            show = show
        })
    end
end

local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    if shouldUpdate then
        -- Since we found updated data, replace player cache with data
        prevPlayerStats = data
        SendNUIMessage({
            action = 'hudtick',
            topic = 'status',
            show = data[1],
            health = data[2],
            playerDead = data[3],
            armor = data[4],
            thirst = data[5],
            hunger = data[6],
            stress = data[7],
            voice = data[8],
            radioChannel = data[9],
            radioTalking = data[10],
            talking = data[11],
            armed = data[12],
            oxygen = data[13],
            parachute = data[14],
            nos = data[15],
            cruise = data[16],
            nitroActive = data[17],
            harness = data[18],
            hp = data[19],
            speed = data[20],
            engine = data[21],
            cinematic = data[22],
            dev = data[23],
        })
    end
end

-- HUD Update loop

CreateThread(function()
    local wasInVehicle = false
    while true do        
        if LocalPlayer.state.isLoggedIn then
            Wait(500)

            local show = true
            local player = PlayerPedId()
            local playerId = PlayerId()
            local weapon = GetSelectedPedWeapon(player)
            
            -- Player hud
            if not IsWhitelistedWeaponArmed(weapon) then
                -- weapon ~= 0 fixes unarmed on Offroad vehicle Blzer Aqua showing armed bug
                if weapon ~= `WEAPON_UNARMED` and weapon ~= 0 then
                    armed = true
                else
                    armed = false
                end
            end

            playerDead = IsEntityDead(player) or PlayerData.metadata["inlaststand"] or PlayerData.metadata["isdead"] or false
            parachute = GetPedParachuteState(player)

            -- Stamina
            if not IsEntityInWater(player) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(playerId)
            end
            
            -- Oxygen
            if IsEntityInWater(player) then
                oxygen = GetPlayerUnderwaterTimeRemaining(playerId) * 10
            end

            -- Voice setup            
            local talking = NetworkIsPlayerTalking(playerId)
            local voice = 0
            if LocalPlayer.state['proximity'] then
                voice = LocalPlayer.state['proximity'].distance
                -- Player enters server with Voice Chat off, will not have a distance (nil)
                if voice == nil then
                    voice = 0
                end
            end

            if IsPauseMenuActive() then
                show = false
            end

            local vehicle = GetVehiclePedIsIn(player)

            if not (IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle)) then
                updatePlayerHud({
                    show,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state['radioChannel'],
                    radioTalking,
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    -1,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    -1,
                    Menu.isCineamticModeChecked,
                    dev,
                })
            end

            -- Vehicle hud

            if IsPedInAnyHeli(player) or IsPedInAnyPlane(player) then
                showAltitude = true
                showSeatbelt = false
            end

            if IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle) then
                if not wasInVehicle then
                    DisplayRadar(Menu.isMapEnabledChecked)
                end

                wasInVehicle = true
                
                updatePlayerHud({
                    show,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state['radioChannel'],
                    radioTalking,
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    nos,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    (GetVehicleEngineHealth(vehicle) / 10),
                    Menu.isCineamticModeChecked,
                    dev,
                })
                showAltitude = false
                showSeatbelt = true
            else
                DisplayRadar(not Menu.isOutMapChecked)
            end
        else
            -- Not logged in, dont show Status UI (cached)
            updateShowPlayerHud(false)
            DisplayRadar(false)
            Wait(1000)
        end
    end
end)

function isElectric(vehicle)
    local noBeeps = false
    for k, v in pairs(Config.FuelBlacklist) do
        if GetEntityModel(vehicle) == GetHashKey(v) then
            noBeeps = true
        end
    end
    return noBeeps
end

-- Low fuel
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) and not IsThisModelABicycle(GetEntityModel(GetVehiclePedIsIn(ped, false))) and not isElectric(GetVehiclePedIsIn(ped, false)) then
                if GetVehicleFuelLevel(GetVehiclePedIsIn(ped, false)) <= 20 then -- At 20% Fuel Left
                    if Menu.isLowFuelChecked then
                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "pager", 0.10)
                        QBCore.Functions.Notify(Lang:t("notify.low_fuel"), "error")
                        Wait(60000) -- repeats every 1 min until empty
                    end
                end
            end
        end
        Wait(10000)
    end
end)

-- Money HUD

RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        SendNUIMessage({
            action = 'show',
            type = 'cash',
            cash = amount
        })
    else
        SendNUIMessage({
            action = 'show',
            type = 'bank',
            bank = amount
        })
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
    cashAmount = PlayerData.money['cash']
    bankAmount = PlayerData.money['bank']
		if type == 'cash' and amount == 0 then return end
    SendNUIMessage({
        action = 'updatemoney',
        cash = cashAmount,
        bank = bankAmount,
        amount = amount,
        minus = isMinus,
        type = type
    })
end)

-- Minimap update
CreateThread(function()
    while true do
        SetRadarBigmapEnabled(false, false)
        SetRadarZoom(1000)
        Wait(500)
    end
end)

local function BlackBars()
    DrawRect(0.0, 0.0, 2.0, w, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, w, 0, 0, 0, 255)
end

CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do
            Wait(1)
        end
    end
    while true do
        if w > 0 then
            BlackBars()
            DisplayRadar(0)
        end
        Wait(0)
    end
end)

exports['bendixboy-hudmanager']:RegisterHudItem({
    name = 'ps-hud',
    show = function() updateShowPlayerHud(true) end,
    hide = function() updateShowPlayerHud(false) end,
    shouldBeDisplayed = true
})