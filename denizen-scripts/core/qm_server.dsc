qmw_server:
    type: world
    debug: true
    events:
        on server start:
            - narrate 'QLD Minecraft starting...' targets:<server.online_players>
            - ~run qm_server.yaml.load
            - foreach <yaml[server].read[start_commands]||<list[]>>:
                - execute as_server <[value]>
            
            - if <server.sql_connections.contains[mysql]||false> == false:
                - ~sql id:mysql connect:localhost:3306/qldminecraft username:qm password:XXHIDDENXX
            
        
        after server start:
            - event 'pre load'
            - waituntil <queue.list.size> <= 1
            - event load


        after player joins:
            - run qm_server.motd

            - if <yaml[server].read[maintenance]||0> != 0:
                - if !<proc[qmp_player.is_developer].context[<player>]>:
                    - kick <player> reason:<proc[qmp_lang].context[<player||null>|maintenance_current|server]>
                    - determine cancelled
                    - stop
                - else:
                    - narrate <proc[qmp_lang].context[<player||null>|maintenance_enabled|server]>
            
            - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<player.money>]>
            - if <server.sql_connections.contains[mysql]||false> == false:
                - ~sql id:mysql connect:localhost:3306/qldminecraft username:qm password:XXHIDDENXX
            - ~sql id:mysql 'update:INSERT into login(datetime,uuid,action) VALUES("<util.time_now.epoch_millis>","<player.uuid>","0");'
            - ~sql id:mysql 'update:INSERT into username(uuid,username) VALUES("<player.uuid>","<player.name.sql_escaped>");'

        on player joins:
            - if <player.is_op>:
                - adjust <player> is_op:false
            - group remove developer
            - group add default
        
        on player quits:
            - sql id:mysql 'update:INSERT into login(datetime,uuid,action) VALUES("<util.time_now.epoch_millis>","<player.uuid>","1");'
            - if <player.is_op>:
                - adjust <player> is_op:false
            - group remove developer
            - group add default



        on pre script reload priority:-100:
            - narrate <proc[qmp_language].context[server_reloading|server]>
            - run qm_server.yaml.load


        on script reload:
            - foreach <yaml[server].read[reload_commands]||<list[]>>:
                - execute as_server <[value]>
            - waituntil <queue.list.size> <= 1
            - event 'pre load'
            - waituntil <queue.list.size> <= 1
            - event load
            - waituntil <queue.list.size> <= 1
            - narrate <proc[qmp_language].context[server_reloaded|server]>


        on system time minutely every:5:
            - run qm_server.yaml.save
            - event save


        on load:
            - run qm_language.set.placeholder def:build|<proc[qmp_server.build]>

            - run qm_command.add.command def:qm_server_cmd|build
            - run qm_command.add.command def:qm_server_cmd|demote|developer
            - run qm_command.add.command def:qm_server_cmd|dev
            - run qm_command.add.command def:qm_server_cmd|info|developer
            - run qm_command.add.command def:qm_server_cmd|maintenance|developer
            - run qm_command.add.command def:qm_server_cmd|promote|developer
            - run qm_command.add.command def:qm_server_cmd|save|developer
            - run qm_command.add.command def:qm_server_cmd|startcmd|developer
            - run qm_command.add.command def:qm_server_cmd|reload|developer
            
            
            - run qm_command.add.command def:qm_server_cmd|promote|developer
            - run qm_command.add.tabcomplete def:promote|_*players
            
            - run qm_command.add.command def:qm_server_cmd|demote|developer
            - run qm_command.add.tabcomplete def:demote|_*players
            
            - run qm_command.add.command def:qm_server_cmd|motd|developer
            - run qm_command.add.tabcomplete def:motd|get
            - run qm_command.add.tabcomplete def:motd|set|_*number

            - run qm_command.add.command def:qm_server_cmd|text|developer
            - run qm_command.add.tabcomplete def:text|placeholder|_*textplaceholders
            - run qm_command.add.tabcomplete def:text|placeholder|_*textplaceholders|set
            - run qm_command.add.tabcomplete def:text|placeholder|_*textplaceholders|remove


        on save:
            - run qm_server.yaml.save


