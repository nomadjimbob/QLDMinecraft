qmw_region:
    type: world
    debug: false
    events:
        on load:
            - run qm_command.add.command def:qm_region_cmd|region|developer
            - run qm_command.add.aliases def:region|rg
            - run qm_command.add.tabcomplete def:region|create
            - run qm_command.add.tabcomplete def:region|player|_*players
            - run qm_command.add.tabcomplete def:region|list
            - run qm_command.add.tabcomplete def:region|_*regions|remove
            - run qm_command.add.tabcomplete def:region|_*regions|update
            - run qm_command.add.tabcomplete def:region|_*regions|priority
            - run qm_command.add.tabcomplete def:region|_*regions|title
            - run qm_command.add.tabcomplete def:region|_*regions|block_place|_*boolean

            
            # - run qm_command.add.tabcomplete def:region|list
            # 
            # - run qm_command.add.tabcomplete def:region|update|_*regions
            # - run qm_command.add.tabcomplete def:region|delete|_*regions
            # - run qm_command.add.tabcomplete def:region|priority|_*regions|_*number
            # - run qm_command.add.tabcomplete def:region|type
            # - run qm_command.add.tabcomplete def:region|name
            # - run qm_command.add.tabcomplete def:region|biomeadd|_*regions|_*biomes

            - run qm_region.yaml.load
        
        on save:
            - run qm_region.yaml.save
        
        on system time minutely every:5:
            - run qm_region.spawn
                            

        after player joins:
            - flag player region:!
            - flag player region_list:!
            - foreach <yaml[regions].list_keys[regions]>:
                - if <player.location.is_within[<yaml[regions].read[regions.<[value]>.cuboid]>]>:
                    - flag player region_list:->:<[value]>
            
            - wait 2t
            - run qmw_region.update_player_region

        on player enters *:
            - run qmw_region.update_player_region def:<context.to||<empty>>
        
            # - if <context.area.note_name.starts_with[qm_region_]||false>:
            #     - define region_id:<context.area.note_name.after[qm_region_]>
            #     - if !<player.flag[region_list].contains[<[region_id]>]||false>:
            #         - flag player region_list:->:<[region_id]>

            #         - wait 1t
            #         - ~run locally update_region def:<player.location.biome> save:update_result
            #         - foreach <entry[update_result].created_queue.determination||<list[]>>:
            #             - foreach <[value].as_list||<list[]>>:
            #                 - if <[value]> == cancelled:
            #                     - flag player region_list:<-:<[region_id]>
            #                     - determine passively <[value]>

        on player exits *:
            - run qmw_region.update_player_region def:<context.to>

            # - if <context.area.note_name.starts_with[qm_region_]||false>:
            #     - define region_name:<context.area.note_name.after[qm_region_]>
            #     - flag player region_list:<-:<[region_name]>

            #     - flag player region_list:<-:<[region_name]>
            #     - run locally update_region


        on player enters biome:
            - run qmw_region.update_player_region def:<context.to>

            # - if !<list[river].contains[<context.new_biome.name>]>:
            #     - run locally update_region def:<context.new_biome> save:update_result
            #     - foreach <entry[update_result].created_queue.determination||<list[]>>:
            #         - foreach <[value].as_list||<list[]>>:
            #             - determine <[value]>
        
        # The following event is not needed at this time
        # on player walks:
        #     - ~run locally update_region def:<player.location.biome> save:update_result
        #     - foreach <entry[update_result].created_queue.determination||<list[]>>:
        #         - foreach <[value].as_list||<list[]>>:
        #             - determine <[value]>

        on player places block:
            - if !<player.in_group[developer]>:
                - if <proc[qmp_region.find.block_place].context[<context.location>]> == false:
                    - if <player.flag[block_place_allow]||false> == false:
                        - narrate <proc[qmp_language].context[no_place_block_region|region]>
                        - determine passively cancelled
                - else:
                    - if <player.flag[block_place_deny]||false>:
                        - narrate <proc[qmp_language].context[no_place_block_region|region]>
                        - determine passively cancelled
                
                - if <proc[qmp_region.find.gamemode].context[<context.location>]> != <proc[qmp_region.find.gamemode].context[<player.location>]>:
                    - narrate <proc[qmp_language].context[no_place_block_region|region]>
                    - determine passively cancelled
            
            - flag player block_place_allow:!
            - flag player block_place_deny:!


        on player breaks block:
            - if !<player.in_group[developer]>:
                - if <proc[qmp_region.find.block_break].context[<context.location>]> == false:
                    - if <player.flag[block_break_allow]||false> == false:
                        - narrate <proc[qmp_language].context[no_break_block_region|region]>
                        - determine passively cancelled
                - else:
                    - if <player.flag[block_break_deny]||false>:
                        - narrate <proc[qmp_language].context[no_break_block_region|region]>
                        - determine passively cancelled

                - if <proc[qmp_region.find.gamemode].context[<context.location>]> != <proc[qmp_region.find.gamemode].context[<player.location>]>:
                    - narrate <proc[qmp_language].context[no_break_block_region|region]>
                    - determine passively cancelled

            - flag player block_break_allow:!
            - flag player block_break_deny:!
        
        on player opens inventory:
            - if <context.inventory.location||<empty>> != <empty>:
                - if <proc[qmp_region.find.gamemode].context[<context.inventory.location>]> != <proc[qmp_region.find.gamemode].context[<player.location>]>:
                    - determine passively cancelled


        on lightning strikes:
            - if <proc[qmp_region.find.lightning_strike].context[<context.location>]> == false:
                - determine cancelled

        on block ignites:
            - if <proc[qmp_region.find.block_ignite].context[<context.location>]> == false:
                - determine cancelled

        on block burns:
            - if <proc[qmp_region.find.block_burn].context[<context.location>]> == false:
                - determine cancelled

        on block spreads:
            - if <proc[qmp_region.find.block_spread].context[<context.location>]> == false:
                - determine cancelled

        on liquid spreads:
            - if <proc[qmp_region.find.liquid_spread].context[<context.location>]> == false:
                - determine cancelled

        # on player opens inventory:
        #     - define inventory_region:<proc[qmp_region.find.id].context[<context.inventory.location||null>]||null>
        #     - define player_region:<proc[qmp_region.find.id].context[<player.location>]||null>

        #     - if <[inventory_region]> != null && <[inventory_region]> != <[player_region]>:
        #         - narrate format:notice "XXYou cannot open chests across different zones"
        #         - determine cancelled
        #         - stop
        
    update_player_region:
        - define location:<[1]||<player.location>>
        - if <[location]> != <empty>:
            - define old_region:<player.flag[region]||<empty>>
            - define new_region_list:<proc[qmp_region.find.list].context[<[location]>]>
            - define new_region:<[new_region_list].get[1]||<empty>>

            - if <[new_region]> != <[old_region]>:
                - flag player region:<[new_region]>
                - define gamemode:<proc[qmp_region.find.gamemode].context[<[location]>]>
                - if !<proc[qmp_server.player.in_developer_mode].context[<player>]>:
                    - adjust <player> gamemode:<[gamemode]>
                
                - define title:<proc[qmp_region.get.title].context[<[new_region]>]||<empty>>
                - if <proc[qmp_region.player.region_discovered].context[<player>|<[new_region]>]>:
                    - if <[title]> != <empty>:
                        - define type:<proc[qmp_region.get.type].context[<[new_region]>]||<empty>>
                        - if <[type]> != <empty>:
                            - define announce_format:<proc[qmp_language].context[region_entered_<[type]>|region|<map[title/<[title]>].escaped>]||<empty>>

                        - if <[type]> == <empty> || <[announce_format]> == <empty>:
                            - define announce_format:<proc[qmp_language].context[region_entered|region|<map[title/<[title]>].escaped>]>

                        - actionbar <[announce_format]>
                    - else:
                        - define old_title:<proc[qmp_region.get.title].context[<[old_region]>]||<empty>>
                        - if <[old_title]> != <empty>:
                            - define type:<proc[qmp_region.get.type].context[<[old_region]>]||<empty>>
                            - if <[type]> != <empty>:
                                - define announce_format:<proc[qmp_language].context[region_leave_<[type]>|region|<map[title/<[old_title]>].escaped>]||<empty>>

                            - if <[type]> == <empty> || <[announce_format]> == <empty>:
                                - define announce_format:<proc[qmp_language].context[region_leave|region|<map[title/<[old_title]>].escaped>]>

                            - actionbar <[announce_format]>
                        
                - else:
                    - run qm_region.player.region_discover def:<player>|<[new_region]>
                    - if <[title]> != <empty>:
                        - actionbar <proc[qmp_language].context[region_discovered|region|<map[title/<[title]>].escaped>]>
                
            
            # announce!




    # update_region:
    #     - stop

    #     - define biome:<[1].name||null>
    #     - define region_id:null
    #     - define region_priority:-1

    #     - foreach <player.flag[region_list]||<list[]>>:
    #         - if <[biome]> != null:
    #             - define loop_biomes:<yaml[regions].read[regions.<[value]>.biomes]||<list[]>>
    #             - if <[loop_biomes].size> > 0:
    #                 - if !<[loop_biomes].contains[<[biome]>]>:
    #                     - foreach next

    #         - define loop_priority:<yaml[regions].read[regions.<[value]>.priority]||0>
    #         - if <[loop_priority]> > <[region_priority]>:
    #             - define region_id:<[value]>
    #             - define region_priority:<[loop_priority]>

    #     - if <[region_id]> != <player.flag[region]||<element[]>>:
    #         - if <[region_id]> != null:
    #             - define gamemode:<yaml[regions].read[<[region_id]>.gamemode]||survival>
    #             - if <[gamemode]> != <player.gamemode> && !<player.in_group[developer]>:
    #                 - adjust <player> gamemode:<[gamemode]>

    #             - event "player enters region" context:name|<[region_id]> save:event_result
    #             - define actionbar:null
    #             - define message:null

    #             - foreach <entry[event_result].determinations||<list[]>>:
    #                 - foreach <[value]||<list[]>>:
    #                     - if <[value]> == cancelled:
    #                         - determine cancelled
    #                     - else if <[value].starts_with[actionbar:]>:
    #                         - define actionbar:<[value].after_last[actionbar:]>
    #                     - else if <[value].starts_with[message:]>:
    #                         - define message:<[value].after_last[message:]>

    #             - flag player region:<[region_id]>

    #             - if <[actionbar]> != null:
    #                 - actionbar <[actionbar]>
    #             - else if <yaml[regions].read[regions.<[region_id]>.name]||null> != null:
    #                 - define region_name:<yaml[regions].read[regions.<[region_id]>.name]||null>
    #                 - define region_type:<yaml[regions].read[regions.<[region_id]>.type]||null>
    #                 - define region_lvl:<yaml[regions].read[regions.<[region_id]>.level]||null>
                    
    #                 - if <[region_name]> != null:
    #                     - define textcolor:<yaml[regions].read[colors.area]||<element[e]>>
    #                     - define entertext:<proc[qmp_language].context[region_enter_area|region|<map[region/<[region_name]>]>]>

    #                     # - choose <[region_type]>:
    #                     #     - case town:
    #                     #         - define textcolor:<yaml[regions].read[colors.town]||<element[e]>>
    #                     #         - define entertext:<proc[qmp_language].context[region_enter_town|region|<map[region/<[region_name]>]>]>
    #                     #     - default:
    #                     #         - if <[region_lvl]> != null:
    #                     #             - if <player.xp_level> > <[region_lvl]>:
    #                     #                 - define textcolor:<yaml[regions].read[colors.leveldown]||<element[e]>>
    #                     #             - else if <[region_lvl]> > <player.xp_level.add[2]>:
    #                     #                 - define textcolor:<yaml[regions].read[colors.levelup]||<element[e]>>
                            
    #                     - if !<yaml[<player.uuid>].read[regions.discovered].contains[<[region_id]>]||false>:
    #                         - define entertext:<proc[qmp_language].context[region_discovered|region|<map[region/<[region_name]>]>]>
    #                         - yaml id:<player.uuid> set regions.discovered:->:<[region_id]>

    #                     - actionbar <&color[<[textcolor]>]><[entertext]>
                                
    #             - if <[message]> != null:
    #                 - narrate <[message]>
    #         - else:
    #             - flag player region:<[region_id]>



