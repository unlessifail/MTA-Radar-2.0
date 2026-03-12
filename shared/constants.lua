CoreRadar = CoreRadar or {}

CoreRadar.Config = CoreRadar.Config or {
    iconeDestinoPadrao = 41,
    tamanhoBlipPadrao = 2,
    distanciaVisivelBlip = 99999,
    intervaloRastreamentoMs = 1250,
    distanciaMinimaRecalculoAlvo = 10,
    distanciaMinimaRecalculoJogador = 25,
    distanciaConclusaoNo = 10
}

CoreRadar.NomesPadraoBlip = CoreRadar.NomesPadraoBlip or {
    [42] = "Ministério do Trabalho",
    [55] = "Detran",
    [30] = "Delegacia",
    [17] = "Prefeitura de San Fierro",
    [9] = "Clube Libertário Las Venturas",
    [8] = "Governo Popular de Los Santos",
    [15] = "UBS",
    [35] = "Hospital Particular",
    [20] = "Hospital Público",
    [13] = "Loja",
    [47] = "Comércio Popular",
    [28] = "Auto Posto Cuzzeta",
    [11] = "Starlink Gas",
    [12] = "LS Combustíveis",
    [49] = "Adega",
    [34] = "Hotel",
    [24] = "Biqueira",
    [36] = "Laboratório Ilegal",
    [43] = "Exército Vermelho",
    [29] = "Restaurante",
    [18] = "Concessionária",
    [39] = "Lanches"
}

CoreRadar.Util = CoreRadar.Util or {}

function CoreRadar.Util.numero(valor, padrao)
    valor = tonumber(valor)
    if valor == nil then
        return padrao
    end

    return valor
end

function CoreRadar.Util.texto(valor, padrao)
    if valor == nil then
        return padrao
    end

    valor = tostring(valor)
    if valor == "" then
        return padrao
    end

    return valor
end

function CoreRadar.Util.elementoValido(elemento, tipoEsperado)
    if not isElement(elemento) then
        return false
    end

    if tipoEsperado and getElementType(elemento) ~= tipoEsperado then
        return false
    end

    return true
end

function CoreRadar.Util.clonarTabela(tabelaOrigem, profundidade)
    if type(tabelaOrigem) ~= "table" then
        return tabelaOrigem
    end

    profundidade = tonumber(profundidade) or 0
    if profundidade > 4 then
        return {}
    end

    local copia = {}

    for chave, valor in pairs(tabelaOrigem) do
        if type(valor) == "table" then
            copia[chave] = CoreRadar.Util.clonarTabela(valor, profundidade + 1)
        else
            copia[chave] = valor
        end
    end

    return copia
end

function CoreRadar.Util.distancia2D(x1, y1, x2, y2)
    return getDistanceBetweenPoints2D(x1, y1, x2, y2)
end

function CoreRadar.Util.agoraUnix()
    local tempo = getRealTime()
    if tempo and tempo.timestamp then
        return tempo.timestamp
    end

    return 0
end
