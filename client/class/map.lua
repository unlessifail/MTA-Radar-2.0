Map = {}
Map.__index = Map
Map.instances = {}
Map.damageEfect = {}

local sx, sy = guiGetScreenSize()
px, py = 1366, 768
x, y = (sx / px), (sy / py)
font = dxCreateFont("gfx/myriadproregular.ttf", 20, true)

function math.map(value, low1, high1, low2, high2)
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
end

function removerPontosGPSProximos()
    for indice, ponto in ipairs(gpsPontok) do
        local jogadorX, jogadorY = getElementPosition(localPlayer)

        if getDistanceBetweenPoints2D(jogadorX, jogadorY, ponto.x, ponto.y) < CoreRadar.Config.distanciaConclusaoNo then
            table.remove(gpsPontok, indice)

            for indiceInterno, pontoInterno in ipairs(gpsPontok) do
                if pontoInterno.id < ponto.id then
                    table.remove(gpsPontok, indiceInterno)
                end
            end

            if #gpsPontok == 0 then
                CoreRadar.limparDestinoVisual()
                CoreRadar.definirDestinoAtual(nil)
                CoreRadar.sincronizarDestinoServidor()
            end

            break
        end
    end
end

kozeliGPSPontokTorlese = removerPontosGPSProximos

function Map.new(posX, posY, largura, altura)
    local self = setmetatable({}, Map)

    self.x = posX
    self.y = posY
    self.w = largura
    self.h = altura

    local posicao = { getElementPosition(localPlayer) }
    self.posX = posicao[1]
    self.posY = posicao[2]
    self.posZ = posicao[3]

    self.size = 90
    self.color = { 255, 255, 255, 255 }
    self.blipSize = x * 17
    self.drawRange = 400
    self.map = dxCreateTexture("gfx/gtasa.png", "dxt5")
    self.renderTarget = dxCreateRenderTarget(largura, altura, true)
    self.blips = {}
    self.blipCache = {}

    for iconId = 0, 63 do
        self.blips[iconId] = dxCreateTexture("gfx/icons/" .. iconId .. ".png", "dxt3")
    end

    if #Map.instances == 0 then
        addEventHandler("onClientRender", root, Map.render)
    end

    table.insert(Map.instances, self)
    return self
end

function Map.render()
    for _, mapa in pairs(Map.instances) do
        if mapa.visible then
            if mapa.style == 1 then
                mapa:draw2()
            else
                mapa:draw()
            end
        end
    end
end

function Map:setVisible(visible)
    self.visible = visible

    if visible == true then
        self:setPosition(getElementPosition(localPlayer))
    end

    return true
end

function Map:isVisible()
    return self.visible
end

function Map:setPosition(posX, posY, posZ)
    self.posX = posX
    self.posY = posY
    self.posZ = posZ
    return true
end

function Map:getPosition()
    return self.posX, self.posY, self.posZ
end

function Map:setColor(r, g, b, a)
    self.color = { r, g, b, a }
    return true
end

function Map:getColor()
    return self.color
end

function Map:getBlipTexture(iconId)
    iconId = tonumber(iconId) or 0

    if self.blips[iconId] then
        return self.blips[iconId]
    end

    if self.blipCache[iconId] then
        return self.blipCache[iconId]
    end

    local caminho = "gfx/icons/" .. iconId .. ".png"
    if fileExists(caminho) then
        local textura = dxCreateTexture(caminho, "dxt3")
        if textura then
            self.blipCache[iconId] = textura
            return textura
        end
    end

    return self.blips[0]
end

function Map:setSize(value)
    self.size = value
    return true
end

function contornoRetangulo(absX, absY, sizeX, sizeY, color, espessura)
    dxDrawRectangle(absX, absY, sizeX, espessura, color)
    dxDrawRectangle(absX, absY + espessura, espessura, sizeY - espessura, color)
    dxDrawRectangle(absX + espessura, absY + sizeY - espessura, sizeX - espessura, espessura, color)
    dxDrawRectangle(absX + sizeX - espessura, absY + espessura, espessura, sizeY - espessura * 2, color)
end

function dxDrawEmptyRec(absX, absY, sizeX, sizeY, color, espessura)
    dxDrawRectangle(absX, absY, sizeX, espessura, color)
    dxDrawRectangle(absX, absY + espessura, espessura, sizeY - espessura, color)
    dxDrawRectangle(absX + espessura, absY + sizeY - espessura, sizeX - espessura, espessura, color)
    dxDrawRectangle(absX + sizeX - espessura, absY + espessura, espessura, sizeY - espessura * 2, color)
end

