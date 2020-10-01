qmw_player:
    type: world
    events:
        on player join:
            - run qm_player.yaml.load def:<player>
            
            - yaml id:<player.uuid> set logins:++
            - run qm_player.gamemode.load def:<player>|<player.gamemode>

        after player joins:
            - if <yaml[<player.uuid>].read[logins]||0> <= 1:
                - run qm_player.reset def:<player>
                - event firstjoin context:player|<player>
            # - else:
            #     - run qm_player.gamemode.load def:<player>|<player.gamemode>
        
        on player quits:
            - ~run qm_player.gamemode.save def:<player>|<player.gamemode>
            - ~run qm_player.yaml.save def:<player>
            - run qm_player.yaml.unload def:<player>

        on load:
            - foreach <server.online_players>:
                - run qm_player.yaml.load def:<[value]>

            # - run qm_command.add.command def:qm_player_cmd|dev
            # - run qm_command.add.aliases def:dev|develop
            # - run qm_command.add.aliases def:dev|developer
            # - run qm_command.add.tabcomplete def:dev|_*switch

            - run qm_command.add.command def:qm_player_cmd|player|developer
            - run qm_command.add.tabcomplete def:player|reset|_*players
            
        
        on save:
            - foreach <server.online_players>:
                - run qm_player.yaml.save def:<[value]>
        
        # on firstjoin:
        #     - run qm_player.reset def:<context.player>
        
        on player changes gamemode:
            - if <proc[qmp_player.loaded].context[<player>]>:
                - ~run qm_player.gamemode.save def:<player>|<player.gamemode>
                - run qm_player.gamemode.load def:<player>|<context.gamemode>

        on player death:
            - flag player death_location:<player.location>

        after player respawns:
            - define graveyard:<proc[qmp_region.find.graveyard].context[<player.flag[death_location]||<empty>>]>
            - if <[graveyard]> != <empty>:
                - teleport <[graveyard]> <player>
            - else:
                - teleport <yaml[server].read[first_join.tp]> <player>
        
        on player drops item:
            - if <player.gamemode> == creative:
                - narrate <proc[qmp_language].context[player_no_drop_creative|player]>
                - determine cancelled



