# Validação da campanha LAN em duplas, v3

Build alvo: Pokémon Battle Advanced 0.6.2a, executável Godot 4.7.1. PCK de entrada com Thunder Stone: SHA-256 `0fefbd8092f041d74f628e99eae8eb80bd3f141c0a644a24cf6c7f00e92d81f7`. PCK v3 final: SHA-256 `64d016ebf4c1f756ceffde085711e1f591bcbff9bd0939b8c6c185a77cba7077`.

Teste entre dois PCs com Radmin da **v2 anterior**: relatado como bem-sucedido pelo usuário. A versão v3 ainda precisa desse teste externo. Nenhum controle físico estava disponível localmente.

## Testes executados nesta máquina

`validar_campanha.py` abriu duas instâncias reais do executável em loopback, cada uma com APPDATA isolado. Os logs reproduzíveis estão em `logs/duplas_final2/` e `logs/duplas_delivery/`.

| Caso | Resultado |
| --- | --- |
| `win` final | Ryan iniciou com Rattata e Pidgey ativos; ambos os jogadores deram dano; vitória, HP `[6,34,0,0]`, 63 snapshots aplicados, retorno ao mapa e estado restaurado. |
| `waves` final | Time de teste de quatro adversários em duas vagas, com reposição; ambos deram dano; vitória, 204 snapshots, retorno e estado restaurado. |
| `odd` | Time de teste ímpar recebeu Pidgey temático; dois adversários ativos; vitória, 59 snapshots. |
| `pad` final | Eventos sintéticos do mapeamento original no convidado moveram e atacaram com seu Pokémon; 92 snapshots, vitória. |
| `slot1` final | Time de quatro inimigos; a segunda vaga foi substituída depois do nocaute, 123 snapshots, dano de ambos e vitória. |
| `repeat` | Duas batalhas completas contra Ryan na mesma sessão, ambas vencidas, com movimento após cada retorno. |
| `drop_guest` / `drop_host` | Desconexão injetada em cada lado durante a batalha; sobrevivente voltou à Route 2 com controles liberados. |
| `lose` final | IA derrotou os dois Pokémon; HP `[0,0,25,24]`, 283 snapshots, retorno e estado restaurado. |
| `visual` | Duas janelas renderizadas; captura da Route 2 e da arena com quatro combatentes; o convidado registrou `guest_entry_reveal`. |
| solo | Executável sem argumentos LAN entrou no bootstrap original, sem `LanCampaign` ou `SCRIPT ERROR`; encerrado pelo validador após 12 segundos. |
| arena v1 | `coop_patch/validar_local.py` no PCK v3: vitória, 96 snapshots, dano de ambos e retorno à arena livre. |

O instalador foi executado em um destino vazio e o backup da base com Thunder Stone conferiu; o guia foi copiado e `restaurar.py` devolveu o PCK anterior nessa cópia de verificação. A checagem de hash exato do build final foi repetida em nova instalação após a correção da segunda vaga.

O validador compara HP recebido e enviado por sequência, confirma duas posições de jogadores, dano independente, ausência de gravação de save, restauração do time/flags/dinheiro e controles após a luta. O caso `waves` revelou inicialmente que o convidado continuava mirando um inimigo caído; `_retarget_allies()` foi adicionado. O caso `slot1` revelou uma referência vencida na lista de adversários quando a segunda vaga era reposta; a lista agora é limpa antes do novo corpo entrar. `slot1`, `win` e `pad` passaram no PCK final. Os demais casos aprovados foram feitos antes da última correção, que afeta apenas a reposição da segunda vaga. O executável Godot 4.7.1 carregou o PCK final sem erro de script.

Limites verificados: controle físico e Radmin v3 dependem dos dois PCs do usuário; apenas os quatro treinadores da Route 2 estão conectados ao co-op. O balanceamento de times ímpares para ginásios está no código, mas os ginásios ainda não foram integrados ou testados. Não há aplicação de experiência/recompensas ao save, reunião de jogadores vindos de mapas diferentes nem menus de co-op.
