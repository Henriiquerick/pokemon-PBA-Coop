# v9: diagnóstico e validação

Nos logs enviados da v8, o convidado passou pelo portão da Viridian Forest e ficou mais de dez segundos sem enviar presença durante o carregamento. O mod registrou `timeout` ao voltar ao mapa mundial. A v9 envia pings mesmo quando a instância do personagem ainda não existe durante a troca de cena e aumenta o limite de perda de comunicação para 45 segundos. O log do convidado não inclui `SCRIPT ERROR` nem código de saída; há avisos de cache de shader e da extensão Discord. Portanto, o motivo exato do fechamento do executável não foi demonstrado. O lançador v9 agora anexa o código de saída ao log para a próxima investigação.

A v8 impedia `grass_encounter`, `surf_encounter` e `Battle.start_battle` sempre que o nó LAN existia. A v9 permite essas rotinas quando não há batalha cooperativa ativa. Cada encontro selvagem comum roda no sistema solo original e permanece local. O estado de ocupação do jogador viaja com a presença LAN; o anfitrião não inicia treinador cooperativo enquanto o convidado luta sozinho. Se uma solicitação chegar no mesmo instante, o convidado a recusa e o anfitrião libera o mapa sem aguardar o timeout.

O lançador importa automaticamente uma cópia do `save.json` pessoal e verifica que há um Pokémon não ovo com HP positivo. O jogo confirma o primeiro Pokémon apto antes de criar a conexão. A cena, o ponto de entrada, a posição e a direção são lidos do save; o estado do time, os desbloqueios e os itens são individuais. Saves originais não recebem gravações. O perfil gerado para testes automáticos continua disponível apenas com `--coop-autotest`.

## Testes locais executados

- Save pessoal real de 0.6.2a, com cinco Pokémon: host e guest inicializaram na posição salva em Viridian City, sem erro de script (`logs/v9_personal_smoke`).
- Dois saves de teste distintos carregaram e se conectaram em processos separados: Bulbasaur no host, Charmander no guest (`logs/v9_two_saves`).
- Save sem Pokémon: o lançador recusou a conexão antes de abrir o jogo (`logs/v9_save_gate`).
- Encontro de grama real em duas instâncias: apenas o host entrou em batalha 1 contra 1, o guest permaneceu no mapa, e o host retornou com controles e conexão ativos (`logs/v9_wild_final`).
- Regressão de treinador Route 2/Ryan: vitória, dano dos dois jogadores e 32 estados de HP coincidentes na build final (`logs/v9_final_route2`).
- Regressão de Brock entre mapas: vitória, dano dos dois jogadores, 38 estados de HP coincidentes e retorno ao mapa (`logs/v9_split`).
- Instalador recusou uma segunda aplicação no destino v9; `restaurar.py` repôs o PCK anterior em uma cópia de verificação. O PCK final instalado foi conferido pelo hash do registro.

Ainda dependem dos dois PCs Windows: confirmar que a mudança de mapa lenta não gera mais timeout, repetir encontro selvagem em cada lado com teclado/gamepad físico, testar os saves pessoais de ambos e obter o novo código de saída se o segundo PC fechar novamente. A experiência, as recompensas e o progresso continuam sem gravação nesta etapa.