qm_region:
    type: task
    debug: false
    script:
        - run qm_debug 'def:Called qm_region incorrectly!'
    
    yaml:
        load:
            - if <server.has_file[/serverdata/regions.yml]>:
                - ~yaml load:/serverdata/regions.yml id:regions
            - else:
                - ~yaml create id:regions
                - yaml savefile:/serverdata/regions.yml id:regions

            - ~run locally sync

        save:
            - yaml savefile:/serverdata/regions.yml id:regions

        set:
            - define region_id:<[1]||null>
            - define key:<[2]||null>
            - define value:<[3]||null>
            - if <[region_id]> != null && <[key]> != null:
                - yaml id:regions set regions.<[region_id]>.<[key]>:<[value]>
                - run qm_region.yaml.save

        clear:
            - define region_id:<[1]||null>
            - define key:<[2]||null>
            - if <[region_id]> != null && <[key]> != null:
                - yaml id:regions set regions.<[region_id]>.<[key]>:!
    
    sync:
        - foreach <server.notables[cuboids]>:
            - if <[value].note_name.starts_with[qm_region_]>:
                - note remove as:<[value].note_name>
        
        - foreach <yaml[regions].list_keys[regions]||<list[]>>:
            - define region_cuboid:<yaml[regions].read[regions.<[value]>.cuboid]||null>
            - if <[region_cuboid]> != null:
                - note <[region_cuboid]> as:qm_region_<[value]>
    
    spawn:
        - foreach <yaml[regions].list_keys[regions]>:
            - define region_id:<[value]>
            - define target_cuboid:<yaml[regions].read[regions.<[region_id]>.cuboid]>
            - foreach <yaml[regions].list_keys[regions.<[region_id]>.spawn.materials]||<list[]>>:
                - define target_material:<[value]>
                - define target_quantity:<yaml[regions].read[regions.<[region_id]>.spawn.materials.<[target_material]>]||0>
                - define target_quantity:<[target_quantity].sub[<[target_cuboid].blocks[<[target_material]>].size>]||0>
                - if <[target_quantity]> > 3:
                    - define target_quantity:3

                - while <[target_quantity]> > 0:
                    - define x:<util.random.int[<[target_cuboid].min.x>].to[<[target_cuboid].max.x>]>
                    - define y:<[target_cuboid].min.y>
                    - define z:<util.random.int[<[target_cuboid].min.z>].to[<[target_cuboid].max.z>]>
                    - while <[y]> < <[target_cuboid].max.y>:
                        - if <location[<[x]>,<[y]>,<[z]>,<[target_cuboid].min.world.name>].material.name> == air:
                            - modifyblock <location[<[x]>,<[y]>,<[z]>,<[target_cuboid].min.world.name>]> <[target_material]>
                            - define target_quantity:--
                            - while stop
                        - else:
                            - define y:++
            
            - foreach <yaml[regions].list_keys[regions.<[region_id]>.spawn.entities]||<list[]>>:
                - define target_entity:<[value]>
                - define target_quantity:<yaml[regions].read[regions.<[region_id]>.spawn.entities.<[target_entity]>]||0>
                - define target_quantity:<[target_quantity].sub[<[target_cuboid].entities[<[target_entity]>].size>]||0>
                
                - if <[target_quantity]> > 0:
                    - define x:<util.random.int[<[target_cuboid].min.x>].to[<[target_cuboid].max.x>]>
                    - define y:<[target_cuboid].min.y>
                    - define z:<util.random.int[<[target_cuboid].min.z>].to[<[target_cuboid].max.z>]>
                    - define target_location:<location[<[x]>,<[y]>,<[z]>,island].highest.up[1]>
                    - spawn <[target_entity]> <[target_location]>

    player:
        region_discover:
            - define target_player:<[1]||<empty>>
            - define region_id:<[2]||<empty>>

            - if <[target_player].is_player||false> && <[region_id]> != <empty> && <proc[qmp_player.loaded].context[<[target_player]>]>:
                - if !<yaml[<[target_player].uuid>].read[regions.discovered].contains[<[region_id]>]||false>:
                    - yaml id:<[target_player].uuid> set regions.discovered:->:<[region_id]>
                    - run qm_player.yaml.save



