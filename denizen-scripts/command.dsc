# File:     command.dsc
# Contains: Command Base Handler
# Package:  QLD Minecraft
# Build:    114
# URL:      http://play.qldminecraft.com.au/

command_handler:
    type: command
    debug: true
    name: qm
    description: Displays or sets areas
    usage: /qm [option]
    #tab complete:
        #- if <player.in_group[developer].not||<context.server>>||<player.has_flag[developer].not>:
        #    - stop
        #- determine <motd|npc|reload|teleport|version>
    script:
        - define command:<context.args.get[1]||null>
        - define action:<context.args.get[2]||null>
        - define item:<context.args.get[3]||null>
        - define val:<context.args.get[4]||null>

        - define "unknown_action:Unknown action for <[command]>"
        - define "no_permission:You do not have permission to use this command"
        - define "no_console:This command cannot be run from the console"

        - if <[command]> == null:
            - define command:version
        
        - choose <[command]>:
            - case dev develop developer:
                - if <context.server> || <yaml[<player.uuid>].read[developer]||0> != 0:
                    - choose <[action]>:
                        - case null toggle:
                            - if <context.server>:
                                - narrate format:notice "The console is always in developer mode"
                            - else:
                                - if <player.in_group[developer]>:
                                    - group remove developer
                                    - group add default
                                    - define mode:<yaml[server].read[regions.<player.flag[region].last>.mode]||survival>
                                    - adjust <player> gamemode:<[mode]>

                                    - narrate format:notice "You are no longer in developer mode"
                                - else:
                                    - group add developer
                                    - group remove default
                                    - narrate format:notice "You are now in developer mode"
                - else:
                    - narrate format:notice <[no_permission]>

            - case gamemode:
                - if <player.in_group[developer]>:
                    - if <[action]> == 'creative' || <[action]> == 'survival':
                        - adjust <player> gamemode:<[action]>
                        - narrate format:notice "Game mode changed"
                    - else:
                        - narrate format:notice "Unknown Game mode"
                - else:
                    - narrate format:notice <[no_permission]>

            - case motd:
                - choose <[action]>:
                    - case null get:
                        - define motd:<yaml[server].read[motd]||null>
                        - if <[motd]> != null:
                            - narrate format:notice "QLD Minecraft MOTD is currently:"
                            - narrate <&f><[value].parsed>
                        - else:
                            - narrate format:notice "QLD Minecraft MOTD has not been set"
                    - case set:
                        - if <player.in_group[developer]||<context.server>>:
                            - if <context.args.size> > 2:
                                - define motd:<context.args.remove[1|2].space_separated.escaped>
                                - narrate format:notice "QLD Minecraft MOTD was changed to:
                                - narrate <&f><[motd].parsed>
                                - yaml id:server set motd:<[motd]>
                            - else:
                                - narrate format:notice "No MOTD string was entered"
                        - else:
                            - narrate format:notice <[no_permission]>
                    - default:
                        - narrate format:notice <[unknown_action]>


            - case npc:
                - if <player.in_group[developer]||<context.server>>:
                    - choose <[action]>:
                        - case assign:
                            - if <context.server>:
                                - narrate format:notice "<[no_console]>"
                            - else:
                                - if <player.selected_npc||null> != null:
                                    - assignment set qm_npc_assignment
                                    - adjust <player.selected_npc> lookclose:true
                                    - narrate format:notice "NPC assignment set for <player.selected_npc.name>"
                                - else:
                                    - narrate format:notice "No NPC is selected"

                        - case unassign:
                            - if <context.server>:
                                - narrate format:notice "<[no_console]>"
                            - else:
                                - if <player.selected_npc> != null:
                                    - assignment remove
                                    - narrate format:notice "NPC assignment removed for <player.selected_npc.name>"
                                - else:
                                    - narrate format:notice "No NPC is selected"

                        - case select:
                            - define npcs:<player.location.find.npcs.within[10]>
                            - if <[npcs].size> > 0:
                                - adjust <player> selected_npc:<[npcs].first>
                                - narrate format:notice "NPC <[npcs].first.name> (<[npcs].first.id>) selected"
                            - else:
                                - narrate format:notice "No NPCs are within range"

                        - default:
                            - narrate format:notice <[unknown_action]>
                - else:
                    - narrate format:notice <[no_permission]>

            # Player
            - case player:
                - if <player.in_group[developer]||<context.server>>:
                    - if <[item]> != null:
                        - if <server.player_is_valid[<[item]>]>:
                            - define item:<server.match_offline_player[<[item]>]>
                        - else:
                            - define item:null

                    - choose <[action]>:

                        # developer
                        - case dev develop developer:
                            - if <[item]> == null:
                                - narrate format:notice "Player name is not valid"
                            - else:
                                - if <[val]> == null:
                                    - if <[item].flag[developer]||0> != 0:
                                        - narrate format:notice "Player is a developer"
                                    - else:
                                        - narrate format:notice "Player is not a developer"
                                - else if <[val].is_boolean>:
                                    - if <[val]> == true:
                                        - yaml id:<[item].uuid> set developer:1
                                        #- group add developer
                                        #- group remove default
                                        - narrate format:notice "Player was added to developer"
                                        - narrate format:notice "The player will need to reconnect for changes to take affect"
                                        #- narrate format:notice "You are in developer mode" target:<[item]>
                                    - else:
                                        - yaml id:<[item].uuid> set developer:0
                                        #- group remove developer
                                        #- group add default
                                        - narrate format:notice "Player was removed from developer"
                                        - narrate format:notice "The player will need to reconnect for changes to take affect"
                                        #- narrate format:notice "You are now in developer mode" target:<[item]>
                                - else:
                                    - narrate format:notice "The developer flag requires to be true or false"
                                    

                        - default:
                            - narrate format:notice <[unknown_action]>
                
                - else:
                    - narrate format:notice <[no_permission]>


            - case reload:
                - if <player.in_group[developer]||<context.server>>:
                    - reload
                    - ~run qm_server_yaml_load
                    - narrate format:notice "QLD Minecraft reloaded"
                - else:
                    - narrate format:notice <[no_permission]>


            - case region rg:
                - if <player.in_group[developer]||<context.server>>:
                    - choose <[action]>:
                        - case add create:
                            - if <context.server>:
                                - narrate format:notice "<[no_console]>"
                            - else:
                                - if <context.args.size> > 2:
                                    - define id:<context.args.get[3].escaped>
                                    - if <yaml[server].read[regions.<[id]>]||null> == null:
                                        - narrate format:notice "Region has been created: <&f><[id]>"
                                        - yaml id:server set regions.<[id]>.cuboid:<player.we_selection>
                                    - else:
                                        - narrate format:notice "Region id already exists"
                                - else:
                                    - narrate format:notice "No region id was entered"
                        - case update:
                            - if <context.server>:
                                - narrate format:notice "<[no_console]>"
                            - else:
                                - if <context.args.size> > 2:
                                    - define id:<context.args.get[3].escaped>
                                    - if <yaml[server].read[regions.<[id]>]||null> != null:
                                        - narrate format:notice "Region has been updated: <&f><[id]>"
                                        - yaml id:server set regions.<[id]>.cuboid:<player.we_selection>
                                    - else:
                                        - narrate format:notice "Region id doesn't exist"
                                - else:
                                    - narrate format:notice "No region id was entered"
                        - case del delete rem remove:
                            - if <context.args.size> > 2:
                                - define id:<context.args.get[3].escaped>
                                - if <yaml[server].read[regions.<[id]>]||null> != null:
                                    - narrate format:notice "Region was removed: <&f><[id]>"
                                    - yaml id:server set regions.<[id]>:!
                                - else:
                                    - narrate format:notice "Region id doesn't exist"
                            - else:
                                - narrate format:notice "No region id was entered"
                        - case get set:
                            - define region_id:<context.args.get[3].escaped||null>
                            - define flag:<context.args.get[4].escaped||null>
                            - define val:<context.args.remove[1|2|3|4].space_separated.escaped||null>

                            - if <[region_id]> != null:
                                - if <yaml[server].read[regions.<[region_id]>]||null> != null:
                                    - if <[action]> == get:
                                        - define val:<yaml[server].read[regions.<[region_id]>.<[flag]>]||null>

                                        - if <[val]> == null:
                                            - narrate format:notice "Region flag is not set"
                                        - else:
                                            - if <[flag]> == death_spawn:
                                                - playeffect effect:barrier at:<yaml[server].read[regions.<[item]>.death_spawn].outline> offset:0 target:<player>
                                            - else:
                                                - narrate format:notice "Region flag is: <&f><[val]>"
                                    - else:
                                        - if <[val]> == null:
                                            - yaml id:server set regions.<[region_id]>.<[flag]>:!
                                            - narrate format:notice "Region flag removed"
                                        - else:
                                            - if <[flag]> == death_spawn:
                                                - define val:<player.location>

                                            - yaml id:server set regions.<[region_id]>.<[flag]>:<[val]>
                                            - narrate format:notice "Region flag updated"
                                        
                                - else:
                                    - narrate format:notice "Region id doesn't exist"
                            - else:
                                - narrate format:notice "No region id was entered"
                        - case show:
                            - if <yaml[server].read[regions.<[item]>]||null> != null:
                                - playeffect effect:barrier at:<yaml[server].read[regions.<[item]>.cuboid].outline> offset:0 target:<player>
                            - else:
                                - narrate format:notice "Region doesn't exist"

                        - default:
                            - narrate format:notice <[unknown_action]>

                    - ~run qm_server_yaml_save
                    - ~run qm_server_sync_regions
                - else:
                    - narrate format:notice <[no_permission]>
            
            - case save:
                - if <player.in_group[developer]||<context.server>>:
                    - ~run qm_server_yaml_save
                    - foreach <server.online_players>:
                        - ~run qm_player_yaml_save def:<[value]>
                    - narrate format:notice "Server data saved"
                - else:
                    - narrate format:notice <[no_permission]>

            - case teleport tp:
                - if <player.in_group[developer]||<context.server>>:
                    - choose <[action]>:
                        - case list:
                            - narrate format:notice "Teleport locations: <yaml[server].list_keys[teleports].separated_by[, ]>"
                        - case loc location:
                            - teleport <location[<[item]>,island]> <player>
                        - case set:
                            - if <context.server>:
                                - narrate format:notice "<[no_console]>"
                            - else:
                                - if <context.args.size> > 2:
                                    - define name:<context.args.get[3].escaped>
                                    - if <yaml[server].read[teleports.<[name]>]||null> == null:
                                        - narrate format:notice "Teleport location has been set: <&f><[name]>"
                                        - yaml id:server set teleports.<[name]>:<player.location>
                                    - else:
                                        - narrate format:notice "This teleport location name already exists"
                                - else:
                                    - narrate format:notice "A teleport location name was not entered"
                        - case update:
                            - if <context.server>:
                                - narrate format:notice "<[no_console]>"
                            - else:
                                - if <context.args.size> > 2:
                                    - define name:<context.args.get[3].escaped>
                                    - if <[name]> != first_spawn:
                                        - if <yaml[server].read[teleports.<[name]>]||null> != null:
                                            - narrate format:notice "Teleport location has been updated: <&f><[name]>"
                                            - yaml id:server set teleports.<[name]>:<player.location>
                                        - else:
                                            - narrate format:notice "Teleport location does not exist"
                                    - else:
                                        - yaml id:server set first_spawn:<player.location>
                                - else:
                                    - narrate format:notice "A teleport location name was not entered"
                        - case del delete rem remove:
                            - if <context.args.size> > 2:
                                - define name:<context.args.get[3].escaped>
                                - if <[name]> != first_spawn:
                                    - if <yaml[server].read[teleports.<[name]>]||null> != null:
                                        - narrate format:notice "Teleport location has been removed: <&f><[name]>"
                                        - yaml id:server set teleports.<[name]>:!
                                    - else:
                                        - narrate format:notice "Teleport location does not exist"
                                - else:
                                    - narrate format:notice "You cannot delete the location first_spawn"
                            - else:
                                - narrate format:notice "A teleport location name was not entered"
                        - default:
                            - define loc:<yaml[server].read[teleports.<[action]>]||null>
                            - if <[loc]> != null:
                                - teleport <[loc]> <player>
                            - else:
                                - if <server.player_is_valid[action]> && <server.online_players.contains[action]>:
                                    - if <context.args.size> > 2:
                                        - define target:<context.args.get[3].escaped>
                                        - if <server.player_is_valid[target]> && <server.online_players.contains[target]>:
                                            - teleport <server.match_offline_player[action].location> <server.match_offline_player[target]>
                                        - else:
                                            - narrate format:notice "Player <[target]> was not found"
                                    - else:
                                        - if <context.server>:
                                            - narrate format:notice "<[no_console]>"
                                        - else:
                                            - teleport <server.match_offline_player[action].location> <player>
                                - else:
                                    - narrate format:notice "Player <[action]> was not found"
                - else:
                    - narrate format:notice <[no_permission]>

            - case info:
                - if <player.in_group[developer]||<context.server>>:
                    - narrate ""
                    - narrate "<&e>----- Server Information -----"
                    - narrate "<&6>Online players: <&a><server.online_players.size> <&6>/ <&a><server.max_players>"
                    - narrate "<&6>Disk free space: <&a><server.disk_free.div[1073741824].round_to[2]> GB"
                    - narrate "<&6>Memory: <&a><server.ram_usage.div[1073741824].round_to[2]> GB <&6>(<&a><server.ram_free.div[1073741824].round_to[2]> GB <&6>free)"
                    - narrate "<&6>Script count: <&a><server.scripts.size>"
                    - narrate "<&6>NPC count: <&a><server.npcs.size>"
                    - narrate "<&6>Region count: <&a><server.notables.size>"
                    - execute as_op tps
                - else:
                    - narrate format:notice <[no_permission]>

            - case version:
                - choose <[action]>:
                    - case null get:
                        - narrate format:notice "QLD Minecraft <yaml[server].read[version]||unknown> (build 114)"
                    - case set:
                        - if <context.args.size> > 2:
                            - if <player.in_group[developer]||<context.server>>:
                                - define version:<context.args.remove[1|2].space_separated.escaped>
                                - narrate format:notice "QLD Minecraft version changed to: <&f><[version]>"
                                - yaml id:server set version:<[version]>
                            - else:
                                - narrate format:notice <[no_permission]>
                        - else:
                            - narrate format:notice "No version string was entered"
                    - default:
                        - narrate format:notice <[unknown_action]>

            - default:
                - narrate format:notice "Unknown QLD Minecraft command"


# Send bug report
qm_command_bug:
    type: command
    name: bug
    description: Reports a bug
    usage: /bug <&lt>Description<&gt>
    script:
    - if <context.args.size> > 0:
        - ~webget https://play.qldminecraft.com.au/bridge.php data:{"cmd":"bug","player":"<player.uuid>","name":"<player.name>","location":"<player.location>","viaversion":"<player.viaversion>","description":"<context.args.space_separated>"} headers:<map.with[Content-Type].as[application/json]> save:request
        - if <entry[request].status> == 200 && <entry[request].result.starts_with[ok]>:
            - narrate format:notice "Your bug as been reported"
        - else:
            - narrate format:notice "There was a problem reporting the bug. Please email james.collins@slq.qld.gov.au or use Discord https://discord.gg/hENeBQb"
        
    - else:
        - narrate format:notice "You need to enter a description of the issue"