qm_server:
    type: task
    debug: false
    script:
        - narrate ''
    
    motd:
        - foreach <yaml[server].read[motd]||<list[]>>:
            - narrate <proc[qmp_language].context[<[value]>]>
    
    yaml:
        load:
            - if <server.has_file[/serverdata/server.yml]>:
                - yaml load:/serverdata/server.yml id:server
            - else:
                - yaml create id:server
                - yaml savefile:/serverdata/server.yml id:server
        
        save:
            - yaml savefile:/serverdata/server.yml id:server
        

        merge:
            - define yaml_id:<[1]||null>
            - define file_path:<[2]||null>

            - if <[yaml_id]> != null && <[file_path]> != null && <server.has_file[<[file_path]>]>:
                - define random_id:<util.random.duuid>
                - ~yaml load:<[file_path]> id:<[random_id]>
                - foreach <yaml[<[random_id]>].list_deep_keys[]||<list[]>>:
                    - yaml id:<[yaml_id]> set <[value]>:<yaml[<[random_id]>].read[<[value]>]>
                - yaml unload id:<[random_id]>
    
    player:
        demote:
            - define target_player:<[1]>
            - if <[1].is_player>:
                # - execute as_server 'lp user <[target_player].name> parent set default'
                - yaml id:server set developers:<-:<[target_player].uuid>
                # - event 'player update' context:player:<[target_player]>

        promote:
            - define target_player:<[1]>
            - if <[1].is_player>:
                - if !<yaml[server].read[developers].contains[<[target_player].uuid>]>:
                    - yaml id:server set developers:->:<[target_player].uuid>
                    # - event 'player update' context:player:<[target_player]>
                    
                    


qmp_server:
    type: procedure
    debug: false
    version: 260
    script:
        - determine null


    build:
        - determine <script[qmp_server].data_key[version]||-1>

    
    format:
        # followin gfunxtuin still needed?
        text:
            - define text:<[1]||<element[]>>
            - foreach <yaml[server].list_keys[text-placeholders]||<list[]>>:
                - define text:<[text].replace_language[$<[value]>$].with[<yaml[server].read[text-placeholders.<[value]>]>]>
            - determine <[text]>
        
        money:
            - define money:<[1]||0>
            - define text:<element[]>
            - define gold:<[money].div[10000].round_down>
            - define silver:<[money].mod[10000].div[100].round_down>
            - define copper:<[money].mod[100].round_down>

            - define show_gold:false
            - define show_silver:false
            - define show_copper:false

            - if <[gold]> > 0:
                - define show_gold:true
            - if <[silver]> > 0:
                - define show_silver:true
            - if <[copper]> > 0:
                - define show_copper:true

            - if <[show_copper]> && <[show_gold]>:
                - define show_silver:true


            - if <[show_gold]>:
                - define 'text:<[text]><&e><&chr[2B24]><&f><[gold]> '
            - if <[show_silver]>:
                - if <[show_gold]> && <[silver]> < 10:
                    - define silver:0<[silver]>
                - define 'text:<[text]><&7><&chr[2B24]><&f><[silver]> '
            - if <[show_copper]>:
                - if <[show_silver]> && <[copper]> < 10:
                    - define copper:0<[copper]>
                - define 'text:<[text]><&6><&chr[2B24]><&f><[copper]> '


            # - if <[gold]> > 0:
            #     - define 'text:<[text]><&e><&chr[2B24]><&f><[gold]> '

            # - if <[silver]> > 0:

            #     - if <[gold]> > 0 && <[silver]> < 10:
            #         - define silver:0<[silver]>

            #     - define 'text:<[text]><&7><&chr[2B24]><&f><[silver]> '

            # - if <[copper]> > 0 || <[text].length> == 0:

            #     - define 'text:<[text]><&6><&chr[2B24]><&f><[copper]> '

            - determine <[text].trim>
    
    player:
        is_developer:
            - if <[1].is_player||false>:
                - determine <yaml[server].read[developers].contains[<[1].uuid>]||false>
            - if <[1]||<empty>> == null:
                - determine true
            
            - determine false

        in_developer_mode:
            - if <[1].is_player||false>:
                - determine <[1].in_group[developer]>

            - determine false
    
    find:
        player:
            - define search:<[1]||<empty>>
            - if <[search].is_player||false>:
                - determine <[search]>
            - foreach <server.players>:
                - if <[value].uuid||<element[]>> == <[search]>:
                    - determine <[value]>
                - if <[value].name||<element[]>> == <[search]>:
                    - determine <[value]>

            - determine <empty>

        npc:
            - define search:<[1]||<empty>>
            - if <[search].is_npc||false>:
                - determine <[search]>
            - foreach <server.npcs>:
                - if <[value].id||<element[]>> == <[search]>:
                    - determine <[value]>
                - if <[value].name||<element[]>> == <[search]>:
                    - determine <[value]>

            - determine <empty>


qm_debug:
    type: task
    script:
        - if <proc[qmp_server.player.in_developer_mode].context[<[1]>]||false>:
            - narrate $COLOR-DEBUG$<[2]||<empty>>

