CoreRadar = CoreRadar or {}
CoreRadar.Estado = CoreRadar.Estado or {
    rotaGPS = {},
    blipDestino = nil,
    destinoAtual = nil,
    rastreadores = {},
    timerDestino = nil
}

gpsPontok = gpsPontok or CoreRadar.Estado.rotaGPS
utiBlip = utiBlip or CoreRadar.Estado.blipDestino

function CoreRadar.sincronizarLegado()
    gpsPontok = CoreRadar.Estado.rotaGPS
    utiBlip = CoreRadar.Estado.blipDestino
end

function CoreRadar.definirRotaGPS(rota)
    CoreRadar.Estado.rotaGPS = rota or {}
    CoreRadar.sincronizarLegado()
    return true
end

function CoreRadar.obterRotaGPS()
    return CoreRadar.Estado.rotaGPS
end

function CoreRadar.definirBlipDestino(blip)
    CoreRadar.Estado.blipDestino = blip
    CoreRadar.sincronizarLegado()
    return true
end

function CoreRadar.obterBlipDestino()
    return CoreRadar.Estado.blipDestino
end

function CoreRadar.definirDestinoAtual(destino)
    CoreRadar.Estado.destinoAtual = destino
    return true
end

function CoreRadar.obterDestinoAtual()
    return CoreRadar.Estado.destinoAtual
end

function CoreRadar.definirTimerDestino(timer)
    if CoreRadar.Estado.timerDestino and isTimer(CoreRadar.Estado.timerDestino) then
        killTimer(CoreRadar.Estado.timerDestino)
    end

    CoreRadar.Estado.timerDestino = timer
    return true
end

function CoreRadar.cancelarTimerDestino()
    if CoreRadar.Estado.timerDestino and isTimer(CoreRadar.Estado.timerDestino) then
        killTimer(CoreRadar.Estado.timerDestino)
    end

    CoreRadar.Estado.timerDestino = nil
    return true
end

function CoreRadar.limparDestinoVisual()
    CoreRadar.definirRotaGPS({})

    local blipDestino = CoreRadar.obterBlipDestino()
    if blipDestino and isElement(blipDestino) then
        destroyElement(blipDestino)
    end

    CoreRadar.definirBlipDestino(nil)
    return true
end

CoreRadar.sincronizarDestinoServidor = CoreRadar.sincronizarDestinoServidor or function()
    return true
end
