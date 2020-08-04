# /gold                                 - returns the amount of gold you have
# /gold <player.name>                   - returns the amount of gold a player has (OP Only)
# /gold give <amount> <player.name>     - gives the amount of gold to a player
# /gold set <amount> <player.name>      - sets the amount of gold for a player (OP Only)
command_gold:
    type: command
    debug: false
    name: gold
    description: Displays the amount of gold coins you have
    usage: /gold
    aliases:
    - money
    - coin
    - coins
    - goldcoin
    - goldcoins
    script:
    - choose <context.args.size>:
        - case 1:
            - if <player.is_op||<context.server>>:
                - if <server.player_is_valid[<context.args.get[1].escaped>]>:
                    - define player_uuid <server.match_offline_player[<context.args.get[1].escaped>]>
                    #- if <player[<[player_uuid]>].is_whitelisted> = true:
                    - narrate format:msgchat "Player '<player[<[player_uuid]>].name>' has <player[<[player_uuid]>].money> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>"
                    #- else:
                    #    - narrate format:msgerror "Player '<context.args.get[1]>' is not whitelisted"
                - else:
                    - narrate format:msgerror "Player '<context.args.get[1]>' was not found"
            - else:
                - inject locally gold_display_me
        - case 3:
            - define command <context.args.get[1].escaped>
            - if <[command]> = give || <[command]> = send:
                - if <server.player_is_valid[<context.args.get[3].escaped>]>:
                    - define player_uuid <server.match_offline_player[<context.args.get[3].escaped>]>
                    - if <context.args.get[2].escaped.is_integer>:
                        - define amount <context.args.get[2].escaped>
                        - if <player.is_op||<context.server>>:
                            - money give quantity:<[amount]> player:<player[<[player_uuid]>]>
                            - narrate format:msgchat "<player[<[player_uuid]>].name> has received <[amount]> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>"
                            - narrate format:msgchat "<player[<[player_uuid]>].name> now has <player[<[player_uuid]>].money> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>"
                            - narrate format:msgchat "You received <[amount]> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]> from the server" target:<player[<[player_uuid]>]>
                            - narrate format:msgchat "You now have <player[<[player_uuid]>].money> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>" target:<player[<[player_uuid]>]>
                        - else:
                            - if <player[<[player_uuid]>].is_whitelisted> = true:
                                - if <amount> > <player.money>:
                                    - narrate format:msgchat "You cannot give <[amount]> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>. You only have <player.money> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>"
                                - else:
                                    - money give quantity:<[amount]> player:<player[<[player_uuid]>]>
                                    - money take quantity:<[amount]>
                                    - narrate format:msgchat "<player[<[player_uuid]>].name> has received <[amount]> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>"
                                    - narrate format:msgchat "You now have <player.money> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>"
                                    - narrate format:msgchat "You received <[amount]> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]> from <player.name>" target:<player[<[player_uuid]>]>
                                    - narrate format:msgchat "You now have <player[<[player_uuid]>].money> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>" target:<player[<[player_uuid]>]>
                            - else:
                                - narrate format:msgerror "You cannot give gold coin to '<player[<[player_uuid]>].name>' at the moment"
                    - else:
                        - narrate format:msgerror "An amount was not specified. Try /gold give <&lt>amount<&gt> <&lt>player<&gt>"
                - else:
                    - narrate format:msgerror "Player '<context.args.get[1]>' was not found"
            - else if <[command]> = set:
                - if <player.is_op||<context.server>>:
                    - if <server.player_is_valid[<context.args.get[3].escaped>]>:
                        - define player_uuid <server.match_offline_player[<context.args.get[3].escaped>]>
                        - if <context.args.get[2].escaped.is_integer>:
                            - define amount <context.args.get[2].escaped>
                            - money take quantity:<player[<[player_uuid]>].money> player:<player[<[player_uuid]>]>
                            - money give quantity:<[amount]> player:<player[<[player_uuid]>]>
                            - narrate format:msgchat "<player[<[player_uuid]>].name> now has <[amount]> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>"
                            - narrate format:msgchat "You now have <player[<[player_uuid]>].money> gold coin<tern[<player[<[player_uuid]>].money.as_boolean>].pass[].fail[s]>" target:<player[<[player_uuid]>]>
                        - else:
                            - narrate format:msgerror "An amount was not specified. Try /gold set <&lt>amount&lt <&lt>player<&gt>"
                    - else:
                        - narrate format:msgerror "Player '<context.args.get[1]>' was not found"
                - else:
                    - narrate format:msgerror "An unknown action was specified. Try /gold give <&lt>amount<&gt> <&lt>player<&gt>"
            - else:
                - narrate format:msgerror "An unknown action was specified. Try /gold give <&lt>amount<&gt> <&lt>player<&gt>"
        - default:
            - inject locally gold_display_me

    gold_display_me:
    - if <context.server>:
        - if <context.args.size> = 0:
            - narrate format:msgerror "You need to specify a player"
        - else if <context.args.size> = 2:
            - narrate format:msgerror "An unknown action was specified. Try /gold give <&lt>amount<&gt> <&lt>player<&gt>"
        - else:
            - narrate format:msgerror "Command could not be parsed. Try /gold give <&lt>amount<&gt> <&lt>player<&gt>"
    - else:
        - narrate format:msgchat "You have <player.money> gold coin<tern[<player.money.as_boolean>].pass[].fail[s]>"