qm_server_cmd:
    type: task
    debug: false
    script:
        - choose <[1].get[command]>:
            
            # build
            - case build:
                - narrate 'QLD Minecraft build: <proc[qmp_server.build]>'

            # demote
            - case demote:
                - if <[1].get[option]||null> != null:
                    - define player_name:<[1].get[option]||null>
                    - if <server.player_is_valid[<[player_name]>]>:
                        - define target_player:<player[<[player_name]>]>

                        - run qm_server.player.demote def:<[target_player]>
                        - narrate <proc[qmp_language].context[<player||null>|player_demoted|common|<map[player/<[player_name].escaped>]>]>
                    - else:
                        - narrate <proc[qmp_language].context[<player||null>|player_not_found|common|<map[player/<[player_name].escaped>]>]>
                - else:
                    - narrate '<proc[qmp_server.format.text].context[$COLOR_SERVER$/qm demote <&lt>player<&gt>]>'


            # dev
            - case dev:
                - if <proc[qmp_server.player.is_developer].context[<[1].get[player]>]>:
                    - if <proc[qmp_server.player.in_developer_mode].context[<[1].get[player]>]>:
                        - execute as_server 'lp user <[1].get[player].name> parent set default'
                        - narrate <proc[qmp_language].context[dev_disabled|server]>
                    - else:
                        - execute as_server 'lp user <[1].get[player].name> parent set developer'
                        - narrate <proc[qmp_language].context[dev_enabled|server]>
                - else:
                    - narrate <proc[qmp_language].context[command_not_permitted|server]>

            # - case dev:
            #     - if <proc[qmp_server.player.is_developer].context[<[1].get[player]||null>]||false>:


            #         - choose <[1].get[option]||null>:
            #             - case null:
            #                 - if <[1].is_player||false>:
            #                     - narrate isPlayer
            #                 - else:
            #                     - narrate notPlayer
            #             - case get:
            #                 - narrate get
            #             - case toggle:
            #                 - if <proc[qmp_server.player.is_developer].context[<[1].get[player]||null>]||false>:
            #                     - if <[1].is_player||false>:
            #                         - if <proc[qmp_server.player.in_developer_mode].context[<[1].get[player]||null>]||false>:
            #                             - run qm_server.player.developer_mode.enable def:<[1].get[player]||null>
            #                             - narrate <proc[qmp_lang].context[<player||null>|dev_mode_enabled|server]>
            #                         - else:
            #                             - run qm_server.player.developer_mode.disable def:<[1].get[player]||null>
            #                             - narrate <proc[qmp_lang].context[<player||null>|dev_mode_disabled|server]>
            #                     - else:
            #                         - narrate <proc[qmp_lang].context[<player||null>|cmd_run_player_only|server]>
            #                 - else:
            #                     - narrate <proc[qmp_lang].context[<player||null>|cmd_not_permmitted|server]>
            #             - case on:
            #                 - narrate on
            #             - case off:
            #                 - narrate off
            #             - case list:
            #                 - narrate '<yaml[server].read[developers].separated_by[, ]>'
            #             - default:
            #                 - narrate <[1].get[option]>
            #         # - narrate <proc[qmp_server.player.is_developer].context[<[1].get[player]>]>
            #         # - define toggle:<[1].get[option]||null>
            #     - else:
            #         - narrate <proc[qmp_lang].context[<player||null>|cmd_not_permitted|server]>
                

            # info
            - case info:
                - narrate ''
                - narrate '<&e>----- Server Information -----'
                - narrate '<&6>Online players: <&a><server.online_players.size> <&6>/ <&a><server.max_players>'
                - narrate '<&6>Disk free space: <&a><server.disk_free.div[1073741824].round_to[2]> GB'
                - narrate '<&6>Memory: <&a><server.ram_usage.div[1073741824].round_to[2]> GB <&6>(<&a><server.ram_free.div[1073741824].round_to[2]> GB <&6>free)'
                - narrate '<&6>Script count: <&a><server.scripts.size>'
                - narrate '<&6>NPC count: <&a><server.npcs.size>'
                - narrate '<&6>Mob count: <&a><world[island].living_entities.size.sub[<server.npcs.size>].sub[<server.online_players.size>]>'
                - narrate '<&6>Region count: <&a><server.notables.size>'
                - define tps:<list[]>
                - foreach <server.recent_tps>:
                    - define rounded:<[value].round_to[1]>
                    
                    - if <[rounded]> < 15:
                        - define tps:|:<&c><[rounded]>
                    - else if <[rounded]> < 18:
                        - define tps:|:<&e><[rounded]>
                    - else:
                        - define tps:|:<&a><[rounded]>
                - narrate '<&6>Last TPS: <[tps].space_separated>'
            
            # maintenance
            - case maintenance:
                - choose <[option]>:
                    - case null get list:
                        - if <yaml[server].read[maintenance]||0> == 0:
                            - narrate <proc[qmp_lang].context[<player||null>|maintenance_disabled|server]>
                        - else:
                            - narrate <proc[qmp_lang].context[<player||null>|maintenance_enabled|server]>
                    - case enable enabled true:
                        - yaml id:server set maintenance:1
                        - run qm_server.yaml.save
                        - narrate <proc[qmp_lang].context[<player||null>|maintenance_enabled|server]>
                    - case disable disabled false:
                        - yaml id:server set maintenance:!
                        - run qm_server.yaml.save
                        - narrate <proc[qmp_lang].context[<player||null>|maintenance_disabled|server]>

            # motd
            - case motd:
                - choose <[1].get[option]>:
                    - case get null:
                        - define index:<[1].get[args].get[1]||null>
                        - if <[index]> != null:
                            - define line:<yaml[server].read[motd]||<list[]>>
                            - if <[line].get[<[index]>]||null> != null:
                                - narrate '<&3><[index]> - <&f><[line].get[<[index]>]>'
                            - else:
                                - narrate line_not_exist
                        - else:
                            - foreach <yaml[server].read[motd]||<list[]>>:
                                - narrate '<&3><[loop_index]> - <&f><proc[qmp_language].context[<[value]>]>'
                    - case set:
                        - define index:<[1].get[args].get[2]||null>
                        - if <[index].is_integer>:
                            - define motd:<yaml[server].read[motd]||<list[]>>
                            # - define motd:<[motd].set>
                        - else:
                            - <proc[qmp_lang].context[<player||null>|motd_set_line_invalid|server]>
                    - default:
                        - narrate <proc[qmp_lang].context[<player||null>|command_invalid|command]>
                        

            # promote
            - case promote:
                - if <[1].get[option]||null> != null:
                    - define player_name:<[1].get[option]||null>
                    - if <server.player_is_valid[<[player_name]>]>:
                        - define target_player:<player[<[player_name]>]>

                        - run qm_server.player.promote def:<[target_player]>
                        - narrate <proc[qmp_language].context[player_promoted|server|<map[player/<[player_name].escaped>]>]>
                        - narrate <proc[qmp_language].context[you_promoted|server]> target:<[target_player]>
                    - else:
                        - narrate <proc[qmp_lang].context[<player||null>|player_not_found|common|<map[player/<[player_name].escaped>]>]>
                - else:
                    - narrate '<proc[qmp_server.format.text].context[$COLOR_SERVER$/qm promote <&lt>player<&gt>]>'


            # save
            - case save:
                - event save
                - narrate <proc[qmp_language].context[server_saved|server]>

            # startcmd
            - case startcmd startcmds:
                - choose <[option]>:
                    - case null list:
                        - narrate <proc[qmp_lang].context[<player||null>|start_cmds|server]>
                        - if <yaml[server].read[start_commands].size> > 0:
                            - foreach <yaml[server].read[start_commands]>:
                                - narrate '<proc[qmp_lang_raw].context[$COLOR_SERVER$<[loop_index]> - $COLOR_VALUE$<[value]>]>'
                        - else:
                            - narrate <proc[qmp_lang].context[<player||null>|start_cmds_none|server]>
            
            #reload
            - case reload:
                - reload
            

            # text
            - case text:
                - choose <[1].get[option]||null>:
                    - case placeholder:
                        - define target_placeholder:<[1].get[args].get[1]||null>
                        - if <[target_placeholder]> != null:
                            - if <[target_placeholder]> == list:
                                - define list:<yaml[server].list_keys[text-placeholder]||<list[]>>
                                - if <[list].size> > 0:
                                    - narrate '<[list].separated_by[, ]>'
                                - else:
                                    - narrate <proc[qmp_lang].context[<player||null>|placeholder_empty_list|server]>
                            - else:
                                - choose <[1].get[args].get[2]||null>:
                                    - case null:
                                        - narrate <proc[qmp_lang].context[<player||null>|placeholder_get|server|<map[placeholder/<[target_placeholder]>|value/<yaml[server].read[text-placeholder.<[target_placeholder]>]||null>].escaped>]>
                                    - case set:
                                        - define value:<[1].get[args].get[3]||<empty>>
                                        - if <[value]> != <empty>:
                                            - yaml id:server set text-placeholder.<[target_placeholder]>:<[value]>
                                            - narrate <proc[qmp_lang].context[<player||null>|placeholder_set|server|<map[placeholder/<[target_placeholder]>|value/<[value]>].escaped>]>
                                        - else:
                                            - narrate <proc[qmp_lang].context[<player||null>|placeholder_no_set_value|server|<map[placeholder/<[target_placeholder]>].escaped>]>
                                    - case rem remove del delete:
                                        - yaml id:server set text-placeholder.<[target_placeholder]>:!
                                        - narrate <proc[qmp_lang].context[<player||null>|placeholder_removed|server|<map[placeholder/<[target_placeholder].escaped>]>]>
                        - else:
                            - narrate <proc[qmp_lang].context[<player||null>|placeholder_not_entered|server]>
                    - default:
                        - narrate <proc[qmp_lang].context[<player||null>|command_invalid|command]>