qm_player:
    type: task
    script:
        - narrate 'invalid call to qm_player'
    
    yaml:
        load:
            - define target:<[1]||null>
            - if <[target]> != null:
                - if <server.has_file[/serverdata/players/<[target].uuid>.yml]>:
                    - yaml load:/serverdata/players/<[target].uuid>.yml id:<[target].uuid>
                - else:
                    - yaml create id:<[target].uuid>

                # Update player name
                - define currname:<yaml[<[target].uuid>].read[name]||null>
                - if <[currname]> != null && <[currname]> != <[target].name>:
                    - yaml id:<[target].uuid> set prevNames:->:<[currname]>
                - yaml id:<[target].uuid> set name:<[target].name>

                # Save data
                - run qm_player.yaml.save def:<[target]>

        save:
            - define target:<[1]||null>
            - if <[target]> != null:
                - yaml savefile:/serverdata/players/<[target].uuid>.yml id:<[target].uuid>

        unload:
            - define target:<[1]||null>
            - if <[target]> != null:
                - yaml unload id:<[target].uuid>
    
    reset:
        - define target_player:<[1]||null>
        - if <[target_player].is_player||false>:
            - define player_loaded:<yaml.list.contains[<[target_player].uuid>]>
            - if !<[player_loaded]>:
                - ~run qm_player.yaml.load def:<[target_player]>

            - yaml id:<[target_player].uuid> set old_logins:+:<yaml[<[target_player].uuid>].read[logins]||0>
            - yaml id:<[target_player].uuid> set first_join:!
            - yaml id:<[target_player].uuid> set regions:!
            - yaml id:<[target_player].uuid> set bankvault.size:9
            - yaml id:<[target_player].uuid> set bankvault.slots:!
            - yaml id:<[target_player].uuid> set quests:!
            - yaml id:<[target_player].uuid> set gamestate:!

            - if <[target_player].is_online>:
                - teleport <yaml[server].read[first_join.tp]> <[target_player]>
                - adjust <[target_player]> gamemode:survival
                - money take quantity:<[target_player].money> from:<[target_player]>
                - give money quantity:<yaml[server].read[first_join.money]||0> player:<[target_player]>
                - inventory d:<[target_player].inventory> clear
                - inventory d:<[target_player].enderchest> clear
                # - foreach <yaml[server].list_keys[first_join.items]||<list[]>>:
                #     - give <[value]> qty:<yaml[server].read[first_join.items.<[value]>]> to:<[target_player].inventory>
                - adjust <[target_player]> max_health:20
                - adjust <[target_player]> health:20
                - adjust <[target_player]> food_level:20
                - adjust <[target_player]> saturation:0
                - adjust <[target_player]> exhaustion:1
                - adjust <[target_player]> fall_distance:0
                - adjust <[target_player]> fire_time:0
                - adjust <[target_player]> oxygen:15
                - adjust <[target_player]> remove_effects
                - experience take <util.int_max> player:<[target_player]>

            - if <[target_player].is_online>:
                - yaml id:<[target_player].uuid> set logins:1
            - else:
                - yaml id:<[target_player].uuid> set logins:0

            - ~run qm_player.yaml.save def:<[target_player]>
            - if !<[player_loaded]>:
                - ~run qm_player.yaml.unload def:<[target_player]>

    gamemode:
        load:
            - define target_player:<[1]>
            - define gamemode:<[2]>

            - define id <[target_player].uuid>
            - define path:gamestate.<[gamemode]>
            
            - inventory clear
            - inventory d:<[target_player].enderchest> clear
            
            # Inventory 
            - define slots <yaml[<[id]>].read[<[path]>.inventory]||<map[]>> 
            - if !<[slots].is_empty>: 
                - inventory set d:<[target_player].inventory> o:<[slots]> 
            
            # Enderchest 
            - define slots <yaml[<[id]>].read[<[path]>.enderchest]||<map[]>> 
            - if !<[slots].is_empty>: 
                - inventory set d:<[target_player].enderchest> o:<[slots]> 
            
            # Equipment 
            - define slots <yaml[<[id]>].read[<[path]>.equipment]||<map[]>> 
            - if !<[slots].is_empty>: 
                - adjust <[target_player]> equipment:<[slots]> 
            
            # Offhand 
            - define slots <yaml[<[id]>].read[<[path]>.offhand]||null> 
            - if <[slots]> != null: 
                - adjust <[target_player]> item_in_offhand:<[slots]> 
            
            # Stats 
            - adjust <[target_player]> max_health:<yaml[<[id]>].read[<[path]>.stats.health_max]||20> 
            - adjust <[target_player]> health:<yaml[<[id]>].read[<[path]>.stats.health]||20> 
            - adjust <[target_player]> food_level:<yaml[<[id]>].read[<[path]>.stats.food_level]||20> 
            - adjust <[target_player]> saturation:<yaml[<[id]>].read[<[path]>.stats.saturation]||0> 
            - adjust <[target_player]> exhaustion:<yaml[<[id]>].read[<[path]>.stats.exhaustion]||1> 
            - adjust <[target_player]> fall_distance:<yaml[<[id]>].read[<[path]>.stats.fall_distance]||0> 
            - adjust <[target_player]> fire_time:<yaml[<[id]>].read[<[path]>.stats.fire_time]||0> 
            - adjust <[target_player]> oxygen:<yaml[<[id]>].read[<[path]>.stats.oxygen]||15> 
            - adjust <[target_player]> remove_effects 
            - adjust <[target_player]> potion_effects:<yaml[<[id]>].read[<[path]>.stats.potion_effects]||<list[]>> 
            - experience take <util.int_max> 
            - experience give <yaml[<[id]>].read[<[path]>.stats.xp]||0> 

        save:
            - define target_player:<[1]>
            - define gamemode:<[2]>

            - define id:<[target_player].uuid>
            - define path:gamestate.<[gamemode]>

            # Inventory
            - define slots <[target_player].inventory.map_slots.get_subset[<[target_player].inventory.map_slots.keys.filter[is[less].than[37]]>]>
            - if <[slots].is_empty>:
                - yaml set <[path]>.inventory:! id:<[id]>
            - else:
                - yaml set <[path]>.inventory:<[slots]> id:<[id]>

            # Enderchest
            - define slots <[target_player].enderchest.map_slots>
            - if <[slots].is_empty>:
                - yaml set <[path]>.enderchest:! id:<[id]>
            - else:
                - yaml set <[path]>.enderchest:<[slots]> id:<[id]>

            # Equipment
            - define slots <[target_player].equipment_map>
            - if <[slots].is_empty>:
                - yaml set <[path]>.equipment:! id:<[id]>
            - else:
                - yaml set <[path]>.equipment:<[slots]> id:<[id]>

            # Offhand
            - yaml set <[path]>.offhand:<[target_player].item_in_offhand> id:<[id]>

            # Stats
            - yaml set <[path]>.stats.health_max:<[target_player].health_max> id:<[id]>
            - yaml set <[path]>.stats.health:<[target_player].health> id:<[id]>
            - yaml set <[path]>.stats.food_level:<[target_player].food_level> id:<[id]>
            - yaml set <[path]>.stats.saturation:<[target_player].saturation> id:<[id]>
            - yaml set <[path]>.stats.exhaustion:<[target_player].exhaustion> id:<[id]>
            - yaml set <[path]>.stats.fall_distance:<[target_player].fall_distance> id:<[id]>
            - yaml set <[path]>.stats.fire_time:<[target_player].fire_time> id:<[id]>
            - yaml set <[path]>.stats.oxygen:<[target_player].oxygen> id:<[id]>
            - yaml set <[path]>.stats.potion_effects:<[target_player].list_effects> id:<[id]>
            - yaml set <[path]>.stats.xp:<proc[qmp_region.player.get_xp].context[<[target_player]>]> id:<[id]>
        


        # set:
        #     - define target_player:<[1]||null>
        #     - if <[target_player].is_player>:
        #         - adjust <[target_player]> gamemode:<yaml[regions].read[<player.flag[region]||null>.gamemode]||survival>
            


