local resolucao = { guiGetScreenSize() }
local tamanhoMapaGrande = { resolucao[1] - 400, resolucao[2] - 200 }
local posicaoMapaGrande = { resolucao[1] / 2 - tamanhoMapaGrande[1] / 2, resolucao[2] / 2 - tamanhoMapaGrande[2] / 2 }
local corFundoMapa = tocolor(110, 158, 204, 255)
local renderMapaGrande
local tamanhoTexturaRadar = { 3072, 3072 }
local tamanhoBlip = { 20, 20 }
local zoomMapaGrande = 1
local zoomMinimo = 1
local zoomMaximo = 1
local passoZoom = 0.05
local deslocamentoMapa = { 0, 0 }
local origemArrastoMapa = { 0, 0 }

radarMegjelenitve = radarMegjelenitve or false

addEventHandler("onClientResourceStart", root,
    function(resource)
        if resource ~= getThisResource() then
            return
        end

        toggleControl("radar", true)
        renderMapaGrande = dxCreateRenderTarget(tamanhoMapaGrande[1], tamanhoMapaGrande[2], false)
    end
)

addEventHandler("onClientKey", root,
    function(tecla, pressionada)
        if tecla == "F11" and pressionada then
            alternarMapaGrande()
            cancelEvent()
        end
    end
)

function alternarMapaGrande()
    if radarMegjelenitve then
        radarMegjelenitve = false
        ocultarMapaGrande()
        showChat(true)
        showCursor(false)
        addEventHandler("onClientRender", root, Map.render)
    else
        radarMegjelenitve = true
        exibirMapaGrande()
        showChat(false)
        deslocamentoMapa = { 0, 0 }
        removeEventHandler("onClientRender", root, Map.render)
        showCursor(true, false)
    end
end

togRadar = alternarMapaGrande

function exibirMapaGrande()
    if not radarMegjelenitve then
        return
    end

    addEventHandler("onClientRender", root, renderizarMapaGrande)
end

ujRadarMegjelenites = exibirMapaGrande

addEventHandler("onClientMouseWheel", root,
    function(sentido)
        if not radarMegjelenitve then
            return
        end

        if sentido == 1 then
            if zoomMapaGrande < zoomMaximo then
                zoomMapaGrande = zoomMapaGrande + passoZoom
            end
        elseif sentido == -1 then
            if zoomMapaGrande > zoomMinimo then
                zoomMapaGrande = zoomMapaGrande - passoZoom
            end
        end
    end
)

