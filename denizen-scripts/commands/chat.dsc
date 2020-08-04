# /chat                                 - returns if chat is enabled server wide
# /chat <player.name>                   - returns if chat is enabled for a player wide
# /chat enable|disable <player.name>    - enabled/disables chat server wide unless a player name is specified
command_chat:
    type: command
    debug: false
    name: chat
    description: Gets or sets chat settings
    usage: /chat [enabled|disabled] [player]
    aliases:
    - chat
    script:
    - if <player.is_op||<context.server>>:
        - choose <context.args.size>:
            - case 1:
                - define command <context.args.get[1].escaped>
                - choose <[command]>:
                    - case enable enabled:
                        - yaml id:server set Flags.Chat:1
                        - narrate format:msgchat "Server chat is now enabled"
                        - ~run server_yaml_save
                    - case disable disabled:
                        - yaml id:server set Flags.Chat:0
                        - narrate format:msgchat "Server chat is now disabled"
                        - ~run server_yaml_save
                    - default:
                        - if <server.player_is_valid[<[command]>]>:
                            - define player_uuid <server.match_offline_player[<[command]>].uuid>
                            - define unload_yaml 0
                            
                            - if !<yaml.list.contains[<[player_uuid]>]>:
                                - define unload_yaml 1
                                - ~run player_yaml_load def:<[player_uuid]>
                            - if <yaml[<[player_uuid]>].read[Flags.Chat]> != 1:
                                - narrate format:msgchat "Chat is disabled for <player[<[player_uuid]>].name>"
                            - else:
                                - narrate format:msgchat "Chat is enabled for <player[<[player_uuid]>].name>"
                            
                            - if <[unload_yaml]> = 1:
                                - ~run player_yaml_unload def:<[player_uuid]>
                        - else:
                            - narrate format:msgerror "Player '<[command]>' was not found"
            - case 2:
                - define playername <context.args.get[1].escaped>
                - define command <context.args.get[2].escaped>
                - if <server.player_is_valid[<[playername]>]>:
                    - if <[command]> = enable || <[command]> = enabled || <[command]> = disable || <[command]> = disabled:
                        - define player_uuid <server.match_offline_player[<[playername]>].uuid>
                        - define unload_yaml 0
                        
                        - if !<yaml.list.contains[<[player_uuid]>]>:
                            - define unload_yaml 1
                            - ~run player_yaml_load def:<[player_uuid]>
                        - if <[command]> = enable || <[command]> = enabled:
                            - yaml id:<[player_uuid]> set Flags.Chat:1
                            - narrate format:msgchat "Chat is now enabled for <player[<[player_uuid]>].name>"
                        - else:
                            - yaml id:<[player_uuid]> set Flags.Chat:0
                            - narrate format:msgchat "Chat is now disabled for <player[<[player_uuid]>].name>"
                        
                        - if <[unload_yaml]> = 1:
                            - ~run player_yaml_unload def:<[player_uuid]>
                    - else:
                        - narrate format:msgerror "You used the command incorrectly. Try /chat [player] <&lt>enable|disable<&gt>"
                - else:
                    - narrate format:msgerror "Player '<[playername]>' was not found"
            - default:
                - if <context.args.size> > 1:
                    - narrate format:msgerror "You used the command incorrectly. Try /chat [player] <&lt>enable|disable<&gt>"
                - else:
                    - if <yaml[server].read[Flags.Chat]> != 1:
                        - narrate format:msgchat "Server chat is disabled"
                    - else:
                        - narrate format:msgchat "Server chat is enabled"
    - else:
        - narrate format:msgerror "You do not have access to this command"
