local rastreadores = {}
local sequenciaRastreador = 0

local function gerarIdRastreador()
    sequenciaRastreador = sequenciaRastreador + 1
    return tostring(getTickCount()) .. "_" .. tostring(sequenciaRastreador)
end

local function validarNumero(valor, padrao)
    return CoreRadar.Util.numero(valor, padrao)
end

local function validarTexto(valor, padrao)
    return CoreRadar.Util.texto(valor, padrao)
end

local function aplicarIconeCustomizado(blip, iconId)
    if not isElement(blip) then
        return false
    end

    iconId = validarNumero(iconId, nil)
    if iconId == nil then
        return false
    end

    setElementData(blip, "core_radar:icon", iconId, false)
    return true
end

local function destruirBlipDestinoAtual()
    local blipDestino = CoreRadar.obterBlipDestino()

    if blipDestino and isElement(blipDestino) then
        destroyElement(blipDestino)
    end

    CoreRadar.definirBlipDestino(nil)
end

local function criarBlipDestino(x, y, z, iconId, nome)
    destruirBlipDestinoAtual()

    local blip = createBlip(x, y, z, 0, CoreRadar.Config.tamanhoBlipPadrao, 255, 255, 255, 255, 0, CoreRadar.Config.distanciaVisivelBlip)
    if not blip then
        return false
    end

    aplicarIconeCustomizado(blip, iconId)
    setElementData(blip, "blipName", validarTexto(nome, "Destino"), false)
    CoreRadar.definirBlipDestino(blip)
    return blip
end

local function construirTabelaDestino(destino)
    if not destino then
        return false
    end

    return {
        tipo = destino.tipo,
        x = destino.x,
        y = destino.y,
        z = destino.z,
        iconId = destino.iconId,
        nome = destino.nome,
        rastreando = destino.rastreando or false,
        element = destino.element,
        blip = destino.blip,
        atualizadoEm = CoreRadar.Util.agoraUnix()
    }
end

function CoreRadar.sincronizarDestinoServidor()
    local destino = CoreRadar.obterDestinoAtual()

    if destino then
        triggerServerEvent("core_radar:sincronizarDestino", resourceRoot, construirTabelaDestino(destino))
    else
        triggerServerEvent("core_radar:sincronizarDestino", resourceRoot, false)
    end

    return true
end