function planejarRotaPorCoordenadas(origemX, origemY, origemZ, destinoX, destinoY, destinoZ)
    local rota = calculatePathByCoords(origemX, origemY, origemZ, destinoX, destinoY, destinoZ)

    if not rota then
        outputConsole("Nenhum destino encontrado.")
        return false
    end

    local pontos = {}

    for indice, no in ipairs(rota) do
        pontos[#pontos + 1] = { x = no.x, y = no.y, id = indice }
    end

    CoreRadar.definirRotaGPS(pontos)
    return true
end

utvonalTervezes = planejarRotaPorCoordenadas

function processarCliqueMapaGrande(botao, estado, cursorX, cursorY)
    if not radarMegjelenitve then
        return
    end

    if botao == "right" and estado == "down" then
        if cursorX > posicaoMapaGrande[1] and cursorX < posicaoMapaGrande[1] + tamanhoMapaGrande[1] and cursorY > posicaoMapaGrande[2] and cursorY < posicaoMapaGrande[2] + tamanhoMapaGrande[2] then
            if #gpsPontok == 0 then
                local jogadorX, jogadorY, _ = getElementPosition(localPlayer)
                jogadorX, jogadorY = jogadorX + deslocamentoMapa[1], jogadorY + deslocamentoMapa[2]

                local destinoX = jogadorX + ((((cursorX - posicaoMapaGrande[1]) - (tamanhoMapaGrande[1] / 2)) * 2) * zoomMapaGrande)
                local destinoY = jogadorY - ((((cursorY - posicaoMapaGrande[2]) - (tamanhoMapaGrande[2] / 2)) * 2) * zoomMapaGrande)

                CoreRadar.definirDestinoRadar(destinoX, destinoY, 0, CoreRadar.Config.iconeDestinoPadrao, "Destino")
            else
                CoreRadar.limparDestinoRadar()
            end
        end
    elseif botao == "left" then
        if estado == "down" then
            origemArrastoMapa = { cursorX + deslocamentoMapa[1], cursorY - deslocamentoMapa[2] }
        elseif estado == "up" then
            origemArrastoMapa = { 0, 0 }
        end
    end
end
addEventHandler("onClientClick", root, processarCliqueMapaGrande)

nagyMapKattintas = processarCliqueMapaGrande

function renderizarMapaGrande()
    if not renderMapaGrande then
        return
    end

    local blurResource = getResourceFromName("zGPainelBlur")

    if blurResource and getResourceState(blurResource) == "running" then
        local sucesso = pcall(function()
            exports["zGPainelBlur"]:dxDrawBluredRectangle(posicaoMapaGrande[1], posicaoMapaGrande[2], tamanhoMapaGrande[1], tamanhoMapaGrande[2], tocolor(255, 255, 255, 255))
        end)

        if not sucesso then
            dxDrawRectangle(posicaoMapaGrande[1], posicaoMapaGrande[2], tamanhoMapaGrande[1], tamanhoMapaGrande[2], tocolor(0, 0, 0, 140))
        end
    else
        dxDrawRectangle(posicaoMapaGrande[1], posicaoMapaGrande[2], tamanhoMapaGrande[1], tamanhoMapaGrande[2], tocolor(0, 0, 0, 140))
    end

    if origemArrastoMapa[1] ~= 0 or origemArrastoMapa[2] ~= 0 then
        local cursorX, cursorY = getCursorPosition()

        if cursorX and cursorY then
            cursorX, cursorY = cursorX * resolucao[1], cursorY * resolucao[2]
            deslocamentoMapa = { cursorX - origemArrastoMapa[1], cursorY - origemArrastoMapa[2] }
            deslocamentoMapa = {
                math.max(math.min(-deslocamentoMapa[1], 6000), -6000),
                math.max(math.min(deslocamentoMapa[2], 6000), -6000)
            }
        end
    end

    if getKeyState("num_add") and zoomMapaGrande > zoomMinimo then
        zoomMapaGrande = zoomMapaGrande - passoZoom
    end

    if getKeyState("num_sub") and zoomMapaGrande < zoomMaximo then
        zoomMapaGrande = zoomMapaGrande + passoZoom
    end

    if getKeyState("num_4") then
        deslocamentoMapa[1] = deslocamentoMapa[1] - 5
    end

    if getKeyState("num_6") then
        deslocamentoMapa[1] = deslocamentoMapa[1] + 5
    end

    dxSetRenderTarget(renderMapaGrande, true)
    dxDrawRectangle(0, 0, tamanhoMapaGrande[1], tamanhoMapaGrande[2], corFundoMapa, false)

    local jogadorX, jogadorY, _ = getElementPosition(localPlayer)
    jogadorX, jogadorY = jogadorX + deslocamentoMapa[1], jogadorY + deslocamentoMapa[2]

    local secaoX = (((3000) + jogadorX) / 6000 * tamanhoTexturaRadar[1]) - ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande)
    local secaoY = ((3000 - jogadorY) / 6000 * tamanhoTexturaRadar[2]) - ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande)
    local secaoLargura = tamanhoMapaGrande[1] * zoomMapaGrande
    local secaoAltura = tamanhoMapaGrande[2] * zoomMapaGrande
    local ajusteX, ajusteY = 0, 0

    if secaoY + (tamanhoMapaGrande[2] * zoomMapaGrande) >= tamanhoTexturaRadar[2] then
        ajusteY = tamanhoTexturaRadar[2] - (secaoY + (tamanhoMapaGrande[2] * zoomMapaGrande))
    end

    if secaoY <= 0 then
        ajusteY = 0 - secaoY
    end

    if secaoX + (tamanhoMapaGrande[1] * zoomMapaGrande) >= tamanhoTexturaRadar[1] then
        ajusteX = tamanhoTexturaRadar[1] - (secaoX + (tamanhoMapaGrande[1] * zoomMapaGrande))
    end

    if secaoX <= 0 then
        ajusteX = 0 - secaoX
    end

    dxDrawImageSection(
        0 + (ajusteX / zoomMapaGrande),
        0 + (ajusteY / zoomMapaGrande),
        tamanhoMapaGrande[1],
        tamanhoMapaGrande[2],
        secaoX + ajusteX,
        secaoY + ajusteY,
        secaoLargura,
        secaoAltura,
        "gfx/gtasa.png",
        0,
        0,
        0,
        tocolor(255, 255, 255, 255),
        false
    )

    local ultimoX, ultimoY = nil, nil

    for _, ponto in ipairs(gpsPontok) do
        local pontoX = (((((3000) + ponto.x) / (6000) * tamanhoTexturaRadar[1]) - ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande) - secaoX) + ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande)) / zoomMapaGrande
        local pontoY = (((((3000 - ponto.y) / (6000) * tamanhoTexturaRadar[2]) - ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande) - secaoY) + ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande))) / zoomMapaGrande

        if ultimoX and ultimoY then
            dxDrawLine(ultimoX, ultimoY, pontoX, pontoY, tocolor(144, 0, 254, 255), 8)
        end

        ultimoX, ultimoY = pontoX, pontoY
    end

    for _, area in ipairs(getElementsByType("radararea")) do
        local larguraArea, alturaArea = getRadarAreaSize(area)
        local posAreaX, posAreaY, _ = getElementPosition(area)
        local areaX = (((((3000) + posAreaX) / (6000) * tamanhoTexturaRadar[1]) - ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande) - secaoX) + ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande)) / zoomMapaGrande
        local areaY = (((((3000 - posAreaY) / (6000) * tamanhoTexturaRadar[2]) - ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande) - secaoY) + ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande))) / zoomMapaGrande
        local r, g, b, alpha = getRadarAreaColor(area)

        if isRadarAreaFlashing(area) then
            alpha = alpha * math.abs(getTickCount() % 1000 - 500) / 500
        end

        dxDrawRectangle(areaX - larguraArea / 2 + larguraArea / 1.8, areaY - alturaArea / 2 - alturaArea / 1.8, larguraArea / 2, alturaArea / 2, tocolor(r, g, b, alpha))
    end

    for _, blip in ipairs(getElementsByType("blip")) do
        local iconId = getElementData(blip, "core_radar:icon") or getBlipIcon(blip)
        local blipX, blipY = getElementPosition(blip)
        local desenhoX = (((((3000) + blipX) / (6000) * tamanhoTexturaRadar[1]) - ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande) - secaoX) + ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande)) / zoomMapaGrande
        local desenhoY = (((((3000 - blipY) / (6000) * tamanhoTexturaRadar[2]) - ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande) - secaoY) + ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande))) / zoomMapaGrande

        desenhoX = math.min(math.max(desenhoX, tamanhoBlip[1] / 2), tamanhoMapaGrande[1] - tamanhoBlip[2] / 2)
        desenhoY = math.min(math.max(desenhoY, tamanhoBlip[2] / 2), tamanhoMapaGrande[2] - tamanhoBlip[2] / 2)

        local r, g, b = 255, 255, 255

        if getBlipIcon(blip) == 0 then
            r, g, b = getBlipColor(blip)
        end

        dxDrawImage(desenhoX - tamanhoBlip[1] / 2, desenhoY - tamanhoBlip[2] / 2, tamanhoBlip[1], tamanhoBlip[2], "gfx/icons/" .. iconId .. ".png", 0, 0, 0, tocolor(r, g, b, 255))

        local cursorX, cursorY = getCursorPosition()
        if cursorX and cursorY then
            cursorX, cursorY = cursorX * resolucao[1] - posicaoMapaGrande[1], cursorY * resolucao[2] - posicaoMapaGrande[2]

            if estaDentroDaArea(desenhoX - tamanhoBlip[1] / 2, desenhoY - tamanhoBlip[2] / 2, tamanhoBlip[1], tamanhoBlip[2], cursorX, cursorY) then
                local nomeBlip = getElementData(blip, "blipName") or CoreRadar.NomesPadraoBlip[getBlipIcon(blip)] or "Nome indisponível"
                local larguraTooltip = dxGetTextWidth(nomeBlip, 0.7, "default-bold") + 40

                desenharCaixaTooltip(desenhoX - larguraTooltip / 2, desenhoY + tamanhoBlip[2], larguraTooltip, 20, tocolor(20, 20, 20, 150), tocolor(0, 0, 0, 200))
                desenharTexto(nomeBlip, desenhoX - larguraTooltip / 2, desenhoY + tamanhoBlip[2], larguraTooltip, 20, tocolor(255, 255, 255, 220), 1, "default-bold", "center", "center", true, true, false, 0, 0, 0)
            end
        end
    end

    local rotacao = getPedRotation(localPlayer)
    local posJogadorX, posJogadorY, _ = getElementPosition(localPlayer)
    local indicadorX = (((((3000) + posJogadorX) / (6000) * tamanhoTexturaRadar[1]) - ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande) - secaoX) + ((tamanhoMapaGrande[1] / 2) * zoomMapaGrande)) / zoomMapaGrande
    local indicadorY = (((((3000 - posJogadorY) / (6000) * tamanhoTexturaRadar[2]) - ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande) - secaoY) + ((tamanhoMapaGrande[2] / 2) * zoomMapaGrande))) / zoomMapaGrande
    dxDrawImage(indicadorX - tamanhoBlip[1] / 2, indicadorY - tamanhoBlip[2] / 2, tamanhoBlip[1], tamanhoBlip[2], "gfx/icons/2.png", -rotacao, 0, 0, tocolor(255, 255, 255, 255))

    dxSetRenderTarget()

    dxCreateBorder(posicaoMapaGrande[1], posicaoMapaGrande[2], tamanhoMapaGrande[1], tamanhoMapaGrande[2], tocolor(0, 0, 0, 200))
    dxDrawImage(posicaoMapaGrande[1], posicaoMapaGrande[2], tamanhoMapaGrande[1], tamanhoMapaGrande[2], renderMapaGrande, 0, 0, 0, tocolor(255, 255, 255, 200))
