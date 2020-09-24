qma_npc:
    type: assignment
    debug: false
    actions:
        on assignment:
            - trigger name:click state:true
            - trigger name:chat state:true
            - trigger name:proximity state:true

    interact scripts:
    - qmi_npc


qmi_npc:
    type: interact
    debug: false
    speed: 0
    steps:
        1:
            proximity trigger:
                entry:
                    script:
                        - define trait_list:<proc[qmp_npc.get.trait].context[<npc.id>]>
                        - event 'trait proximity entry' context:npc|<npc>|player|<player>
                        - foreach <[trait_list]||<list[]>>:
                            - event 'trait proximity entry <[value]>' context:npc|<npc>|player|<player>
                exit:
                    script:
                        - if <player.flag[npc_engaged]||<empty>> == <npc>:
                            - run qm_menu.close
                            - flag player npc_engaged:!

                        - define trait_list:<proc[qmp_npc.get.trait].context[<npc.id>]>
                        - event 'trait proximity exit' context:npc|<npc>|player|<player>
                        - foreach <[trait_list]||<list[]>>:
                            - event 'trait proximity exit <[value]>' context:npc|<npc>|player|<player>
            
            click trigger:
                script:
                    - define menu_list:<list[]>
                    - define greeting:true

                    - flag player npc_engaged:<npc>

                    - define trait_list:<proc[qmp_npc.get.trait].context[<npc.id>]||<list[]>>
                    - foreach <[trait_list]>:
                        - define callback:<yaml[npc_traits].read[<[value]>]||<empty>>
                        - if <[callback]> != <empty>:
                            - ~run <[callback]> def:click|<npc>|<player> save:result
                            - define determinations:<entry[result].created_queue.determination||<list[]>>
                            - if <[determinations].get[1]||<empty>> != <empty>:
                                - if <[determinations].get[1].starts_with[greeting:]>:
                                    - define greeting:<[determinations].get[1].after[greeting:]>
                                - else:
                                    - define menu_list:->:<[determinations].get[1]>
                    
                    - if <[menu_list].size> > 0:
                        - if <[menu_list].size> > 1:
                            - flag player npc_menu:<[menu_list]>
                            - note "in@generic[size=9;title=Menu]" as:menu_<player.uuid>
                            - define slots:<map[]>
                            - inventory set d:in@menu_<player.uuid> o:<[slots]>
                            
                            - foreach <[menu_list]>:
                                - define slot_id:<[slots].keys.highest.add[1]||1>
                                - define slots:<[slots].with[<[slot_id]>].as[<[value].get[1]>]>
                                - inventory set d:in@menu_<player.uuid> slot:<[slot_id]> o:<[value].get[1]>

                            - inventory open d:in@menu_<player.uuid>
                        - else:
                            - if <server.scripts.contains[<script[<[menu_list].get[1].as_list.get[2]||<empty>>]||<empty>>]>:
                                - run <[menu_list].get[1].as_list.get[2]>
                    - else if <[greeting]>:
                        - define greeting:<proc[qmp_npc.get.greeting].context[<npc>]||<element[...]>>
                        - narrate <proc[qmp_chat].context[<npc>|<[greeting]>]>


qm_npc_trait_exit:
    type: task
    script:
        - run qm_menu.close


