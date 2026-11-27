# v8: reunião entre Route 2 e ginásio

Os logs da v7 enviados pelo usuário mostram duas vitórias iguais nos dois PCs. Depois da segunda luta, o anfitrião saiu do ginásio e a sessão registrou `map_changed`; o convidado recebeu `timeout`. A v8 mantém o nó LAN no root durante a troca de cena e recria a representação do parceiro quando o personagem da campanha muda de instância. O convite de batalha aceita a Route 2 e o ginásio de Pewter como cenas de origem/destino. O convidado guarda sua cena, posição e orientação, viaja ao centro da luta e retorna ao local de origem ao encerrar. O anfitrião continua responsável pela simulação, IA, dano, HP e resultado.

A entrada `--inicio split` inicia Brock no anfitrião e Route 2 no convidado em saves de teste isolados. O teste vale para esses dois cenários; outros mapas, histórias e encontros não foram validados. A batalha e a equipe de quatro Pokémon de Brock permanecem como na v7. A v8 ainda não aplica insígnias, experiência ou recompensas.

## Validação local

- Duas instâncias reais da v8, em cenas diferentes, venceram Brock; o convidado registrou `join_map_done` e `return_map_done`, ambos causaram dano, 39 snapshots de HP coincidiram e os dois retornaram ao mapa com controles liberados.
- O anfitrião abortou a luta e voltou ao mapa após saída simulada do convidado, com 17 snapshots coincidentes.
- A regressão de Ryan na Route 2 venceu; na build final houve dano 20/41, 36 snapshots coincidentes e retorno ao mapa.
- Na build final, o teste `travel` venceu Brock com dano 152/171 e 34 snapshots iguais. O convidado voltou à zona `route_2`; o anfitrião trocou do ginásio para a Route 2 ainda conectado, com recriação do parceiro na nova cena. O teste `drop_guest` anterior abortou corretamente a luta após a queda simulada; a alteração posterior limitou o convite às zonas Route 2 e ginásio.

Ainda depende dos dois PCs do usuário: validar o Radmin VPN com `--inicio split`, a entrada manual pela conversa com Brock, os controles físicos/gamepad, e viagens normais pelas portas após a luta. Não se deve usar saves principais até validar o fluxo com cópias. A extensão Discord e o certificado do sistema podem registrar avisos no Godot headless de teste, sem `SCRIPT ERROR` da campanha.