end

ujRadarRender = renderizarMapaGrande

function desenharTexto(texto, posX, posY, largura, altura, cor, escala, fonte, alinhamentoX, alinhamentoY, clip, quebraLinha, postGUI, rotacao, rotacaoX, rotacaoY, subPixel)
    if not subPixel then
        subPixel = false
    end

    dxDrawText(texto, posX, posY, posX + largura, posY + altura, cor, escala, fonte or "default-bold", alinhamentoX, alinhamentoY, clip, quebraLinha, postGUI, subPixel, false, rotacao, rotacaoX, rotacaoY)
end

fontSzovegRender = desenharTexto

function estaDentroDaArea(areaX, areaY, largura, altura, cursorX, cursorY)
    return cursorX >= areaX and cursorX <= areaX + largura and cursorY >= areaY and cursorY <= areaY + altura
end

dobozbaVan = estaDentroDaArea

function isInSlot(posX, posY, largura, altura)
    if isCursorShowing() then
        local telaX, telaY = guiGetScreenSize()
        local cursorX, cursorY = getCursorPosition()

        cursorX, cursorY = cursorX * telaX, cursorY * telaY
        return estaDentroDaArea(posX, posY, largura, altura, cursorX, cursorY)
    end

    return false
end

function dxCreateBorder(posX, posY, largura, altura, cor)
    dxDrawRectangle(posX - 3, posY - 3, largura + 6, 3, cor)
    dxDrawRectangle(posX - 3, posY, 3, altura, cor)
    dxDrawRectangle(posX - 3, posY + altura, largura + 6, 3, cor)
    dxDrawRectangle(posX + largura, posY - 3, 3, altura + 3, cor)