qmp_command_tabcomplete_languageplaceholders:
    type: procedure
    debug: false
    script:
        - determine <yaml[server].list_keys[text-placeholders]||<list[]>>




qmc_money:
    type: command
    debug: false
    name: money
    description: Displays the amount of money you have
    usage: /money
    script:
        - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<player.money>]>


qmc_motd:
    type: command
    debug: false
    name: motd
    description: Displays the server MOTD
    usage: /motd
    script:
        - run qm_server.motd

qmc_stuck:
    type: command
    debug: false
    name: stuck
    description: Teleports you back home
    usage: /stuck
    tab complete:
        - if <proc[qmp_player.is_moderator].context[<player>]>:
            - define players:<list[]>
            - foreach <server.online_players>:
                - define players:->:<[value].name>
            - determine <[players]>
    script:
        - if <proc[qmp_player.is_moderator].context[<player>]>:
            - if <context.args.size> > 0:
                - if <server.player_is_valid[<context.args.get[1]>]>:
                    - define target_player:<player[<context.args.get[1]>]>
                    - teleport <yaml[server].read[first_join.tp]> <[target_player]>
                    - narrate '[SERVER]: <&f><[target_player].name> <&e>has been teleported back to the pirate ship'
                    - narrate '[SERVER]: <&e>You has been teleported back to the pirate ship' target:<[target_player]>
                - else:
                    - narrate '[SERVER]: <&f><context.args.get[1]> <&e>is not a valid player name'
            - else:
                - teleport <yaml[server].read[first_join.tp]> <player>
                - narrate '[SERVER]: <&e>You have been teleported back to the pirate ship'
        - else:
            - if <player.money> < 10000:
                - take money quantity:<player.money>
            - else:
                - take money quantity:10000

            - teleport <yaml[server].read[first_join.tp]> <player>
            - narrate '[SERVER]: <&e>You have been teleported back to the pirate ship'
            - narrate '[SERVER]: <&e>Up to <proc[qmp_server.format.money].context[10000]> has been taken from you'
            - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<player.money>]>