qmp_player:
    type: procedure
    debug: false
    script:
        - determine null
    
    is_developer:
        - define target:<[1]||null>
        - if <[target]> != null:
            - if <yaml[<[target].uuid>].read[developer]||0> != 0:
                - determine true
        - determine false
    
    is_moderator:
        - define target_player:<[1]||<empty>>
        - if <[target_player].is_player||false>:
            - if <[target_player].in_group[moderator]> || <proc[qmp_player.is_developer].context[<[target_player]>]> == true:
                - determine true
        - determine false

    is_bedrock:
        - define target_player:<[1]||<empty>>
        - if <[target_player].name.char_at[1]> == '*':
            - determine true
        - determine false

    is_java:
        - define target_player:<[1]||<empty>>
        - if <[target_player].name.char_at[1]> == '*':
            - determine false
        - determine true


    loaded:
        - define target_player:<[1]||<empty>>
        - if <[target_player].is_player> && <yaml.list.contains[<[target_player].uuid>]>:
            - determine true

        - determine false
    


qm_player_cmd:
    type: task
    debug: false
    script:
        # - define action:<[1]||null>
        # - define option:<[2]||null>
        # - define value:<[3]||null>

        - choose <[1].get[command]>:
            - case dev:
                - if <proc[qmp_player.is_developer].context[<[1].get[player]>]>:
                    - choose <[1].get[option]>:
                        - case true on enable enabled:
                            - run qm_player_cmd.dev.on
                        - case false off disable disabled:
                            - run qm_player_cmd.dev.off
                        - default:
                            - if <player.in_group[developer]>:
                                - run qm_player_cmd.dev.off
                            - else:
                                - run qm_player_cmd.dev.on
                - else:
                    - narrate <proc[qmp_lang].context[<player||null>|command_not_permitted|command]>
            
            - case player:
                # - if !<player.in_group[developer]>:
                #     - narrate <proc[qmp_lang].context[<player||null>|command_not_permitted|command]>
                #     - stop

                - if <[1].get[option]> == reset:
                    - if <[1].get[args].get[1]||<empty>> == <empty>:
                        - define arg_player_name:<[1].get[player].name>
                    - else:
                        - define arg_player_name:<[1].get[args].get[1]>
                                        
                    - define target_player:<server.match_player[<[arg_player_name]>]>
                    - if <[target_player].is_player>:
                        - run qm_player.reset def:<[target_player]>
                        - narrate <proc[qmp_language].context[player_reset|player|<map[player/<[target_player].name>].escaped>]>
                    - else:
                        - narrate <proc[qmp_language].context[player_not_found|player|<map[player/<[target_player].name>].escaped>]>

    
    dev:
        on:
            - group add developer
            - adjust <player> gamemode:creative
            - narrate <proc[qmp_lang].context[<player||null>|developer_mode_on|player]>
        off:
            - group remove developer
            - group add default
            - run qm_region.gamemode.set def:<player>
            - narrate <proc[qmp_lang].context[<player||null>|developer_mode_off|player]>

                            
