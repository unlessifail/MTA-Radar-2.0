local dadosJogadores = {}

local function obterNomeLimpo(player)
    return getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
end

local function removerBlipJogador(player)
    local dados = dadosJogadores[player]

    if dados and dados.blip and isElement(dados.blip) then
        destroyElement(dados.blip)
    end

    dadosJogadores[player] = nil
    return true
end

local function criarBlipJogador(player, usarCorAleatoria)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end

    removerBlipJogador(player)

    local r, g, b
    if usarCorAleatoria then
        r, g, b = math.random(0, 255), math.random(0, 255), math.random(0, 255)
        setPlayerNametagColor(player, r, g, b)
    else
        r, g, b = getPlayerNametagColor(player)
    end

    local blip = createBlipAttachedTo(player, 0, 2, r, g, b, 255, 0, CoreRadar.Config.distanciaVisivelBlip)
    if not blip then
        return false
    end

    setElementData(blip, "blipName", obterNomeLimpo(player), false)
    dadosJogadores[player] = {
        blip = blip,
        nome = obterNomeLimpo(player)
    }

    return true
end

addEventHandler("onResourceStart", resourceRoot,
    function()
        math.randomseed(getTickCount())

        for _, player in ipairs(getElementsByType("player")) do
            criarBlipJogador(player, false)
        end
    end
)

addEventHandler("onPlayerJoin", root,
    function()
        criarBlipJogador(source, true)
    end
)

addEventHandler("onPlayerQuit", root,
    function()
        removerBlipJogador(source)
    end
)

addEventHandler("onPlayerChangeNick", root,
    function(_, newNick)
        local dados = dadosJogadores[source]
        if dados and dados.blip and isElement(dados.blip) then
            setElementData(dados.blip, "blipName", tostring(newNick):gsub("#%x%x%x%x%x%x", ""), false)
        end
    end
)
