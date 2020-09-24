qmw_trait_flightmaster:
    type: world
    events:
        on load:
            - run qm_npc.trait.register def:flightmaster|qm_trait_flightmaster_events
            - run qm_command.add.command def:qm_flightmaster_cmd|flightpath|developer
            - run qmw_trait_flightmaster.yaml.load

        on save:
            - run qmw_trait_flightmaster.yaml.save
        
        on trait added flightmaster:
            - yaml id:flightmaster set flightmaster.npcs:->:<context.npc.id>
            - run qmw_trait_flightmaster.yaml.save
    
        on trait removed flightmaster:
            - yaml id:flightmaster set flightmaster.npcs:<-:<context.npc.id>
            - run qmw_trait_flightmaster.yaml.save

        on player drags in inventory:
            - if '<context.inventory.title.starts_with[Flights]>':
                - determine cancelled
        
        on player clicks in inventory:
            - if '<context.inventory.title.starts_with[Flights]>':
                - determine passively cancelled
                - if <inventory[flights_<player.uuid>].map_slots.get[<context.slot>].material.name||<empty>> != <empty>:
                    - if <context.clicked_inventory.title> != 'inventory':
                        - define lore:<inventory[flights_<player.uuid>].map_slots.get[<context.slot>].lore.get[1].after_last[/].split[^]||<empty>>
                        - if <[lore].size> == 2:
                            - define npc_id:<[lore].get[1]>
                            - define cost:<[lore].get[2]>
                            - if <player.money> >= <[cost]>:
                                - define target_location:<npc[<[npc_id]>].location||<empty>>
                                - if <[target_location]> != <empty>:
                                    - money take quantity:<[cost]>
                                    - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<player.money>]>
                                    - execute as_op 'dt ctravel <[target_location].x.round_down> <[target_location].y.round_down> <[target_location].z.round_down> <[target_location].world.name>'
                            - else:
                                - narrate <proc[qmp_language].context[not_enough_money|flightmaster]>
                - inventory close
        
        on player closes inventory:
            - if '<context.inventory.title.starts_with[Flights]>':
                - note remove as:flights_<player.uuid>

    yaml:
        load:
            - if <server.has_file[/serverdata/flightmaster.yml]>:
                - yaml load:/serverdata/flightmaster.yml id:flightmaster
            - else:
                - yaml create id:flightmaster

            - run qmw_trait_flightmaster.yaml.save

        save:
            - yaml savefile:/serverdata/flightmaster.yml id:flightmaster


qm_trait_flightmaster_events:
    type: task
    script:
        - define event_type:<[1]||<empty>>
        - define target_npc:<[2]||<empty>>
        - define target_player:<[3]||<empty>>

        - if <[event_type]> == click:
            - determine <list[qm_trait_flightmaster_item|qm_trait_flightmaster_shop]>


qm_trait_flightmaster_item:
    type: item
    material: dragon_head
    display name: <&d>Travel