qmc_warn:
    type: command
    debug: false
    name: warn
    description: Records a player warning
    usage: /warn
    tab complete:
        - if <proc[qmp_player.is_moderator].context[<player>]>:
            - if <context.args.size> < 1:
                - define players:<list[]>
                - foreach <server.online_players>:
                    - define players:->:<[value].name>
                - determine <[players]>
    script:
        - if <proc[qmp_player.is_moderator].context[<player>]>:
            - if <context.args.size> > 0:
                - if <server.player_is_valid[<context.args.get[1]>]>:
                    - define target_player:<player[<context.args.get[1]>]>
                    - define reason:<context.args.remove[1].space_separated>
                    - define highest:<yaml[<[target_player].uuid>].list_keys[warnings].highest.add[1]||1>

                    - yaml id:<[target_player].uuid> set warnings.<[highest]>.time:<util.time_now.epoch_millis>
                    - yaml id:<[target_player].uuid> set warnings.<[highest]>.reason:<[reason]>

                    - narrate '[SERVER]: <&e>A warning has been recorded against <&f><[target_player].name>'
                    
                    - narrate '' target:<[target_player]>
                    - narrate '<&f><[target_player].name> <&5>A warning has been recorded against you' target:<[target_player]>
                    - narrate '<&5>Reason: <[reason]>'
                    - narrate '' target:<[target_player]>
                - else:
                    - narrate '[SERVER]: <&f><context.args.get[1]> <&e>is not a valid player name'
            - else:
                - teleport <yaml[server].read[first_join.tp]> <player>
                - narrate '[SERVER]: <&e>You have been teleported back to the pirate ship'
        - else:
            - narrate '[SERVER]: <&e>You do not have access to this command'