qmp_region:
    type: procedure
    debug: false
    script:
        - determine null
    
    player:
        get_xp:
            - define target_player:<[1]>
            - define lvl:<[target_player].xp_level>
            - if <[lvl]> <= 16:
                - define level_xp:<[lvl].add[6].mul[<[lvl]>]>
            - else if <[lvl]> <= 31:
                - define level_xp:<[lvl].mul[<[lvl]>].mul[2.5].sub[<[lvl].mul[40.5]>].add[360]>
            - else:
                - define level_xp:<[lvl].mul[<[lvl]>].mul[4.5].sub[<[lvl].mul[162.5]>].add[2220]>
            - define curr_xp:<[target_player].xp.mul[<[target_player].xp_to_next_level>].div[100]>
            - determine <[level_xp].add[<[curr_xp]>].round>
        
        region_discovered:
                - define target_player:<[1]||<empty>>
                - define region_id:<[2]||<empty>>
                - if <[target_player].is_player||false> && <[region_id]> != <empty>:
                    - determine <yaml[<[target_player].uuid>].read[regions.discovered].contains[<[region_id]>]||false>
                - determine true
    
    get:
        graveyard:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - determine <yaml[regions].read[regions.<[region_id]>.graveyard]||<empty>>
            - determine <empty>

        priority:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - determine <yaml[regions].read[regions.<[region_id]>.priority]||0>
            - determine 0

        title:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - determine <yaml[regions].read[regions.<[region_id]>.title]||<empty>>
            - determine <empty>
        
        type:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - determine <yaml[regions].read[regions.<[region_id]>.type]||<empty>>
            - determine <empty>
        
        block_place:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.block_place]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.block_place].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>

        block_break:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.block_break]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.block_break].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>

        block_ignite:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.block_ignite]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.block_ignite].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>

        block_burn:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.block_burn]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.block_burn].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>

        block_spread:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.block_spread]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.block_spread].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>

        liquid_spread:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.liquid_spread]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.liquid_spread].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>

        lightning_strike:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.lightning_strike]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.lightning_strike].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>

        gamemode:
            - define region_id:<[1]||<empty>>
            - if <[region_id]> != <empty>:
                - define result:<yaml[regions].read[regions.<[region_id]>.gamemode]||<empty>>
                - if <[result]> == <empty>:
                    - define result:<proc[qmp_regiontype.get.gamemode].context[<proc[qmp_region.get.type].context[<[region_id]>]>]>

                - determine <[result]>
            - determine <empty>





        key:
            - define region_id:<[1]||null>
            - define key:<[2]||null>
            - if <[region_id]> != null && <[key]> != null:
                - determine <yaml[regions].read[regions.<[region_id]>.<[key]>]||null>
            - determine null
        
        name:
            - define region_id:<[1]||null>
            - define region_name:<[region_id]>
            - if <[region_id]> != null && <[key]> != null:
                - define region_name:<yaml[regions].read[regions.<[region_id]>.name]||<[region_id]>>
            - determine <[region_name]>

    find:
        block_place:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.block_place].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine true
            
        block_break:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.block_break].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine true

        block_ignite:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.block_ignite].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine true

        block_burn:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.block_burn].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine true

        block_spread:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.block_spread].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine true

        liquid_spread:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.liquid_spread].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine true

        lightning_strike:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.lightning_strike].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine true

        gamemode:
            - define location:<[1]||<empty>>
            - define found_regions:<proc[qmp_region.find.list].context[<[location]>]>
            - foreach <[found_regions]>:
                - define region_result:<proc[qmp_region.get.gamemode].context[<[value]>]>
                - if <[region_result]> != <empty>:
                    - determine <[region_result]>

            - determine survival
    
        list:
            - define location:<[1]||<empty>>
            - define found_regions:<list[]>

            - if <[location].type> != <empty>:
                - define region_list:<yaml[regions].list_keys[regions]||<list[]>>

                - define temp_found_list:<map[]>

                - foreach <[region_list]>:
                    - define inside:0
                    - define loop_region_id:<[value]>

                    - if <[location].is_within[<yaml[regions].read[regions.<[loop_region_id]>.cuboid]>]||false>:
                        - define biomes:<yaml[regions].read[regions.<[loop_region_id]>.biomes]||<list[]>>
                        - if <[biomes].size> > 0:
                            - if !<[biomes].contains[<[location].biome.name>]>:
                                - foreach next

                        - define loop_region_priority:<yaml[regions].read[regions.<[loop_region_id]>.priority]||0>
                        - define temp_found_list:<[temp_found_list].with[<[loop_region_id]>].as[<[loop_region_priority]>]>

                - define found_regions:<[temp_found_list].sort_by_value.keys.reverse>

            - determine <[found_regions]>

        graveyard:
            - define location:<[1]||<empty>>
            - if <[location]> != <empty>:
                - define region_list:<proc[qmp_region.find.list].context[<[location]>]>

                - foreach <[region_list]>:
                    - define graveyard:<proc[qmp_region.get.graveyard].context[<[value]>]>
                    - if <[graveyard]> != <empty>:
                        - determine <[graveyard]>

            - determine <empty>

    in_region:
        - define location:<[1]||<empty>>
        - define region_id:<[2]||<empty>>

        - if <[location]> != <empty> && <[region_id]> != <empty>:
            - define region_list:<proc[qmp_region.find.list].context[<[location]>]>
            - if <[region_list].contains[<[region_id]>]||false>:
                - determine true

        - determine false

        # type:
        #     - define location:<[1]>
        #     - define region_type:null
        #     - define region_id:<proc[qmp_region.find.id].context[<[location]>]||null>
        #     - if <[region_id]> != null:
        #         - define region_type:<yaml[regions].read[regions.<[region_id]>.type]||null>
        #     - determine <[region_type]>

        # id:
        #     - define location:<[1]>
        #     - define region_list:<[2]||null>
        #     - define region_id:null
        #     - define region_priority:-1

        #     - if <[region_list]> == null:
        #         - define region_list:<yaml[regions].list_keys[regions]||<list[]>>

        #     - foreach <[region_list]>:
        #         - define inside:0
        #         - define loop_region_id:<[value]>

        #         - if <[location].is_within[<yaml[regions].read[regions.<[loop_region_id]>.cuboid]>]||false>:
        #             - define biomes:<yaml[regions].read[regions.<[loop_region_id]>.biomes]||<list[]>>
        #             - if <[biomes].size> > 0:
        #                 - if !<[biomes].contains[<[location].biome.name>]>:
        #                     - foreach next

        #             - define loop_region_priority:<yaml[regions].read[regions.<[loop_region_id]>.priority]||0>
        #             - if <[loop_region_priority]> > <[region_priority]>:
        #                 - define region_id:<[loop_region_id]>
        #                 - define region_priority:<[loop_region_priority]>
            
        #     - determine <[region_id]>

        
