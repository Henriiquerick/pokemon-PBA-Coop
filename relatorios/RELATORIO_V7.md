# Entrega v7: Brock no co-op LAN

O ponto de partida `--inicio brock` abre a cena real `pewter_city_interiors.tscn` no ponto `pw_gym_in`, posiciona os jogadores perto de `GymArenaCenter` e intercepta a conversa com Brock. A luta usa `Battle.start_trainer_battle` do jogo, os corpos e ataques originais dos Pokémon, e o transporte LAN comprovado nas versões anteriores. O anfitrião calcula a simulação e envia o estado ao convidado. A equipe original de Brock é Geodude 17, Vulpix 18 e Onix 19; Sandshrew 19 completa quatro vagas exclusivamente na luta LAN. A troca de adversário aguarda as duas vagas quando dois desmaios são quase simultâneos. O envio do segundo substituto continua mesmo quando o corpo do primeiro já foi liberado.

A alteração está nos fontes de `campaign_patch/src`; os `.gdc` compilados estão em `payload`. O instalador altera somente uma **cópia** do PCK. Conferiu que a Thunder Stone continua no Poké Mart de Viridian e que Haunter evolui por troca. Os recursos originais não relacionados ao patch foram comparados no PCK instalado. O progresso, as recompensas e os saves da luta permanecem isolados e restaurados após o encontro. Não há integração de insígnia ou de recompensas ainda.

## Testes executados nesta máquina

- Duas instâncias locais reais do executável Godot 4.7.1, perfis APPDATA separados, Brock: vitória em `logs/v7_gym4/win`. Ambos se moveram e atacaram; dano do anfitrião/convidado 173/147; 34 estados de HP iguais; os logs registraram Onix e Sandshrew entrando nas vagas liberadas; ambos voltaram ao mapa; flags, dinheiro e time foram restaurados.
- Regressão Route 2/Ryan: vitória em `logs/v7_final/win`, 31 estados de HP iguais, dano 26/33 e retorno ao mapa.
- Desconexão do convidado durante Brock: `logs/v7_final/drop_guest`, 17 estados iguais até a queda, sessão abortada e anfitrião liberado no mapa.
- Duas janelas com renderização real no ginásio: `logs/v7_visual/visual`, vitória, dano 162/140, 22 estados iguais e retorno ao mapa.
- Repetição de Brock em instalação nova recompilada: `logs/v7_repeat_final3/repeat`, duas vitórias consecutivas, 78 estados de HP iguais, movimento e ataques dos dois jogadores nas duas lutas, controle liberado após cada retorno. O roteiro automático volta ao ponto seguro antes da segunda conversa.
- Teste de inicialização do ponto `pw_gym_in`: a cena e os três treinadores do ginásio carregaram sem `SCRIPT ERROR`. Uma tentativa anterior sem esse ponto não carregou o interior; o ponto correto foi identificado em `data/interiors/pewter.json` e corrigido antes dos testes acima.
- O instalador recompôs o PCK com hash `1d5e4abf7b8619d1bcb54c41dc2050e4e211686db87a8415ef29654a40a4f248` a partir do original e recusou instalar novamente no mesmo destino. `restaurar.py` restaurou o PCK anterior em uma cópia de verificação. A inicialização solo headless registrou `solo_original_boot`, sem `SCRIPT ERROR`; o Godot exibiu avisos de carregamento da extensão Discord e do certificado de sistema nesse ambiente de teste.

## Ainda precisa de teste nos dois PCs

A v7 de Brock **não foi executada pelo Radmin VPN** nesta máquina. Também não havia gamepad físico disponível para verificar o controle do convidado. A conversa manual com Brock e o comportamento com saves pessoais devem ser confirmados pelo usuário. Camper Liam e Hiker Dudley estão preparados no mesmo gatilho LAN, mas não foram validados individualmente. O jogo solo segue sem o modo LAN quando iniciado com `solo`; é preciso verificar a experiência em cada PC após a instalação.