function Map:draw2()
    dxSetRenderTarget(self.renderTarget, true)

    removerPontosGPSProximos()

    local jogador = localPlayer
    local _, _, cameraRotacaoZ = getElementRotation(getCamera())
    local rotacaoJogador = getPedRotation(jogador)
    local tamanhoMapa = 3000 / (self.drawRange / 500)

    self.posX, self.posY, self.posZ = getElementPosition(jogador)

    local posicaoMapaX = -(math.map(self.posX + 3000, 0, 6000, 0, tamanhoMapa) - self.w / 2)
    local posicaoMapaY = -(math.map(-self.posY + 3000, 0, 6000, 0, tamanhoMapa) - self.h / 2)

    local cameraX, cameraY, _, alvoX, alvoY = getCameraMatrix()
    local norte = findRotation(cameraX, cameraY, alvoX, alvoY)

    dxDrawRectangle(0, 0, self.w, self.h, tocolor(269, 120, 210, 0))
    dxDrawImage(
        posicaoMapaX,
        posicaoMapaY,
        tamanhoMapa,
        tamanhoMapa,
        self.map,
        norte,
        -tamanhoMapa / 2 - posicaoMapaX + self.w / 2,
        -tamanhoMapa / 2 - posicaoMapaY + self.h / 2,
        tocolor(255, 255, 255, 255)
    )

    for _, ponto in ipairs(gpsPontok) do
        local largura, altura = 15, 15
        local pontoMapaX = (3000 + ponto.x) / 6000 * tamanhoMapa
        local pontoMapaY = (3000 - ponto.y) / 6000 * tamanhoMapa
        local larguraEscalada = largura / 6000 * tamanhoMapa
        local alturaEscalada = -(altura / 6000 * tamanhoMapa)

        pontoMapaX = pontoMapaX + posicaoMapaX
        pontoMapaY = pontoMapaY + posicaoMapaY

        dxSetBlendMode("modulate_add")
        dxDrawImage(
            pontoMapaX,
            pontoMapaY,
            larguraEscalada,
            alturaEscalada,
            self.blips[0],
            norte,
            -larguraEscalada / 2 - pontoMapaX + self.w / 2,
            -alturaEscalada / 2 - pontoMapaY + self.h / 2,
            tocolor(124, 197, 118)
        )
        dxSetBlendMode("blend")
    end

    for _, area in ipairs(getElementsByType("radararea")) do
        local areaX, areaY = getElementPosition(area)
        local largura, altura = getRadarAreaSize(area)
        local mapaAreaX = (3000 + areaX) / 6000 * tamanhoMapa
        local mapaAreaY = (3000 - areaY) / 6000 * tamanhoMapa
        local larguraEscalada = largura / 6000 * tamanhoMapa
        local alturaEscalada = -(altura / 6000 * tamanhoMapa)
        local r, g, b, alpha = getRadarAreaColor(area)

        if isRadarAreaFlashing(area) then
            alpha = alpha * math.abs(getTickCount() % 1000 - 500) / 500
        end

        mapaAreaX = mapaAreaX + posicaoMapaX
        mapaAreaY = mapaAreaY + posicaoMapaY

        dxSetBlendMode("modulate_add")
        dxDrawImage(
            mapaAreaX,
            mapaAreaY,
            larguraEscalada,
            alturaEscalada,
            self.blips[1],
            norte,
            -larguraEscalada / 2 - mapaAreaX + self.w / 2,
            -alturaEscalada / 2 - mapaAreaY + self.h / 2,
            tocolor(r, g, b, alpha)
        )
        dxSetBlendMode("blend")
    end

    for _, blip in ipairs(getElementsByType("blip")) do
        if getElementDimension(blip) == getElementDimension(jogador) and getElementInterior(blip) == getElementInterior(jogador) then
            local elementoAnexado = getElementAttachedTo(blip)

            if elementoAnexado ~= jogador then
                local blipX, blipY, _ = getElementPosition(blip)
                local iconId = getElementData(blip, "core_radar:icon") or getBlipIcon(blip)
                local r, g, b, a = 255, 255, 255, 255
                local tamanhoBlip = self.blipSize

                local radarX, radarY = getRadarFromWorldPosition(blipX, blipY, -x * 40, -y * 40, self.w + x * 80, self.h + y * 80, tamanhoMapa)

                if elementoAnexado and getElementType(elementoAnexado) == "vehicle" then
                    tamanhoBlip = tamanhoBlip / 2
                    a = 200
                end

                if iconId == 0 then
                    r, g, b, a = getBlipColor(blip)
                end

                local textura = self:getBlipTexture(iconId)

                if elementoAnexado and getElementType(elementoAnexado) == "player" then
                    textura = self.blips[0]
                    tamanhoBlip = tamanhoBlip / 1.3
                end

                dxDrawImage(radarX - tamanhoBlip / 2, radarY - tamanhoBlip / 2, tamanhoBlip, tamanhoBlip, textura, 0, 0, 0, tocolor(r, g, b, a))

                if elementoAnexado and getElementType(elementoAnexado) == "player" and getPedOccupiedVehicle(elementoAnexado) and getVehicleType(getPedOccupiedVehicle(elementoAnexado)) == "Helicopter" then
                    dxDrawImage(radarX - x * 50 / 2, radarY - y * 50 / 2, x * 50, y * 50, "gfx/H.png", norte - getPedRotation(elementoAnexado))
                    dxDrawImage(radarX - x * 50 / 2, radarY - y * 50 / 2, x * 50, y * 50, "gfx/HR.png", getTickCount() % 360)
                end
            end
        end
    end

    local jogadorX, jogadorY = getElementPosition(jogador)
    local setaX = (3000 + jogadorX) / 6000 * tamanhoMapa
    local setaY = (3000 - jogadorY) / 6000 * tamanhoMapa
    setaX = setaX + posicaoMapaX
    setaY = setaY + posicaoMapaY

    if getPedOccupiedVehicle(jogador) and getVehicleType(getPedOccupiedVehicle(jogador)) == "Helicopter" then
        dxDrawImage(setaX - x * 50 / 2, setaY - y * 50 / 2, x * 50, y * 50, "gfx/H.png", norte - rotacaoJogador)
        dxDrawImage(setaX - x * 50 / 2, setaY - y * 50 / 2, x * 50, y * 50, "gfx/HR.png", getTickCount() % 360)
    else
        dxDrawImage(setaX - x * 23 / 3, setaY - y * 23 / 3, x * 15, y * 15, self.blips[2], norte - rotacaoJogador, 0, 0, tocolor(255, 255, 255, 255))
    end

    dxSetRenderTarget()

    if getElementInterior(jogador) == 0 then
        for _, componente in ipairs({ "radar", "area_name", "vehicle_name" }) do
            setPlayerHudComponentVisible(componente, false)
        end

        dxDrawImage(self.x - x * 17, self.y - y * 9, self.w + x * 33, self.h + y * 18, "gfx/mapbg.png", 0, 0, 0, tocolor(0, 0, 0, 130))
        dxDrawImage(self.x, self.y, self.w, self.h, self.renderTarget, 0, 0, 0, tocolor(unpack(self.color)))
    else
        dxDrawRectangle(self.x, self.y, self.w, self.h, tocolor(0, 0, 0, 130))
    end

    for indice, efeito in ipairs(Map.damageEfect) do
        efeito[3] = efeito[3] - (getTickCount() - efeito[1]) / 800

        if efeito[3] <= 0 then
            table.remove(Map.damageEfect, indice)
        else
            dxDrawImage(self.x, self.y, self.w, self.h, "gfx/mapred.png", 0, 0, 0, tocolor(255, 255, 255, 255))
        end
    end
