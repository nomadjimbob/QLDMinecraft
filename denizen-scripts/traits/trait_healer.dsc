qmw_trait_healer:
    type: world
    events:
        on load:
            - run qm_npc.trait.register def:healer|qm_trait_healer_events

        on player drags in inventory:
            - if '<context.inventory.title.starts_with[Healer]>':
                - determine cancelled
        
        on player clicks in inventory:
            - if '<context.inventory.title.starts_with[Healer]>':
                - determine passively cancelled
                - if <inventory[healer_<player.uuid>].map_slots.get[<context.slot>].material.name||<empty>> != <empty>:
                    - if <context.clicked_inventory.title> != 'inventory':
                        - define lore:<inventory[healer_<player.uuid>].map_slots.get[<context.slot>].lore.get[1].after_last[/]||<empty>>
                        - if <[lore]> != <empty>:
                            - if <player.money> >= <[lore].mul[100]>:
                                - heal <[lore]>
                                - narrate <proc[qmp_language].context[healed|healer|<map[amount/<[lore]>].escaped>]>
                                - inventory close
                            - else:
                                - narrate <proc[qmp_language].context[not_enough_money|healer]>
                - inventory close
        
        on player closes inventory:
            - if '<context.inventory.title.starts_with[Healer]>':
                - note remove as:healer_<player.uuid>


qm_trait_healer_events:
    type: task
    script:
        - define event_type:<[1]||<empty>>
        - define target_npc:<[2]||<empty>>
        - define target_player:<[3]||<empty>>

        - if <[event_type]> == click:
            - determine <list[qm_trait_healer_item|qm_trait_healer_shop]>


qm_trait_healer_item:
    type: item
    material: potion
    display name: <&d>Heal


qm_trait_healer_shop:
    type: task
    script:
            - define slots:<map[]>
            - note "in@generic[size=9;title=Healer]" as:healer_<player.uuid>
            - inventory set d:in@healer_<player.uuid> o:<[slots]>

            - inventory set d:in@healer_<player.uuid> slot:1 o:qm_trait_healer_item
            - inventory adjust d:in@healer_<player.uuid> slot:1 'lore:<&f>Heal 5 HP  - <proc[qmp_server.format.money].context[500]><&0>/5'
            - inventory set d:in@healer_<player.uuid> slot:2 o:qm_trait_healer_item
            - inventory adjust d:in@healer_<player.uuid> slot:2 'lore:<&f>Heal 10 HP  - <proc[qmp_server.format.money].context[1000]><&0>/10'
            - inventory set d:in@healer_<player.uuid> slot:3 o:qm_trait_healer_item
            - inventory adjust d:in@healer_<player.uuid> slot:3 'lore:<&f>Heal 20 HP  - <proc[qmp_server.format.money].context[2000]><&0>/20'
            - inventory set d:in@healer_<player.uuid> slot:4 o:qm_trait_healer_item
            - inventory adjust d:in@healer_<player.uuid> slot:4 'lore:<&f>Heal 50 HP  - <proc[qmp_server.format.money].context[5000]><&0>/50'
            - inventory set d:in@healer_<player.uuid> slot:5 o:qm_trait_healer_item
            - inventory adjust d:in@healer_<player.uuid> slot:5 'lore:<&f>Heal 100 HP  - <proc[qmp_server.format.money].context[10000]><&0>/100'
                
                # - define target_location:<npc[<[value]>].location>
                # - define region_id:<proc[qmp_region.find.list].context[<[target_location]>].get[1]||<empty>>
                # - define region_name:<proc[qmp_region.get.title].context[<[region_id]>]>
                # - define distance:<[target_location].distance[<[start_location]>].round_down.mul[4]>
                # - define cost:
                
                

            - inventory open d:in@healer_<player.uuid>
