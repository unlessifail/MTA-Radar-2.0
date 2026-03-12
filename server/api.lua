CoreRadarServidor = CoreRadarServidor or {
    destinos = {}
}

local function ehJogador(player)
    return isElement(player) and getElementType(player) == "player"
end

local function clonarDestino(destino)
    if type(destino) ~= "table" then
        return false
    end

    return CoreRadar.Util.clonarTabela(destino)
end

local function registrarDestinoJogador(player, destino)
    if not ehJogador(player) then
        return false
    end

    if type(destino) == "table" then
        destino.atualizadoEm = CoreRadar.Util.agoraUnix()
        CoreRadarServidor.destinos[player] = destino
    else
        CoreRadarServidor.destinos[player] = nil
    end

    return true
end

addEvent("core_radar:sincronizarDestino", true)
addEventHandler("core_radar:sincronizarDestino", resourceRoot,
    function(destino)
        if not client or not ehJogador(client) then
            return
        end

        if type(destino) == "table" then
            registrarDestinoJogador(client, destino)
        else
            registrarDestinoJogador(client, nil)
        end
    end
)

local function triggerCliente(player, nomeEvento, ...)
    if not ehJogador(player) then
        return false
    end

    triggerClientEvent(player, nomeEvento, resourceRoot, ...)
    return true
end

function definirDestinoJogador(player, x, y, z, iconId, nome)
    x, y, z = CoreRadar.Util.numero(x, nil), CoreRadar.Util.numero(y, nil), CoreRadar.Util.numero(z, 0)
    if not ehJogador(player) or x == nil or y == nil then
        return false
    end

    if not triggerCliente(player, "core_radar:clienteDefinirDestino", x, y, z, iconId, nome) then
        return false
    end

    registrarDestinoJogador(player, {
        tipo = "coordenada",
        x = x,
        y = y,
        z = z,
        iconId = CoreRadar.Util.numero(iconId, CoreRadar.Config.iconeDestinoPadrao),
        nome = CoreRadar.Util.texto(nome, "Destino"),
        rastreando = false
    })

    return true
end

function definirDestinoJogadorPorElemento(player, elemento, iconId, nome)
    if not ehJogador(player) or not isElement(elemento) then
        return false
    end

    if not triggerCliente(player, "core_radar:clienteDefinirDestinoPorElemento", elemento, iconId, nome) then
        return false
    end

    local x, y, z = getElementPosition(elemento)
    registrarDestinoJogador(player, {
        tipo = "elemento",
        x = x,
        y = y,
        z = z,
        iconId = CoreRadar.Util.numero(iconId, CoreRadar.Config.iconeDestinoPadrao),
        nome = CoreRadar.Util.texto(nome, "Destino"),
        rastreando = true,
        element = elemento
    })

    return true
end

function definirDestinoJogadorPorBlip(player, blip, iconId, nome)
    if not ehJogador(player) or not isElement(blip) or getElementType(blip) ~= "blip" then
        return false
    end

    if not triggerCliente(player, "core_radar:clienteDefinirDestinoPorBlip", blip, iconId, nome) then
        return false
    end

    local x, y, z = getElementPosition(blip)
    registrarDestinoJogador(player, {
        tipo = "blip",
        x = x,
        y = y,
        z = z,
        iconId = CoreRadar.Util.numero(iconId, CoreRadar.Config.iconeDestinoPadrao),
        nome = CoreRadar.Util.texto(nome, "Destino"),
        rastreando = true,
        blip = blip
    })

    return true
end

function rastrearDestinoJogadorPorElemento(player, elemento, iconId, nome)
    return definirDestinoJogadorPorElemento(player, elemento, iconId, nome)
end

function limparDestinoJogador(player)
    if not ehJogador(player) then
        return false
    end

    if not triggerCliente(player, "core_radar:clienteLimparDestino") then
        return false
    end

    registrarDestinoJogador(player, nil)
    return true
end

function jogadorTemDestino(player)
    if not ehJogador(player) then
        return false
    end

    return CoreRadarServidor.destinos[player] ~= nil
end

function obterDestinoJogador(player)
    if not ehJogador(player) then
        return false
    end

    return clonarDestino(CoreRadarServidor.destinos[player])
end

function criarBlipCustomizado(x, y, z, iconId, tamanho, r, g, b, a, nome, visivelPara)
    x, y, z = CoreRadar.Util.numero(x, nil), CoreRadar.Util.numero(y, nil), CoreRadar.Util.numero(z, 0)
    if x == nil or y == nil then
        return false
    end

    local blip = createBlip(
        x,
        y,
        z,
        0,
        CoreRadar.Util.numero(tamanho, CoreRadar.Config.tamanhoBlipPadrao),
        CoreRadar.Util.numero(r, 255),
        CoreRadar.Util.numero(g, 255),
        CoreRadar.Util.numero(b, 255),
        CoreRadar.Util.numero(a, 255),
        0,
        CoreRadar.Config.distanciaVisivelBlip,
        isElement(visivelPara) and visivelPara or root
    )

    if not blip then
        return false
    end

    setElementData(blip, "core_radar:icon", CoreRadar.Util.numero(iconId, 0), false)

    if nome and tostring(nome) ~= "" then
        setElementData(blip, "blipName", tostring(nome), false)
    end

    return blip
end

function definirIconeBlipCustomizado(blip, iconId)
    if not isElement(blip) or getElementType(blip) ~= "blip" then
        return false
    end

    setElementData(blip, "core_radar:icon", CoreRadar.Util.numero(iconId, 0), false)
    return true
end

function removerBlipCustomizado(blip)
    if blip and isElement(blip) then
        destroyElement(blip)
        return true
    end

    return false
end

setPlayerGPSDestination = definirDestinoJogador
setPlayerGPSDestinationByElement = definirDestinoJogadorPorElemento
setPlayerGPSDestinationByBlip = definirDestinoJogadorPorBlip
clearPlayerGPSDestination = limparDestinoJogador
playerHasGPSDestination = jogadorTemDestino
getPlayerGPSDestination = obterDestinoJogador

addEventHandler("onPlayerQuit", root,
    function()
        registrarDestinoJogador(source, nil)
    end
)