qm_trait_flightmaster_shop:
    type: task
    script:
        - define flightpaths:<list[]>
        - define discovered:<yaml[<player.uuid>].read[flightmaster.discovered]||<list[]>>
        - define start_location:<player.flag[npc_engaged].as_npc.location>

        - foreach <yaml[flightmaster].read[flightmaster.npcs]>:
            - if <[discovered].contains[<[value]>]> && <[value]> != <player.flag[npc_engaged].as_npc.id||<empty>>:
                - define flightpaths:->:<[value]>
            
            - if !<[discovered].contains[<[value]>]> && <[value]> == <player.flag[npc_engaged].as_npc.id||<empty>>:
                - narrate <proc[qmp_language].context[flight_path_discovered|flightmaster]>
                - yaml id:<player.uuid> set flightmaster.discovered:->:<[value]>
                - run qm_player.yaml.save def:<player>

        - if <[flightpaths].size> > 0:
            - define slots:<map[]>
            - note "in@generic[size=45;title=Flights]" as:flights_<player.uuid>
            - inventory set d:in@flights_<player.uuid> o:<[slots]>

            - foreach <[flightpaths]>:
                - define slot_id:<[slots].keys.highest.add[1]||1>
                - define slots:<[slots].with[<[slot_id]>].as[qm_trait_flightmaster_item]>
                - inventory set d:in@flights_<player.uuid> slot:<[slot_id]> o:qm_trait_flightmaster_item
                
                - define target_location:<npc[<[value]>].location>
                - define region_id:<proc[qmp_region.find.list].context[<[target_location]>].get[1]||<empty>>
                - define region_name:<proc[qmp_region.get.title].context[<[region_id]>]>
                - define distance:<[target_location].distance[<[start_location]>].round_down.mul[4]>
                - define cost:<proc[qmp_server.format.money].context[<[distance]>]>
                
                - inventory adjust d:in@flights_<player.uuid> slot:<[slot_id]> 'lore:<&f><[region_name]>  - <[cost]><&0>/<[value]>^<[distance]>'

            - inventory open d:in@flights_<player.uuid>
        - else:
            - narrate <proc[qmp_language].context[no_flight_paths|flightmaster]>
        
        # - stop

        # - define flight_list:<yaml[flightmaster].list_keys[flightmaster.npcs.<player.flag[npc_engaged].as_npc.id>]||<list[]>>
        # - if <[flight_list].size> > 0:
        # - else:
        #     - narrate <proc[qmp_language].context[no_flight_paths|flightmaster]>

        # - stop

        # /dt ctravel <x> <y> <z> [world]

        # - define id:<[1]||null>
        # - choose <[id]>:
        #     - case flights:
        #         - narrate "<&6>-- Flight Master --<&nl>"

        #         - define flightpaths:<yaml[npc].list_keys[npcs.<player.flag[npc_engaged].as_npc.id>.flightpaths]||<list[]>>
        #         - if <[flightpaths].size> > 0:
        #             - foreach <[flightpaths]>:
        #                 - run qm_menu.add 'def:<map[title/<proc[traitp_flightmaster.flightpath.name].context[<[value]>]> <proc[qmp_server.format.money].context[<yaml[npc].read[npcs.<player.flag[npc_engaged].as_npc.id>.flightpaths.<[value]>]>]>|id/<[value]>|handler/trait_flightmaster_menu]>'
        #         - else:
        #             - narrate <proc[qmp_lang].context[<player||null>|no_flightpaths|trait_flightmaster]>

        #     - default:
        #         - define command:<proc[traitp_flightmaster.flightpath.command].context[<[id]>]>
        #         - if <[command]> != null:
        #             - if <player.money> >= <yaml[npc].read[npcs.<player.flag[npc_engaged].as_npc.id>.flightpaths.<[id]>]>:
        #                 - money take quantity:<yaml[npc].read[npcs.<player.flag[npc_engaged].as_npc.id>.flightpaths.<[id]>]>
        #                 - execute as_op <[command]>
        #             - else:
        #                 - narrate <proc[qmp_lang].context[<player||null>|money_not_enough|server]>
        #         - else:
        #             - narrate <proc[qmp_lang].context[<player||null>|unknown_flightpath|trait_flightmaster]>




# ironport:
#   name: Ironport
#   command: dt travel lighthouse
# scarlettville:
#   name: Scarlettville
#   command: dt travel scarletttown




# traitp_flightmaster:
#     type: procedure
#     script:
#         - determine null
    
#     flightpath:
#         name:
#             - determine <yaml[flightpaths].read[<[1]||null>.name]||null>
        
#         command:
#             - determine <yaml[flightpaths].read[<[1]||null>.command]||null>
            
qm_flightmaster_cmd:
    type: task
    script:
        - choose <[1].get[command]>:
            - case flightpath:
                - choose <[1].get[option]>:
                    - case add:
                        # - define region_id:<proc[qmp_region.find.list].context[<[1].get[player].location>].get[1]||<empty>>
                        # - if <[region_id]> != <empty>:
                        #     - if !<yaml[flightmaster].list_keys[flightmaster.paths].contains[<[region_id]>]>:

                        #     - else:
                        #         - narrate <proc[qmp_language].context[not_in_region|flightmaster]>
                        # - else:
                        - narrate <proc[qmp_language].context[not_in_region|flightmaster]>
                        
