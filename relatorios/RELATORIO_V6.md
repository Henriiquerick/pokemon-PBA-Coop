# Diagnóstico e validação da v6

Os logs enviados mostram quatro batalhas completas, resultados e HP iguais entre anfitrião e convidado, sem `SCRIPT ERROR`. A captura do usuário mostra o indicador e HP do Bulbasaur, mas o corpo invisível. A preparação anterior ocultava e pausava todas as criaturas do mapa; se o Pokémon escolhido já estivesse solto, o combate podia reutilizar esse mesmo corpo. A v6 reativa visibilidade e processamento do Pokémon principal antes de ler seus comandos.

A campanha LAN anterior só replicava a posição do personagem e o estado de batalha. A v6 acrescenta uma réplica visual do primeiro Pokémon solto no mapa, a toalha/cesta de um piquenique aberto e o estado climático do anfitrião para o convidado. O piquenique remoto é visual; seu menu e efeitos continuam locais. O clima é enviado a cada cinco segundos.

Testes locais em duas instâncias reais do executável Godot 4.7.1, com APPDATA isolado:

- `out_lead`: Bulbasaur foi solto antes da batalha; o host registrou `host_lead_reactivated`, o convidado registrou `remote_companion_visible`, ambos causaram dano, venceram e voltaram ao mapa com estado restaurado.
- `picnic`: o anfitrião criou uma toalha/cesta de teste; o convidado registrou `remote_picnic_visible`, recebeu `weather_synced` e os dois venceram a batalha seguinte.
- `picnic --visible`: duas janelas com renderização real completaram a luta, sem erro de script. A captura automática do mapa ocorreu cedo demais para servir como prova visual do piquenique remoto; a confirmação visual nos dois PCs permanece pendente.

Ainda dependem dos PCs do usuário: chuva simultânea visível, piquenique real aberto pela interface, Pokémon solto em ambos os sentidos e repetição do bug raro de invisibilidade. Os testes locais não medem o comportamento pela Radmin VPN.