qmw_npc:
    type: world
    debug: true
    events:
        on pre load:
            - run qm_npc.yaml.load
            - run qm_command.add.command def:qm_npc_cmd|npc|developer
            - run qm_command.add.tabcomplete def:npc|create
            
            - if <yaml.list.contains[npc_traits]>:
                - yaml unload id:npc_traits
            - yaml create id:npc_traits
        
            # the following cannot be in pre-load as skins is not ready
            # - foreach <yaml[npc].list_keys[npcs]>:
            #     - define skin:<yaml[npc].read[npcs.<[value]>.skins.default]||null>
            #     - if <[skin]> != null:
            #         - adjust <npc[<[value]>]> skin_blob:<yaml[skins].read[skins.<[skin]>]>
        
        on save:
            - run qm_npc.yaml.save

        on event started:
            - foreach <yaml[npc].list_keys[npcs]>:
                - define skin:<yaml[npc].read[npcs.<[value]>.skins.<context.event>]||null>
                - if <[skin]> != null:
                    - adjust <npc[<[value]>]> skin_blob:<yaml[skins].read[skins.<[skin]>]>
            

        on event finished:
            - foreach <yaml[npc].list_keys[npcs]>:
                - define skin:<yaml[npc].read[npcs.<[value]>.skins.default]||null>
                - if <[skin]> != null:
                    - adjust <npc[<[value]>]> skin_blob:<yaml[skins].read[skins.<[skin]>]>

        on player drags in inventory:
            - if <context.inventory.title> == 'Menu':
                - determine cancelled

        on player clicks in inventory:
            - if <context.inventory.title> == 'Menu':
                - if <context.clicked_inventory.title> != 'Inventory':
                    - determine passively cancelled
                    - define menu_list:<player.flag[npc_menu]||<list[]>>
                    - define script_name:<inventory[menu_<player.uuid>].map_slots.get[<context.slot>].script.name||null>
                    - inventory close
                    - foreach <[menu_list]>:
                        - if <[value].get[1]||<empty>> == <[script_name]> && <server.scripts.contains[<script[<[value].get[2]>]||<empty>>]>:
                            - run <[value].get[2]>
                            - stop
                
        on player closes inventory:
            - if <context.inventory.title> == "Menu":
                - note remove as:menu_<player.uuid>
                - flag player npc_menu:!


qm_npc:
    type: task
    debug: false
    script:
        - narrate 'invalid call to qm_npc'
    
    create:
        - define name:<[1]||<empty>>
        - define location:<[2]||<empty>>
        - if <[name]> != <empty>:
            - create player <[name]> <[location]> save:result
            - determine <entry[result].created_npc.id>
        
        - determine <empty>

    trait:
        register:
            - define trait_name:<[1]||null>
            - define callback:<[2]||null>

            - if <[callback]> != null && <[trait_name]> != null && <server.scripts.contains[<script[<[callback]>]>]||false>:
                - yaml id:npc_traits set <[trait_name]>:<[callback]>

        add:
            - define trait_name:<[1]||null>
            - define target_npc:<[2]||null>

            - if <[trait_name]> != null && <[target_npc].is_npc> && !<yaml[npc].read[npcs.<[target_npc].id>.traits].contains[<[trait_name]>]>:
                - yaml id:npc set npcs.<[target_npc].id>.traits:->:<[trait_name]>
                - run qm_npc.yaml.save


    yaml:
        load:
            - if <server.has_file[/serverdata/npc.yml]>:
                - yaml load:/serverdata/npc.yml id:npc
            - else:
                - yaml create id:npc

            - run qm_npc.yaml.save

        save:
            - yaml savefile:/serverdata/npc.yml id:npc
    

qmp_npc:
    type: procedure
    debug: false
    script:
        - determine null

    list:
        - determine <yaml[npc].list_keys[npcs]>
    
    exists:
        - determine false
    
    find:
        - determine -1
    
    get:
        name:
            - define npc_id:<[1]||<empty>>
            - if <[npc_id]> != <empty>:
                - determine <yaml[npc].read[npcs.<[npc_id]>.name]>
            
            - determine <empty>
        
        location:
            - define npc_id:<[1]||<empty>>
            - if <[npc_id]> != <empty>:
                - determine <yaml[npc].read[npcs.<[npc_id]>.location]>
            
            - determine <location[0,0,0,island]>
         
        trait:
            - define npc_id:<[1]||<empty>>
            - if <[npc_id]> != <empty>:
                - determine <yaml[npc].read[npcs.<[npc_id]>.trait]||<list[]>>
            
            - determine <list[]>


        greeting:
            - define target_npc:<[1]||<empty>>
            - if <[target_npc]> != <empty>:
                - define greetings:<yaml[npc].read[npcs.<[target_npc].id||0>.greetings.default]||<empty>>
                - if <[greetings]> == <empty>:
                    - define greetings:<yaml[npc].read[npcs.default.greetings.default]||<empty>>
                
                # <proc[qmp_events.get.yaml].context[npc|npcs.<[target_npc].id||null>.greetings.$EVENT$]||null>
                # - if <[greetings]> == null:
                #     - define greetings:<proc[qmp_events.get.yaml].context[npc|npcs.default.greetings.$EVENT$]||null>

                # - define greetings:<yaml[npc].read[npcs.<[target_npc].id||null>.greetings]||null>
                # - if <[greetings]> == null:
                #     - define greetings:<yaml[npc].read[npcs.default.greetings]||null>
                
                - if <[greetings]> != <empty>:
                    - determine <[greetings].get[<util.random.int[1].to[<[greetings].size>]>]>

            - determine ...