end

local sombraCaixa = { 15, 3 }
local espacoCaixa = { 17, 1, 0, 5 }

function desenharCaixaTooltip(posX, posY, largura, altura, corFundo, corBorda, postGUI)
    dxDrawRectangle(posX, posY + espacoCaixa[4] / 2, 1, altura - espacoCaixa[4], corBorda or tocolor(60, 63, 63, 255), postGUI)
    dxDrawRectangle(posX + largura - (espacoCaixa[1] - sombraCaixa[1] - 1), posY + espacoCaixa[4] / 2, 1, altura - espacoCaixa[4], corBorda or tocolor(60, 63, 63, 255), postGUI)
    dxDrawRectangle(posX + espacoCaixa[4] / 2, posY, largura - espacoCaixa[4], 1, corBorda or tocolor(60, 63, 63, 255), postGUI)
    dxDrawRectangle(posX + espacoCaixa[4] / 2, posY + altura - (espacoCaixa[1] - sombraCaixa[1] - 1), largura - espacoCaixa[4], 1, corBorda or tocolor(60, 63, 63, 255), postGUI)
    dxDrawRectangle(posX + 1, posY + 1, largura - 2, altura - 2, corFundo or tocolor(60, 63, 63, 100), postGUI)
end

formDobozRajzolasa = desenharCaixaTooltip

function ocultarMapaGrande()
    if radarMegjelenitve then
        return
    end

    removeEventHandler("onClientRender", root, renderizarMapaGrande)
end

ujRadarElrejtes = ocultarMapaGrande

function isEventHandlerAdded(nomeEvento, elemento, funcao)
    if type(nomeEvento) == "string" and isElement(elemento) and type(funcao) == "function" then
        local funcoes = getEventHandlers(nomeEvento, elemento)

        if type(funcoes) == "table" and #funcoes > 0 then
            for _, handler in ipairs(funcoes) do
                if handler == funcao then
                    return true
                end
            end
        end
    end

    return false
end