local function calcularRotaPara(x, y, z)
    if type(calculatePathByCoords) ~= "function" then
        outputDebugString("[core_radar] calculatePathByCoords indisponível.", 2)
        return false
    end

    local jogadorX, jogadorY, jogadorZ = getElementPosition(localPlayer)
    local rota = calculatePathByCoords(jogadorX, jogadorY, jogadorZ, x, y, z)

    if not rota then
        return false
    end

    local pontos = {}

    for indice, no in ipairs(rota) do
        pontos[#pontos + 1] = { x = no.x, y = no.y, id = indice }
    end

    return pontos
end

local function obterPosicaoDestinoPorReferencia(destino)
    if not destino then
        return false
    end

    if destino.tipo == "elemento" then
        if not isElement(destino.element) then
            return false
        end

        local x, y, z = getElementPosition(destino.element)
        return x, y, z
    end

    if destino.tipo == "blip" then
        if not isElement(destino.blip) then
            return false
        end

        local elementoAnexado = getElementAttachedTo(destino.blip)
        if elementoAnexado and isElement(elementoAnexado) then
            local x, y, z = getElementPosition(elementoAnexado)
            return x, y, z
        end

        local x, y, z = getElementPosition(destino.blip)
        return x, y, z
    end

    return destino.x, destino.y, destino.z
end

local function iniciarRastreamentoSeNecessario(destino)
    CoreRadar.cancelarTimerDestino()

    if not destino or not destino.rastreando then
        return true
    end

    local ultimaPosicaoJogador = { getElementPosition(localPlayer) }
    local ultimaPosicaoAlvo = { obterPosicaoDestinoPorReferencia(destino) }

    local timer = setTimer(function()
        local destinoAtual = CoreRadar.obterDestinoAtual()
        if not destinoAtual or not destinoAtual.rastreando then
            CoreRadar.cancelarTimerDestino()
            return
        end

        local alvoX, alvoY, alvoZ = obterPosicaoDestinoPorReferencia(destinoAtual)
        if not alvoX then
            CoreRadar.limparDestinoRadar()
            return
        end

        local jogadorX, jogadorY, jogadorZ = getElementPosition(localPlayer)
        local recalcular = false

        if not ultimaPosicaoAlvo[1] or CoreRadar.Util.distancia2D(ultimaPosicaoAlvo[1], ultimaPosicaoAlvo[2], alvoX, alvoY) >= CoreRadar.Config.distanciaMinimaRecalculoAlvo then
            recalcular = true
        end

        if CoreRadar.Util.distancia2D(ultimaPosicaoJogador[1], ultimaPosicaoJogador[2], jogadorX, jogadorY) >= CoreRadar.Config.distanciaMinimaRecalculoJogador then
            recalcular = true
        end

        if recalcular or #gpsPontok == 0 then
            local rota = calcularRotaPara(alvoX, alvoY, alvoZ)

            if rota and #rota > 0 then
                destinoAtual.x, destinoAtual.y, destinoAtual.z = alvoX, alvoY, alvoZ
                CoreRadar.definirRotaGPS(rota)
                criarBlipDestino(alvoX, alvoY, alvoZ, destinoAtual.iconId, destinoAtual.nome)
                CoreRadar.definirDestinoAtual(destinoAtual)
                CoreRadar.sincronizarDestinoServidor()
                ultimaPosicaoJogador = { jogadorX, jogadorY, jogadorZ }
                ultimaPosicaoAlvo = { alvoX, alvoY, alvoZ }
            end
        end
    end, CoreRadar.Config.intervaloRastreamentoMs, 0)

    CoreRadar.definirTimerDestino(timer)
    return true
end

local function aplicarDestino(destino)
    local destinoX, destinoY, destinoZ = obterPosicaoDestinoPorReferencia(destino)
    if not destinoX then
        return false
    end

    local rota = calcularRotaPara(destinoX, destinoY, destinoZ)
    if not rota or #rota == 0 then
        return false
    end

    destino.x, destino.y, destino.z = destinoX, destinoY, destinoZ
    destino.iconId = validarNumero(destino.iconId, CoreRadar.Config.iconeDestinoPadrao)
    destino.nome = validarTexto(destino.nome, "Destino")

    CoreRadar.definirRotaGPS(rota)
    criarBlipDestino(destinoX, destinoY, destinoZ, destino.iconId, destino.nome)
    CoreRadar.definirDestinoAtual(destino)
    iniciarRastreamentoSeNecessario(destino)
    CoreRadar.sincronizarDestinoServidor()
    return true
end

function definirDestinoRadar(x, y, z, iconId, nome)
    x, y, z = validarNumero(x, nil), validarNumero(y, nil), validarNumero(z, 0)

    if x == nil or y == nil then
        return false
    end

    return aplicarDestino({
        tipo = "coordenada",
        x = x,
        y = y,
        z = z,
        iconId = iconId,
        nome = nome,
        rastreando = false
    })
end

function definirDestinoRadarPorCoordenada(x, y, z, iconId, nome)
    return definirDestinoRadar(x, y, z, iconId, nome)
end

function definirDestinoPorElemento(elemento, iconId, nome)
    if not isElement(elemento) then
        return false
    end

    return aplicarDestino({
        tipo = "elemento",
        element = elemento,
        iconId = iconId,
        nome = nome,
        rastreando = true
    })
end

function definirDestinoPorBlip(blip, iconId, nome)
    if not isElement(blip) or getElementType(blip) ~= "blip" then
        return false
    end

    return aplicarDestino({
        tipo = "blip",
        blip = blip,
        iconId = iconId,
        nome = nome,
        rastreando = true
    })
end

function rastrearDestinoPorElemento(elemento, iconId, nome)
    return definirDestinoPorElemento(elemento, iconId, nome)
end

function limparDestinoRadar()
    CoreRadar.cancelarTimerDestino()
    CoreRadar.limparDestinoVisual()
    CoreRadar.definirDestinoAtual(nil)
    CoreRadar.sincronizarDestinoServidor()
    return true
end

function existeDestinoRadar()
    return CoreRadar.obterDestinoAtual() ~= nil
end

function obterDestinoRadar()
    local destino = CoreRadar.obterDestinoAtual()
    if not destino then
        return false
    end

    local copia = construirTabelaDestino(destino)
    if type(copia) == "table" then
        copia.element = destino.element
        copia.blip = destino.blip
    end

    return copia
end

function criarBlipCustomizado(x, y, z, iconId, tamanho, r, g, b, a, nome)
    x, y, z = validarNumero(x, nil), validarNumero(y, nil), validarNumero(z, 0)
    if x == nil or y == nil then
        return false
    end

    local blip = createBlip(
        x,
        y,
        z,
        0,
        validarNumero(tamanho, CoreRadar.Config.tamanhoBlipPadrao),
        validarNumero(r, 255),
        validarNumero(g, 255),
        validarNumero(b, 255),
        validarNumero(a, 255),
        0,
        CoreRadar.Config.distanciaVisivelBlip
    )

    if not blip then
        return false
    end

    aplicarIconeCustomizado(blip, iconId)

    if nome and tostring(nome) ~= "" then
        setElementData(blip, "blipName", tostring(nome), false)
    end

    return blip
end

function definirIconeBlipCustomizado(blip, iconId)
    return aplicarIconeCustomizado(blip, iconId)
end

function removerBlipCustomizado(blip)
    if blip and isElement(blip) then
        destroyElement(blip)
        return true
    end

    return false
end

function criarRastreadorElemento(elemento, iconId, nome, tamanho, r, g, b, a)
    if not isElement(elemento) then
        return false
    end

    local blip = createBlipAttachedTo(
        elemento,
        0,
        validarNumero(tamanho, CoreRadar.Config.tamanhoBlipPadrao),
        validarNumero(r, 255),
        validarNumero(g, 255),
        validarNumero(b, 255),
        validarNumero(a, 255),
        0,
        CoreRadar.Config.distanciaVisivelBlip
    )

    if not blip then
        return false
    end

    aplicarIconeCustomizado(blip, iconId)

    if nome and tostring(nome) ~= "" then
        setElementData(blip, "blipName", tostring(nome), false)
    end

    local id = gerarIdRastreador()
    rastreadores[id] = { blip = blip, element = elemento }
    return id
end

function removerRastreadorElemento(id)
    id = tostring(id or "")
    local rastreador = rastreadores[id]

    if not rastreador then
        return false
    end

    if rastreador.blip and isElement(rastreador.blip) then
        destroyElement(rastreador.blip)
    end

    rastreadores[id] = nil
    return true
end

createCustomBlip = criarBlipCustomizado
setBlipCustomIcon = definirIconeBlipCustomizado
destroyCustomBlip = removerBlipCustomizado

setGPSDestination = definirDestinoRadar
clearGPSDestination = limparDestinoRadar
hasGPSDestination = existeDestinoRadar
getGPSDestination = obterDestinoRadar
setGPSDestinationByElement = definirDestinoPorElemento
setGPSDestinationByBlip = definirDestinoPorBlip

trackElement = criarRastreadorElemento
untrackElement = removerRastreadorElemento

CoreRadar.definirDestinoRadar = definirDestinoRadar
CoreRadar.definirDestinoPorElemento = definirDestinoPorElemento
CoreRadar.definirDestinoPorBlip = definirDestinoPorBlip
CoreRadar.limparDestinoRadar = limparDestinoRadar

addEvent("core_radar:clienteDefinirDestino", true)
addEventHandler("core_radar:clienteDefinirDestino", resourceRoot,
    function(x, y, z, iconId, nome)
        definirDestinoRadar(x, y, z, iconId, nome)
    end
)

addEvent("core_radar:clienteDefinirDestinoPorElemento", true)
addEventHandler("core_radar:clienteDefinirDestinoPorElemento", resourceRoot,
    function(elemento, iconId, nome)
        definirDestinoPorElemento(elemento, iconId, nome)
    end
)

addEvent("core_radar:clienteDefinirDestinoPorBlip", true)
addEventHandler("core_radar:clienteDefinirDestinoPorBlip", resourceRoot,
    function(blip, iconId, nome)
        definirDestinoPorBlip(blip, iconId, nome)
    end
)

addEvent("core_radar:clienteLimparDestino", true)
addEventHandler("core_radar:clienteLimparDestino", resourceRoot,
    function()
        limparDestinoRadar()
    end
)

addEventHandler("onClientElementDestroy", root,
    function()
        local destino = CoreRadar.obterDestinoAtual()

        if destino and ((destino.element and destino.element == source) or (destino.blip and destino.blip == source)) then
            limparDestinoRadar()
        end

        for id, rastreador in pairs(rastreadores) do
            if rastreador.element == source then
                if rastreador.blip and isElement(rastreador.blip) then
                    destroyElement(rastreador.blip)
                end

                rastreadores[id] = nil
            end
        end
    end
)