qmp_regiontype:
    type: procedure
    debug: false
    script:
        - determine null

    get:
        block_place:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.block_place]||<empty>>

        block_break:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.block_break]||<empty>>

        block_ignite:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.block_ignite]||<empty>>

        block_burn:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.block_burn]||<empty>>

        block_spread:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.block_spread]||<empty>>

        liquid_spread:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.liquid_spread]||<empty>>

        lightning_strike:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.lightning_strike]||<empty>>

        gamemode:
            - determine <yaml[regions].read[region_types.<[1]||<empty>>.gamemode]||<empty>>



qm_region_cmd:
    type: task
    script:
        - choose <[1].get[command]>:
            - case 'region':
                - choose <[1].get[option]>:
                    - case create:
                        - define region_id:<[1].get[args].get[1]||<empty>>
                        - if <[region_id]> != <empty>:
                            - if !<yaml[regions].list_keys[regions.<[region_id]>]>:
                                - yaml id:regions set regions.<[region_id]>.cuboid:<[1].get[player].we_selection>
                                - narrate <proc[qmp_language].context[region_created|region|<map[region/<[region_id]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[region_id_exists|region|<map[region/<[region_id]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[no_region_id_entered|region]>
                    - case player:
                        - if <[1].get[args].get[1]||<empty>> == <empty>:
                            - define target_player:<[1].get[player]>
                        - else:
                            - define target_player:<proc[qmp_server.find.player].context[<[1].get[args].get[1]>]>
                        
                        - if <[target_player].is_player||false>:
                            - define region_list:<proc[qmp_region.find.list].context[<[target_player].location>]>

                            - if <[region_list].size> > 0:
                                - foreach <[region_list]>:
                                    - narrate <proc[qmp_language].context[region_info|region|<map[region/<[value]>|priority/<proc[qmp_region.get.priority].context[<[value]>]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[not_inside_region|region]>
                        - else:
                            - narrate <proc[qmp_language].context[player_name_invalid|server]>
                    - case list <empty>:
                        - define region_list:<yaml[regions].list_keys[regions]>
                        - narrate '<[region_list].separated_by[, ]>'
                    - default:
                        - define region_id:<[1].get[option]>
                        - choose <[1].get[args].get[1]||<empty>>:
                            - case rem remove del delete:
                                - if <[region_id]> != <empty>:
                                    - if <yaml[regions].list_keys[regions].contains[<[region_id]>]>:
                                        - yaml id:regions set regions.<[region_id]>:!
                                        - narrate <proc[qmp_language].context[region_removed|region|<map[region/<[region_id]>].escaped>]>
                                    - else:
                                        - narrate <proc[qmp_language].context[region_id_not_exist|region|<map[region/<[region_id]>].escaped>]>
                                - else:
                                    - narrate <proc[qmp_language].context[no_region_id_entered|region]>
                            - case update:
                                # todo this may remove the adds as well
                                - if <[region_id]> != <empty>:
                                    - if <yaml[regions].list_keys[regions].contains[<[region_id]>]>:
                                        - yaml id:regions set regions.<[region_id]>.cuboid:<[1].get[player].we_selection>
                                        - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region_id]>].escaped>]>
                                    - else:
                                        - narrate <proc[qmp_language].context[region_id_not_exist|region|<map[region/<[region_id]>].escaped>]>
                                - else:
                                    - narrate <proc[qmp_language].context[no_region_id_entered|region]>
                            - case priority:
                                - define priority:<[1].get[args].get[2]||<empty>>
                                - if <[priority]> != <empty>:
                                    - if <[priority].is_integer> || <[priority]> == -:
                                        - if <yaml[regions].list_keys[regions].contains[<[region_id]>]>:
                                            - if <[priority]> == -:
                                                - yaml id:regions set regions.<[region_id]>.priority:!
                                            - else:
                                                - yaml id:regions set regions.<[region_id]>.priority:<[priority]>
                                            - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region_id]>].escaped>]>
                                        - else:
                                            - narrate <proc[qmp_language].context[region_id_not_exist|region|<map[region/<[region_id]>].escaped>]>
                                    - else:
                                        - narrate <proc[qmp_language].context[region_priority_not_number|region]>
                                - else:
                                    - narrate <proc[qmp_language].context[region_info_priority|region|<map[region/<[region_id]>|priority/<proc[qmp_region.get.priority].context[<[region_id]>]>].escaped>]>
                            - case title:
                                - define title:<[1].get[args].get[2]||<empty>>
                                - if <[title]> != <empty>:
                                    - if <yaml[regions].list_keys[regions].contains[<[region_id]>]>:
                                        - if <[title]> == -:
                                            - yaml id:regions set regions.<[region_id]>.title:!
                                        - else:
                                            - yaml id:regions set regions.<[region_id]>.title:<[title]>
                                        - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region_id]>].escaped>]>
                                    - else:
                                        - narrate <proc[qmp_language].context[region_id_not_exist|region|<map[region/<[region_id]>].escaped>]>
                                - else:
                                    - define value:<proc[qmp_region.get.title].context[<[region_id]>]>
                                    - if <[value]> == <empty>:
                                        - define value:<element[$NOTSET$]>
                                    - narrate <proc[qmp_language].context[region_info_title|region|<map[region/<[region_id]>|title/<[value]>].escaped>]>
                            - case type:
                                - define type:<[1].get[args].get[2]||<empty>>
                                - if <[type]> != <empty>:
                                    - if <yaml[regions].list_keys[regions].contains[<[region_id]>]>:
                                        - if <[type]> == -:
                                            - yaml id:regions set regions.<[region_id]>.type:!
                                        - else:
                                            - yaml id:regions set regions.<[region_id]>.type:<[type]>
                                        - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region_id]>].escaped>]>
                                    - else:
                                        - narrate <proc[qmp_language].context[region_id_not_exist|region|<map[region/<[region_id]>].escaped>]>
                                - else:
                                    - define value:<proc[qmp_region.get.type].context[<[region_id]>]>
                                    - if <[value]> == <empty>:
                                        - define value:<element[$NOTSET$]>
                                    - narrate <proc[qmp_language].context[region_info_type|region|<map[region/<[region_id]>|type/<[value]>].escaped>]>
                            - case block_place:
                                - define value:<[1].get[args].get[2]||<empty>>
                                - if <[value]> != <empty>:
                                    - if <yaml[regions].list_keys[regions].contains[<[region_id]>]>:
                                        - if <list[true|false|-].contains[<[value]>]>:
                                            - if <[value]> == -:
                                                - yaml id:regions set regions.<[region_id]>.block_place:!
                                            - else:
                                                - yaml id:regions set regions.<[region_id]>.block_place:<[value]>
                                            - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region_id]>].escaped>]>
                                        - else:
                                            - narrate <proc[qmp_language].context[value_requires_true_false|server]>
                                    - else:
                                        - narrate <proc[qmp_language].context[region_id_not_exist|region|<map[region/<[region_id]>].escaped>]>
                                - else:
                                    - define value:<proc[qmp_region.get.block_place].context[<[region_id]>]>
                                    - if <[value]> == <empty>:
                                        - define value:<element[$NOTSET$]>
                                    - narrate <proc[qmp_language].context[region_info_meta|region|<map[region/<[region_id]>|meta/block_place|value/<[value]>].escaped>]>
                            - case block_break:
                                - define value:<[1].get[args].get[2]||<empty>>
                                - if <[value]> != <empty>:
                                    - if <yaml[regions].list_keys[regions].contains[<[region_id]>]>:
                                        - if <list[true|false|-].contains[<[value]>]>:
                                            - if <[value]> == -:
                                                - yaml id:regions set regions.<[region_id]>.block_break:!
                                            - else:
                                                - yaml id:regions set regions.<[region_id]>.block_break:<[value]>
                                            - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region_id]>].escaped>]>
                                        - else:
                                            - narrate <proc[qmp_language].context[value_requires_true_false|server]>
                                    - else:
                                        - narrate <proc[qmp_language].context[region_id_not_exist|region|<map[region/<[region_id]>].escaped>]>
                                - else:
                                    - define value:<proc[qmp_region.get.block_break].context[<[region_id]>]>
                                    - if <[value]> == <empty>:
                                        - define value:<element[$NOTSET$]>
                                    - narrate <proc[qmp_language].context[region_info_meta|region|<map[region/<[region_id]>|meta/block_break|value/<[value]>].escaped>]>

                - run qm_region.sync


        # - define action:<[1]||null>
        # - define option:<[2]||null>
        # - define region:<[3]||null>
        # - define value:<[4]||null>

        # - choose <[action]>:
        #     - case region:
        #         - choose <[option]>:
        #             - case creativeinv:
        #                 - run qm_region.gamemode.load_creative_inventory def:<player>
        #             - case list:
        #                 - narrate <proc[qmp_language].context[region_show_list|region]>
        #                 - foreach <yaml[regions].list_keys[regions]>:
        #                     - narrate '- <[value]>'
        #             - case create:
        #                 - if <[region]> != null:
        #                     - if !<yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - define selected_cuboid:<player.we_selection>
        #                         - yaml id:regions set regions.<[region]>.cuboid:<[selected_cuboid]>
        #                         - run qm_region.yaml.save
        #                         - note <[selected_cuboid]> as:qm_region_<[region]>
        #                         - narrate <proc[qmp_language].context[region_created|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_exists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>
        #             - case add:
        #                 - if <[region]> != null:
        #                     - if <yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - define selected_cuboid:<player.we_selection>
        #                         - define region_cuboid:<yaml[regions].read[regions.<[region]>.cuboid].as_cuboid.add_member[<[selected_cuboid]>]>
        #                         - yaml id:regions set regions.<[region]>.cuboid:<[region_cuboid]>
        #                         - run qm_region.yaml.save
        #                         - note <[region_cuboid]> as:qm_region_<[region]>
        #                         - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_notexists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>
        #             - case del delete rem remove:
        #                 - if <[region]> != null:
        #                     - if <yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - yaml id:regions set regions.<[region]>:!
        #                         - run qm_region.yaml.save
        #                         - note remove as:qm_region_<[region]>
        #                         - narrate <proc[qmp_language].context[region_deleted|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_notexists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>
        #             - case update:
        #                 - if <[region]> != null:
        #                     - if <yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - define selected_cuboid:<player.we_selection>
        #                         - yaml id:regions set regions.<[region]>.cuboid:<[selected_cuboid]>
        #                         - run qm_region.yaml.save
        #                         - note remove as:qm_region_<[region]>
        #                         - note <[selected_cuboid]> as:qm_region_<[region]>
        #                         - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_notexists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>
        #             - case priority:
        #                 - if <[region]> != null:
        #                     - if <yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - yaml id:regions set regions.<[region]>.priority:<[value]>
        #                         - run qm_region.yaml.save
        #                         - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_notexists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>
        #             - case name:
        #                 - if <[region]> != null:
        #                     - if <yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - yaml id:regions set regions.<[region]>.name:<[value]>
        #                         - run qm_region.yaml.save
        #                         - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_notexists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>
        #             - case type:
        #                 - if <[region]> != null:
        #                     - if <yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - yaml id:regions set regions.<[region]>.type:<[value]>
        #                         - run qm_region.yaml.save
        #                         - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_notexists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>
        #             - case biomeadd:
        #                 - if <[region]> != null:
        #                     - if <yaml[regions].list_keys[regions].contains[<[region]>]>:
        #                         - if !<yaml[regions].read[regions.<[region]>.biomes].contains[<[value]>]||<list[]>>:
        #                             - yaml id:regions set regions.<[region]>.biomes:->:<[value]>
        #                             - run qm_region.yaml.save
        #                             - narrate <proc[qmp_language].context[region_updated|region|<map[region/<[region]>]>]>
        #                         - else:
        #                             - narrate <proc[qmp_language].context[region_biome_exists|region|<map[region/<[region]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_language].context[region_id_notexists|region]>
        #                 - else:
        #                     - narrate <proc[qmp_language].context[region_id_missing|region]>

        #             - case sync:
        #                 - ~run qm_region.sync
        #                 - narrate <proc[qmp_language].context[regions_synchronized|region]>

        #             - default:
        #                 - narrate <proc[qmp_language].context[command_invalid|command]>

qmp_command_tabcomplete_regions:
    type: procedure
    debug: false
    script:
        - determine <yaml[regions].list_keys[regions]||<list[]>>

qmp_command_tabcomplete_biomes:
    type: procedure
    debug: false
    script:
        - define biomes:<list[]>
        - foreach <server.biome_types>:
            - define biomes:->:<[value].name>
        - determine <[biomes]>
