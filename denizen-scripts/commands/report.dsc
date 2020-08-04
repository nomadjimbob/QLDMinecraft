# /report <player.name> <message>       - reports a player to op
command_report:
    type: command
    debug: true
    name: report
    description: Reports a player to OP
    usage: /report player message
    aliases:
    - report
    script:
    - if <context.args.size> >= 2:
        - if <server.player_is_valid[<context.args.get[1].escaped>]>:
            - define player_uuid <server.match_offline_player[<context.args.get[1].escaped>]>
            - narrate format:msgchat "'<player[<[player_uuid]>].name>' has been reported to an OP"
            - define reporter console
            - if !<context.server>:
                - define reporter <player.uuid>
            - webget http://admin.qldminecraft.com.au/ data:{"cmd":"player_report","player":"<[reporter]>","against":"<player[<[player_uuid]>]>","report":"<context.args.remove[1].space_separated.escaped>"} headers:<map.with[Content-Type].as[application/json]>
    - else:
        - narrate format:msgerror "You used the command incorrectly. Try /report <&lt>player<&gt> <&lt>message<&gt>"