end

function findRotation(x1, y1, x2, y2)
    local angulo = -math.deg(math.atan2(x2 - x1, y2 - y1))

    if angulo < 0 then
        angulo = angulo + 360
    end

    return angulo
end

function getPointAway(posX, posY, angulo, distancia)
    local radianos = -math.rad(angulo)
    distancia = distancia / 57.295779513082
    return posX + (distancia * math.deg(math.sin(radianos))), posY + (distancia * math.deg(math.cos(radianos)))
end

function getRadarFromWorldPosition(mundoX, mundoY, xPos, yPos, largura, altura, tamanhoMapaEscalado)
    local radarX, radarY = xPos + largura / 2, yPos + altura / 2
    local distanciaRadar = getDistanceBetweenPoints2D(radarX, radarY, xPos, yPos)
    local jogadorX, jogadorY = getElementPosition(localPlayer)
    local _, _, cameraRotacaoZ = getElementRotation(getCamera())
    local distancia = getDistanceBetweenPoints2D(jogadorX, jogadorY, mundoX, mundoY)

    if distancia > distanciaRadar * 6000 / tamanhoMapaEscalado then
        distancia = distanciaRadar * 6000 / tamanhoMapaEscalado
    end

    local rotacao = 180 - findRotation(jogadorX, jogadorY, mundoX, mundoY) + cameraRotacaoZ
    return getPointAway(radarX, radarY, rotacao, distancia * tamanhoMapaEscalado / 6000)
end

function onClientPlayerDamage(attacker, weapon, _, bodypart)
    local slotArma = attacker and getElementType(attacker) == "player" and getPedWeaponSlot(attacker) or false

    if attacker and attacker ~= source and not (slotArma == 8 or (slotArma == 7 and weapon ~= 38)) then
        Map.damageEfect[#Map.damageEfect + 1] = { getTickCount(), 0, math.min(25.5 * bodypart, 255) }
    else
        Map.damageEfect[#Map.damageEfect + 1] = { getTickCount(), 0, math.min(20 * bodypart, 255) }
    end

    if #Map.damageEfect > 18 then
        repeat
            table.remove(Map.damageEfect, 1)
        until #Map.damageEfect < 18
    end
end
addEventHandler("onClientPlayerDamage", localPlayer, onClientPlayerDamage)

function getPointFromDistanceRotation(posX, posY, distancia, angulo)
    local radianos = math.rad(90 - angulo)
    local deslocamentoX = math.cos(radianos) * distancia
    local deslocamentoY = math.sin(radianos) * distancia
    return posX + deslocamentoX, posY + deslocamentoY
end
