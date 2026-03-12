Sistema avançado de Radar / GPS para MTA desenvolvido para servidores Roleplay.

Desenvolvido originalmente para o servidor Neapolis Brasil Roleplay.

Recursos

Radar customizado
Sistema de GPS
Blips customizados
Rastreamento de elementos
API Client / Server
Compatível com frameworks RP

Instalação

I. Coloque o resource na pasta:

resources/mta-radar-2.0

II. Inicie o resource:

start mta-radar-2.0

ou adicione no mtaserver.conf.

API

O resource exporta funções para outros scripts.

Exemplo:

exports.core_radar:definirDestinoRadar(x,y,z)

Exemplo

exports.core_radar:definirDestinoRadar(1234,-1000,13, 10, "Destino")

Estrutura:

client/
server/
shared/
gps/
gfx/


Integração

Pode ser integrado com sistemas como:

empregos
polícia
corridas
delivery
missões
corridas ilegais
rastreamento policial

Arquitetura do mta-radar-2.0

O resource é dividido em três camadas principais:

1. CLIENT
2. SERVER
3. SHARED

1. Client

Responsável por:

renderização do radar
atualização do GPS
cálculo de posição no mapa
renderização de blips
rastreamento de elementos

Arquivos principais:

client/main.lua
client/api.lua
client/class/map.lua

2. Server

Responsável por:

sincronizar destino dos jogadores
controle de blips globais
comunicação entre resources

Arquivos:

server/api.lua
server/player_blips.lua

Shared

Contém:

constantes
IDs de ícones
configurações globais

Autor

Kalil M. Santos

Licença

Livre para uso em servidores MTA.