qm_npc_menu:
    type: task
    script:
        - define greeting:true
        - define target_npc:<player.flag[npc_engaged]>
        - define traits:<proc[qmp_npc.get.trait].context[<[target_npc].id>]||<list[]>>
        - foreach <[traits]>:
            - define callback:<yaml[npc_traits].read[<[value]>]||null>
            - if <[callback]> != null:
                - ~run <[callback]> def:click|<[target_npc]>|<player> save:result
                - define determinations:<entry[result].created_queue.determination||<list[]>>
                - foreach <[determinations]>:
                    - if <[value]> == 'greeting:false':
                        - define greeting:false

        - if <[greeting]>:
            - define greeting:<proc[qmp_npc.get.greeting].context[<[target_npc]>]>
            - if <[greeting]> != null:
                - narrate <proc[qmp_chat].context[<[target_npc].name.strip_color>|<[greeting]>]>
                - if <proc[qmp_menu.exists]>:
                    - narrate ' '

        - run qm_menu.add def:<map[title/Exit|id/exit|handler/qm_npc_trait_exit|key/x]>


# clean up commands to use above
qm_npc_cmd:
    type: task
    debug: true
    script:
        - choose <[1].get[command]>:
            - case npc:
                - choose <[1].get[option]>:
                    # list
                    - case list:
                        - define list:<list[]>
                        - foreach <yaml[npc].list_keys[npcs]||<list[]>>:
                            - define 'list:->:<yaml[npc].read[npcs.<[value]>.name]> (<[value]>)'

                        - if <[list].size> > 0:
                            - narrate '<[list].separated_by[, ]>'
                        - else:
                            - narrate <proc[qmp_language].context[no_npcs_found|npc]>

                    # create
                    - case create:
                        - define npc_name:<[1].get[args].get[1]||<empty>>
                        - if <[npc_name]> != <empty>:
                            - run qm_npc.create def:<[npc_name]>|<player.location> save:result
                            - define npc_id:<entry[result].created_queue.determination.get[1]||<empty>>
                            - if <[npc_id]> != <empty>:
                                - adjust <player> selected_npc:<npc[<[npc_id]>]>
                                - yaml id:npc set npcs.<[npc_id]>.name:<[npc_name]>
                                - yaml id:npc set npcs.<[npc_id]>.location:<player.location||<location[0,0,0,island]>>
                                - lookclose <npc[<[npc_id]>]> state:true
                                - assignment set script:qma_npc to:<npc[<[npc_id]>]>
                                - narrate <proc[qmp_language].context[npc_created|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[error_creating_npc|npc]>
                        - else:
                            - narrate <proc[qmp_language].context[name_not_entered|npc]>
                    
                    # remove
                    - case rem remove del delete:
                        - define npc_id:<[1].get[args].get[1]||<empty>>
                        - if <[npc_id]> != <empty>:
                            - if !<[npc_id].is_integer>:
                                - define npc_name:<[npc_id]>
                                - define npc_id:<empty>

                                - foreach <yaml[npc].list_keys[npcs]>:
                                    - if <yaml[npc].read[npcs.<[value]>.name]> == <[npc_name]>:
                                        - define npc_id:<[value]>
                                        - foreach stop
                                
                                - if <[npc_id]> == <empty>:
                                    - narrate <proc[qmp_language].context[npc_not_found|npc|<map[npc/<[npc_name]>].escaped>]>
                                    - stop
                            - else:
                                - define npc_name:<yaml[npc].read[npcs.<[npc_id]>.name]||unknown>

                            - remove <npc[<[npc_id]>]>
                            - yaml id:npc set npcs.<[npc_id]>:!
                            - narrate <proc[qmp_language].context[npc_removed|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                        - else:
                            - narrate <proc[qmp_language].context[npc_not_entered|npc]>
                    
                    # spawn
                    - case spawn:
                        # - define npc_id:<[1].get[player].selected_npc.id||<empty>>
                        - define npc_id:<[1].get[args].get[1]||<empty>>
                        - if <[npc_id]> != <empty>:
                            - define location:<[1].get[args].get[1]||<empty>>
                            - if !<[npc_id].is_integer>:
                                - define npc_name:<[npc_id]>
                                - define npc_id:<empty>

                                - foreach <yaml[npc].list_keys[npcs]>:
                                    - if <yaml[npc].read[npcs.<[value]>.name]> == <[npc_name]>:
                                        - define npc_id:<[value]>
                                        - foreach stop
                                
                                - if <[npc_id]> == <empty>:
                                    - narrate <proc[qmp_language].context[npc_not_found|npc|<map[npc/<[npc_name]>].escaped>]>
                                    - stop
                            - else:
                                - define npc_name:<yaml[npc].read[npcs.<[npc_id]>.name]||unknown>
                            
                            - if <yaml[npc].list_keys[npcs].contains[<[npc_id]>]||false> && <server.npcs.contains[<npc[<[npc_id]>]||<empty>]>]>:
                                - if <[location]> == <empty>:
                                    - define location:<yaml[npc].read[npcs.<[npc_id]>.location]||<location[0,0,0,island]>>
                                - else if <[location].is_player> || <[location].is_npc>:
                                    # todo player enters name, not direct object!
                                    - define location:<[location].location>
                                - else:
                                    - narrate <[location]>
                                    - narrate <proc[qmp_language].context[npc_spawn_location_bad|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                                    - stop

                                - spawn <npc[<[npc_id]>]> <[location]>
                                - narrate <proc[qmp_language].context[npc_spawned|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[npc_not_exist|npc]>
                        - else:
                            - narrate <proc[qmp_language].context[npc_not_entered|npc]>

                    # despawn
                    - case despawn:
                        - define npc_id:<[1].get[args].get[1]||<empty>>
                        - if <[npc_id]> != <empty>:
                            - if !<[npc_id].is_integer>:
                                - define npc_name:<[npc_id]>
                                - define npc_id:<empty>

                                - foreach <yaml[npc].list_keys[npcs]>:
                                    - if <yaml[npc].read[npcs.<[value]>.name]> == <[npc_name]>:
                                        - define npc_id:<[value]>
                                        - foreach stop
                                
                                - if <[npc_id]> == <empty>:
                                    - narrate <proc[qmp_language].context[npc_not_found|npc|<map[npc/<[npc_name]>].escaped>]>
                                    - stop
                            - else:
                                - define npc_name:<yaml[npc].read[npcs.<[npc_id]>.name]||unknown>
                            
                            - if <yaml[npc].list_keys[npcs].contains[<[npc_id]>]||false> && <server.npcs.contains[<npc[<[npc_id]>]||<empty>]>]>:
                                - despawn <npc[<[npc_id]>]>
                                - narrate <proc[qmp_language].context[npc_despawned|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[npc_not_exist|npc]>
                        - else:
                            - narrate <proc[qmp_language].context[npc_not_entered|npc]>

                    # move
                    - case move:
                        - define npc_id:<[1].get[args].get[1]||<empty>>
                        - if <[npc_id]> != <empty>:
                            - define location:<[1].get[args].get[2]||<empty>>
                            - if !<[npc_id].is_integer>:
                                - define npc_name:<[npc_id]>
                                - define npc_id:<empty>

                                - foreach <yaml[npc].list_keys[npcs]>:
                                    - if <yaml[npc].read[npcs.<[value]>.name]> == <[npc_name]>:
                                        - define npc_id:<[value]>
                                        - foreach stop
                                
                                - if <[npc_id]> == <empty>:
                                    - narrate <proc[qmp_language].context[npc_not_found|npc|<map[npc/<[npc_name]>].escaped>]>
                                    - stop
                            - else:
                                - define npc_name:<yaml[npc].read[npcs.<[npc_id]>.name]||unknown>
                            
                            - if <yaml[npc].list_keys[npcs].contains[<[npc_id]>]||false> && <server.npcs.contains[<npc[<[npc_id]>]||<empty>]>]>:
                                - if <[location]> == <empty>:
                                    - define location:<player.location>
                                    # - define location:<yaml[npc].read[npc.<[npc_id]>.location]||<location[0,0,0,island]>>
                                - else if <[location].is_player> || <[location].is_npc>:
                                    # todo player enters name, not direct object!
                                    - define location:<[location].location>
                                - else:
                                    - narrate <[location]>
                                    - narrate <proc[qmp_language].context[npc_spawn_location_bad|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                                    - stop

                                - yaml id:npc set npcs.<[npc_id]>.location:<[location]>
                                - teleport <npc[<[npc_id]>]> <[location]>
                                - narrate <proc[qmp_language].context[npc_moved|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[npc_not_exist|npc]>
                        - else:
                            - narrate <proc[qmp_language].context[npc_not_entered|npc]>

                    # rename
                    - case rename:
                        - define npc_id:<[1].get[player].selected_npc.id||<empty>>
                        - if <[npc_id]> != <empty>:
                            - define npc_new_name:<[1].get[args].get[1]||<empty>>
                            - if !<[npc_id].is_integer>:
                                - define npc_name:<[npc_id]>
                                - define npc_id:<empty>

                                - foreach <yaml[npc].list_keys[npcs]>:
                                    - if <yaml[npc].read[npcs.<[value]>.name]> == <[npc_name]>:
                                        - define npc_id:<[value]>
                                        - foreach stop
                                
                                - if <[npc_id]> == <empty>:
                                    - narrate <proc[qmp_language].context[npc_not_found|npc|<map[npc/<[npc_name]>].escaped>]>
                                    - stop
                            - else:
                                - define npc_name:<yaml[npc].read[npcs.<[npc_id]>.name]||unknown>
                            
                            - if <yaml[npc].list_keys[npcs].contains[<[npc_id]>]||false> && <server.npcs.contains[<npc[<[npc_id]>]||<empty>]>]>:
                                - if <[npc_new_name]> != <empty>:
                                    - yaml id:npc set npcs.<[npc_id]>.name:<[npc_new_name]>
                                    - rename <[npc_new_name]> t:<npc[<[npc_id]>]>
                                    - narrate <proc[qmp_language].context[npc_renamed|npc|<map[id/<[npc_id]>|npc/<[npc_name]>|newname/<[npc_new_name]>].escaped>]>
                                - else:
                                    - narrate <proc[qmp_language].context[npc_no_new_name|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[npc_not_exist|npc]>
                        - else:
                            - narrate <proc[qmp_language].context[npc_not_selected|npc]>

                    # trait
                    - case trait:
                        - define trait_option:<[1].get[args].get[1]||<empty>>
                        - define trait:<[1].get[args].get[2]||<empty>>
                        - define npc_id:<player.selected_npc.id||<empty>>
                        - define npc_name:<npc[<[npc_id]>].name||<empty>>
                        - define trait_list:<yaml[npc].read[npcs.<[npc_id]>.trait]||<list[]>>
                        
                        - choose <[trait_option]>:
                            - case list <empty>:
                                - if <[trait_list].size> > 0:
                                    - narrate '<[trait_list].separated_by[, ]>'
                                - else:
                                    - narrate <proc[qmp_language].context[npc_no_traits|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                            - case add:
                                - if <[trait]> != <empty>:
                                    - if !<[trait_list].contains[<[trait]>]>:
                                        - ~yaml id:npc set npcs.<[npc_id]>.trait:->:<[trait]>
                                        - run qm_npc.yaml.save

                                    - narrate <proc[qmp_language].context[npc_no_trait_added|npc|<map[id/<[npc_id]>|npc/<[npc_name]>|trait/<[trait]>].escaped>]>
                                    
                                    - event 'trait added' context:trait|<[trait]>|npc|<player.selected_npc>
                                    - event 'trait added <[trait]>' context:trait|<[trait]>|npc|<player.selected_npc>
                                - else:
                                    - narrate <proc[qmp_language].context[npc_no_trait_entered|npc]>
                            - case rem remove del delete:
                                - if <[trait]> != <empty>:
                                    - if <[trait_list].contains[<[trait]>]>:
                                        - ~yaml id:npc set npcs.<[npc_id]>.trait:<-:<[trait]>
                                        - run qm_npc.yaml.save

                                    - narrate <proc[qmp_language].context[npc_no_trait_removed|npc|<map[id/<[npc_id]>|npc/<[npc_name]>|trait/<[trait]>].escaped>]>

                                    - event 'trait removed' context:trait|<[trait]>|npc|<player.selected_npc>
                                    - event 'trait removed <[trait]>' context:trait|<[trait]>|npc|<player.selected_npc>
                                - else:
                                    - narrate <proc[qmp_language].context[npc_no_trait_entered|npc]>
                    
                    # select
                    - case select:
                        - define npc_id:<[1].get[args].get[1]||<empty>>
                        - if <[npc_id]> != <empty>:
                            - if !<[npc_id].is_integer>:
                                - define npc_name:<[npc_id]>
                                - define npc_id:<empty>

                                - foreach <yaml[npc].list_keys[npcs]>:
                                    - if <yaml[npc].read[npcs.<[value]>.name]> == <[npc_name]>:
                                        - define npc_id:<[value]>
                                        - foreach stop
                                
                                - if <[npc_id]> == <empty>:
                                    - narrate <proc[qmp_language].context[npc_not_found|npc|<map[npc/<[npc_name]>].escaped>]>
                                    - stop
                            - else:
                                - define npc_name:<yaml[npc].read[npcs.<[npc_id]>.name]||unknown>
                            
                            - if <yaml[npc].list_keys[npcs].contains[<[npc_id]>]||false> && <server.npcs.contains[<npc[<[npc_id]>]||<empty>]>]>:
                                - adjust <player> selected_npc:<npc[<[npc_id]>]>
                                - narrate <proc[qmp_language].context[npc_selected|npc|<map[id/<[npc_id]>|npc/<[npc_name]>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[npc_not_exist|npc]>
                        - else:
                            - define closest_npc:<player.location.find.npcs.within[10].get[1]||<empty>>
                            - if <[closest_npc].is_npc>:
                                - adjust <player> selected_npc:<[closest_npc]>
                                - narrate <proc[qmp_language].context[npc_selected|npc|<map[id/<[closest_npc].id>|npc/<[closest_npc].name>].escaped>]>
                            - else:
                                - narrate <proc[qmp_language].context[no_npcs_found|npc]>
                    
                    # import
                    - case import:
                        - define npc_id:<player.selected_npc.id||<empty>>
                        - if <[npc_id]> != <empty>:
                            - if !<[npc_id].is_integer>:
                                - narrate <proc[qmp_language].context[npc_import_requires_id|npc]>
                                - stop
                            - else:
                                # - if !<yaml[npc].list_keys[npc].contains[<[npc_id]>]||false>:
                                - if <server.npcs.contains[<npc[<[npc_id]>]||<empty>]>]>:
                                    - define target_npc:<npc[<[npc_id]>]>
                                    - yaml id:npc set npcs.<[npc_id]>.name:<[target_npc].name>
                                    - yaml id:npc set npcs.<[npc_id]>.location:<[target_npc].location>
                                    - lookclose <[target_npc]> state:true
                                    - assignment set script:qma_npc to:<[target_npc]>
                                    - narrate <proc[qmp_language].context[npc_imported|npc]>
                                - else:
                                    - narrate <proc[qmp_language].context[npc_not_exist|npc]>
                                # - else:
                                #     - narrate <proc[qmp_language].context[npc_already_imported|npc]>
                            - else:
                                - narrate <proc[qmp_language].context[npc_not_exist|npc]>
                        - else:
                            - narrate <proc[qmp_language].context[npc_not_entered|npc]>
                            #todo this should be no npc selected
                    
                    - run qm_npc.yaml.save


















        # - choose <[action]>:
        #     - case npc:
        #         - choose <[option]>:
        #             - case test:
        #                 - narrate here

        #                 # - narrate action:<[action]>
        #                 # - narrate option:<[value]>
        #                 # - narrate value:<[value]>

        #             - case create:
        #                 - if <[value]> != null:
        #                     - if <[value]> == guard:
        #                         - define region_id:<proc[qmp_region.find.id].context[<player.location>]>
        #                         - define region_name:<proc[qmp_region.get.name].context[<[region_id]>]>
        #                         - define 'value:<[region_name]> Guard'
        #                         - create player <&2><[value]> <player.location> save:saved_npc
        #                         - lookclose <entry[saved_npc].created_npc> state:true
        #                         - assignment set script:qma_npc to:<entry[saved_npc].created_npc>
        #                         - adjust <player> selected_npc:<entry[saved_npc].created_npc>
        #                         - trait state:true sentinel to:<entry[saved_npc].created_npc>
        #                         - give crossbow to:<entry[saved_npc].created_npc.inventory>
        #                         - give diamond_sword to:<entry[saved_npc].created_npc.inventory>
        #                         - execute as_op 'sentinel addtarget monsters'
        #                         - execute as_op 'sentinel addtarget event:pvp'
        #                         - execute as_op 'sentinel addtarget event:pvsentinel'
        #                         - execute as_op 'sentinel spawnpoint'
        #                         - execute as_op 'sentinel removeignore owner'
        #                         - adjust <entry[saved_npc].created_npc> skin_blob:<yaml[skins].read[skins.guard]>
        #                         - narrate <proc[qmp_lang].context[<player||null>|npc_created|npc|<map[name/<[value].escaped>]>]>
        #                     - else:
        #                         - create player <[value]> <player.location> save:saved_npc
        #                         - lookclose <entry[saved_npc].created_npc> state:true
        #                         - assignment set script:qma_npc to:<entry[saved_npc].created_npc>
        #                         - adjust <player> selected_npc:<entry[saved_npc].created_npc>
        #                         - narrate <proc[qmp_lang].context[<player||null>|npc_created|npc|<map[name/<[value].escaped>]>]>
        #                 - else:
        #                     - narrate 'xxno name entered'
        #             - case manage:
        #                 - assignment set script:qma_npc
        #                 - narrate <proc[qmp_lang].context[<player||null>|npc_managed|npc|<map[npc/<player.selected_npc.name>]>]>
        #             - case traitlist:
        #                 - foreach <yaml[npc].read[npcs.<player.selected_npc.id>.traits]||<list[]>>:
        #                     - narrate '- <[value]>'
        #             - case traitadd:
        #                 - if <[value]> != null:
        #                     - if <yaml[npc].read[npcs.<player.selected_npc.id>.traits].contains[<[value]>]||false> == false:
        #                         - yaml id:npc set npcs.<player.selected_npc.id>.traits:->:<[value]>
        #                         - run qm_npc.yaml.save
        #                         - narrate <proc[qmp_lang].context[<player||null>|npc_trait_added|npc|<map[npc/<player.selected_npc.name>|trait/<[value]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_lang].context[<player||null>|npc_trait_not_exist|npc|<map[trait/<[value]>|npc/<player.selected_npc.name>].escaped>]>
        #                 - else:
        #                     - narrate <proc[qmp_lang].context[<player||null>|npc_trait_missing|npc|<map[npc/<player.selected_npc.name>]>]>
        #             - case traitdel:
        #                 - if <[value]> != null:
        #                     - if <yaml[npc].read[npcs.<player.selected_npc.id>.traits].contains[<[value]>]||false> != false:
        #                         - yaml id:npc set npcs.<player.selected_npc.id>.traits:<-:<[value]>
        #                         - run qm_npc.yaml.save
        #                         - narrate <proc[qmp_lang].context[<player||null>|npc_trait_added|npc|<map[npc/<player.selected_npc.name>|trait/<[value]>]>]>
        #                     - else:
        #                         - narrate <proc[qmp_lang].context[<player||null>|npc_trait_exists|npc|<map[trait/<[value]>|npc/<player.selected_npc.name>].escaped>]>
        #                 - else:
        #                     - narrate <proc[qmp_lang].context[<player||null>|npc_trait_missing|npc|<map[npc/<player.selected_npc.name>]>]>
        #             - case select:
        #                 - if <player.location.find.npcs.within[10].size> > 0:
        #                     - adjust <player> selected_npc:<player.location.find.npcs.within[10].first>
        #                     - narrate <proc[qmp_lang].context[<player||null>|npc_selected|npc|<map[npc/<player.selected_npc.name>|id/<player.selected_npc.id>].escaped>]>
        #                 - else:
        #                     - narrate <proc[qmp_lang].context[<player||null>|npc_no_selected|npc]>
        #             - case selected:
        #                 - if <player.selected_npc||null> != null:
        #                     - narrate <proc[qmp_lang].context[<player||null>|npc_selected|npc|<map[npc/<player.selected_npc.name>|id/<player.selected_npc.id>].escaped>]>
        #                 - else:
        #                     - narrate <proc[qmp_lang].context[<player||null>|npc_no_selected|npc]>







# qm_npc_interact:
#   type: interact
#   speed: 0
#   steps:
#     1:
#         proximity trigger:
#             entry:
#                 script:
#                     - foreach <yaml[npc].read[<npc.id>.traits]||<list[]>>:
#                         - if <script[npc_trait_<[value]>].list_deep_keys[].contains[proximity.entry]||false>:
#                             - run npc_trait_<[value]>.proximity.entry def:<npc>|<player>

#             exit:
#                 script:
#                     - foreach <yaml[npc].read[<npc.id>.traits]||<list[]>>:
#                         - if <script[npc_trait_<[value]>].list_deep_keys[].contains[proximity.exit]||false>:
#                             - run npc_trait_<[value]>.proximity.exit def:<npc>|<player>

#         click trigger:
#             script:
#                 - ~run qm_npc_menu def:null|<npc>
#                 # greeting
#                 # - if <yaml[server].contains[npcs.<npc.id>.greetings]>:
#                 #     - define greetings:<yaml[server].read[npcs.<npc.id>.greetings]>
#                 # - else:
#                 #     - define greetings:<yaml[server].read[npc.greetings]>
                    
#                 # - narrate format:npc <[greetings].get[<util.random.int[1].to[<[greetings].size>]>]>

#                 # npc menu
#                 # - ~run qm_npc_menu_handler def:<npc>


#         # chat trigger:
#         #     1:
#         #         trigger: /*/
#         #         hide trigger message: true
#         #         script:
#         #         - ~run qm_npc_menu_handler def:<npc>|<context.message>
                
#                 #- if <player.flag[npc_engage.npc]> == <npc.id>:
#                 #    - 
#                 #- else:
#                 # - define actions:<yaml[server].read[npc.unknown_chat]>
#                 # - define action:<[actions].get[<util.random.int[1].to[<[actions].size>]>]>
#                 # - if <[action].starts_with[*]>:
#                 #     - narrate format:npc_action <[action].after_last[*]>
#                 # - else:
#                 #     - narrate format:npc <[action]>
