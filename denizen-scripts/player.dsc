#
# viaversion protocol numbers - https://wiki.vg/Protocol_version_numbers
# 498 = 1.14.4, 578 = 1.15.2
#
# 1.16.1 Issues
#   * Exiting a minecart is not cancellable at the moment. The player still exits but causes issues. The server still assumes the player is in the cart
#       https://hub.spigotmc.org/jira/browse/SPIGOT-5891
#       [Temp fix could be to tp the player to the destination if they try and exit the cart?]
#

player_handler:
    type: world
    debug: false
    events:
        on player joins:
        - define VERSION_RECOMMENDED 1.15.2
        - define VERSION_LESS_THAN_WARNING 498
        - define VERSION_GREATOR_THAN_WARNING 578

        - if <player.viaversion> < 498:
            - narrate format:msgerror "Your Minecraft client may experience issues on this server. Please upgrade to version <[VERSION_RECOMMENDED]><&nl>"
        - else if <player.viaversion> > 578:
            - narrate format:msgerror "Minecraft 1.16+ is not fully supported on this server and you may experience issues. We currently recommend version <[VERSION_RECOMMENDED]><&nl>"

        - webget http://play.qldminecraft.com.au/ 'data:{"cmd":"player_join","player":"<player.uuid>","viaversion":"<player.viaversion>"}' headers:<map.with[Content-Type].as[application/json]>
        - ~run player_yaml_load def:<player.uuid>
        - flag player playingStart:<util.time_now.epoch_millis>

        #after player joins:
        #    - if <yaml[<player.uuid>].read[npc_alan.tutorialdone]> != 1:
        #        - delay 3
        #        - narrate "<&6>Welcome to Ironport <player.name>"
        #        - narrate "<&6>---------------------------------"
        #        - delay 1
        #        - narrate ""
        #        - narrate "<&6>+ Since this is your first time here, go and visit Alan."
        #        - narrate "<&6>+ He is usually fishing at the end of the jetty."
        #        - narrate "<&e> You have <player.money> coins"

        on player quits:
        - webget http://play.qldminecraft.com.au/ 'data:{"cmd":"player_quit","player":"<player.uuid>"}' headers:<map.with[Content-Type].as[application/json]>
    
        - yaml id:<player.uuid> set playingTime:+:<util.time_now.epoch_millis.sub_int[<player.flag[playingStart]>]>
        - ~run player_yaml_unload def:<player.uuid>

        on player chats:
        - if <yaml[server].read[Flags.Chat]> != 1:
            - narrate format:msgerror "Chat is currently disabled for this server"
            - determine cancelled
        - else if <yaml[<player.uuid>].read[Flags.Chat]> != 1:
            - narrate format:msgerror "Chat is currently disabled for you"
            - determine cancelled
        - else:
            - define recipients ""
            - foreach <context.recipients>:
                - if <[value].uuid> != <player.uuid>:
                    - define recipients:|:<[value].uuid>
            
            - if <[recipients].size> > 0:
                - define recipients <[recipients].separated_by[|]>
            
            - webget http://play.qldminecraft.com.au/ data:{"cmd":"player_chat","player":"<player.uuid>","message":"<context.message>","recipients":"<[recipients]>"} headers:<map.with[Content-Type].as[application/json]>

    #on player enters notable cuboid:
    #- actionbar "Player entered <context.area>"

    #on player exits notable cuboid:
    #- actionbar "Player exited <context.area>"

    #on player enters ironport:
    #- actionbar "<&e>Entering Ironport"

    #on player enters ironport_rail_noentry_main:
    #- determine cancelled

    #on player exits ironport:
    #- actionbar "<&e>Exiting Ironport"

    #on player enters devilsmouth:
    #- actionbar "<&e>Entering Devils Mouth"

    #on player exits devilsmouth:
    #- actionbar "<&e>Exiting Devils Mouth"

    #on shutdown:
    #- foreach <server.list_online_players>:
    #  - yaml savefile:/PlayerData/<def[value].uuid>.yml id:<def[value].uuid>

    #on system time minuety every:10:
    #- narrate "Saved" target:<player[nomadjimbob]>
    #- foreach <server.list_online_players>:
    #  - yaml savefile:/PlayerData/<def[value].uuid>.yml id:<def[value].uuid>

player_yaml_load:
    type: task
    definitions: player_uuid
    script:
    - if <server.has_file[/serverdata/players/<[player_uuid]>.yml]>:
        - yaml load:/serverdata/players/<[player_uuid]>.yml id:<[player_uuid]>
        - inject locally player_yaml_defaults
        - yaml id:<player.uuid> set Logins:++
    - else:
        - yaml create id:<[player_uuid]>
        - inject locally player_yaml_defaults
        - yaml savefile:/serverdata/players/<[player_uuid]>.yml id:<[player_uuid]>

    player_yaml_defaults:
    - yaml id:<[player_uuid]> set Name:<player[<[player_uuid]>].name>
    - if !<yaml[server].contains[Logins]>:
        - yaml id:server set Logins:0
    - if !<yaml[server].contains[PlayingTime]>:
        - yaml id:server set PlayingTime:0
    - if !<yaml[server].contains[Flags.Chat]>:
        - yaml id:server set Flags.Chat:1

player_yaml_unload:
    type: task
    definitions: player_uuid
    script:
    - yaml savefile:/serverdata/players/<[player_uuid]>.yml id:<[player_uuid]>
    - yaml unload id:<[player_uuid]>
