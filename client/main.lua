Menu = {}
Menu.__index = Menu
Menu.instances = {}

local function inicializarMapas()
    Pages = {}
    Pages.MAPA = {}

    Pages.MAPA.map = Map.new(x * 10, y * 30, x * 1345, y * 708)
    Pages.MAPA.map:setColor(255, 255, 255, 200)

    Pages.MAPA.radar = Map.new(x * 20, y * 599, x * 280, y * 138)
    Pages.MAPA.radar:setColor(255, 255, 255, 190)
    Pages.MAPA.radar.style = 1
    Pages.MAPA.radar:setVisible(true)

    setPlayerHudComponentVisible("radar", false)
end

function onClientResourceStart()
    math.randomseed(getTickCount())
    CoreRadar.sincronizarLegado()
    inicializarMapas()
end
addEventHandler("onClientResourceStart", resourceRoot, onClientResourceStart)

function onClientResourceStop()
    CoreRadar.cancelarTimerDestino()
    setPlayerHudComponentVisible("radar", true)
    toggleControl("radar", true)
end
addEventHandler("onClientResourceStop", resourceRoot, onClientResourceStop)

function isKeyBound(key, keyState, handler)
    local handlers = getFunctionsBoundToKey(key)

    for _, fn in pairs(handlers or {}) do
        if fn == handler then
            return true
        end
    end

    return false
end
