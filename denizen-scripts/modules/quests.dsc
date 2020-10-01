qmw_quest:
    type: world
    debug: true
    events:
        on load:
            - run qm_quest.yaml.load
            - run qm_npc.trait.register def:quests|qm_quest_trait_events

            - run qm_command.add.command def:qm_quests_cmd|quests|developer
            - run qm_command.add.tabcomplete def:quests|create
            - run qm_command.add.tabcomplete def:quests|list
            - run qm_command.add.tabcomplete def:quests|listnpc
        
        on player drags in inventory:
            - if '<list[Quests|My Quests].contains[<context.inventory.title>]>':
                - determine cancelled

        on player clicks in inventory:
            - if '<list[Quests|My Quests].contains[<context.inventory.title>]>':
                - determine passively cancelled
                - if <context.clicked_inventory.title> != 'inventory':
                    - define quest_id:<inventory[quests_<player.uuid>].map_slots.get[<context.slot>].lore.get[1].after_last[/]||<empty>>
                    - define type:<inventory[quests_<player.uuid>].map_slots.get[<context.slot>].script.name||<empty>>
                    - if <[quest_id]> != <empty>:
                        - if <[type]> == questbook:
                            - if <context.inventory.title> == Quests:
                                - run qm_quest.player.accept def:<player>|<[quest_id]>
                            - else:
                                - run qm_quest.player.abandon def:<player>|<[quest_id]>
                        - else if <[type]> == questbookcomplete:
                            - if <context.inventory.title> == Quests:
                                - run qm_quest.player.close def:<player>|<[quest_id]>
                            - else:
                                - run qm_quest.player.abandon def:<player>|<[quest_id]>
                    
                    - inventory close
                                
        on player closes inventory:
            - if '<list[Quests|My Quests].contains[<context.inventory.title>]>':
                - note remove as:quests_<player.uuid>


        on player places block:
            - define quest_list:<proc[qmp_quest.player.list.active].context[<player>]>
            - foreach <[quest_list]>:
                - define quest_id:<[value]>
                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
                    - define objective_id:<[value]>

                    - if <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]||<empty>> == 'block_place':
                        - define placed_material:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.material]||<empty>>
                        - if  <[placed_material]> == <context.material.name> || <[placed_material]> == '*':
                            - define objective_region_id:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.region]||<empty>>

                            - if <[objective_region_id]> == <empty> || <proc[qmp_region.in_region].context[<context.location>|<[objective_region_id]>]>:
                                - yaml id:<player.uuid> set quests.active.<[quest_id]>.objectives.<[objective_id]>.quantity:++
                                - if <proc[qmp_quest.player.quest_complete].context[<player>|<[quest_id]>]>:
                                    - narrate <proc[qmp_language].context[quest_done|quest|<map[title/<yaml[quests].read[quests.<[quest_id]>.title]>]>]>

        on player breaks block:
            - define quest_list:<proc[qmp_quest.player.list.active].context[<player>]>
            - foreach <[quest_list]>:
                - define quest_id:<[value]>
                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
                    - define objective_id:<[value]>

                    - if <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]||<empty>> == 'block_break':
                        - define break_material:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.material]||<empty>>
                        - if  <[break_material]> == <context.material.name> || <[break_material]> == '*':
                            - define objective_region_id:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.region]||<empty>>
                            
                            - if <[objective_region_id]> == <empty> || <proc[qmp_region.in_region].context[<context.location>|<[objective_region_id]>]>:
                                - yaml id:<player.uuid> set quests.active.<[quest_id]>.objectives.<[objective_id]>.quantity:++
                                - if <proc[qmp_quest.player.quest_complete].context[<player>|<[quest_id]>]>:
                                    - narrate <proc[qmp_language].context[quest_done|quest|<map[title/<yaml[quests].read[quests.<[quest_id]>.title]>]>]>
        
        # on player drops item:
        #     - run qmw_quest.update def:<player>

        after entity picks up item:
            - if <context.pickup_entity.is_player>:
                - define quest_list:<proc[qmp_quest.player.list.active].context[<player>]>
                - foreach <[quest_list]>:
                    - define quest_id:<[value]>
                    - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
                        - define objective_id:<[value]>

                        - if <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]||<empty>> == 'give':
                            - narrate <context.item.material.name>
                            - if <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.material]||<empty>> == <context.item.material.name>:
                                - define objective_region_id:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.region]||<empty>>
                                
                                - if <[objective_region_id]> == <empty> || <proc[qmp_region.in_region].context[<context.location>|<[objective_region_id]>]>:
                                    - if <proc[qmp_quest.player.quest_complete].context[<player>|<[quest_id]>]>:
                                        - narrate <proc[qmp_language].context[quest_done|quest|<map[title/<yaml[quests].read[quests.<[quest_id]>.title]>]>]>
        




    # update:
    #     - stop
        # - define target_player:<[1]||null>
        # - foreach <yaml[<[target_player].uuid>].list_keys[quests.active]||<list[]>>:
        #     - define quest_id:<[value]>
        #     - define quest_title:<yaml[quests].read[quests.<[quest_id]>.title]>
        #     - define quest_completed:true
            
        #     - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
        #         - define objective_id:<[value]>
        #         - choose <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]||null>:
        #             - case break_block place_block:
        #                 - if <yaml[<[target_player].uuid>].read[quests.active.<[quest_id]>.objectives.<[objective_id]>.quantity]> < <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.quantity]>:
        #                     - define quest_completed:false
        #                     - foreach stop
        #             - case give:
        #                 - define target_material:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.material]||null>
        #                 - define target_quantity:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.quantity]||0>
        #                 - define quantity_have:0

        #                 - foreach <player.inventory.map_slots.values>:
        #                     - if <[value].material.name> == <[target_material]>:
        #                         - define quantity_have:+:<[value].quantity>
                        
        #                 - if <[quantity_have]> < <[target_quantity]>:
        #                     - define quest_completed:false
        #                     - foreach stop
                            
        #             - default:
        #                 - define quest_completed:false
        #                 - foreach stop
            
        #     - if <[quest_completed]> == true:
        #         - if !<yaml[<[target_player].uuid>].read[quests.active.<[quest_id]>.done]||false>:
        #             - yaml id:<[target_player].uuid> set quests.active.<[quest_id]>.done:true
        #             - narrate 'xxQuest <[quest_title]> Done'
        #     - else:
        #         - if <yaml[<[target_player].uuid>].read[quests.active.<[quest_id]>.done]||false>:
        #             - yaml id:<[target_player].uuid> set quests.active.<[quest_id]>.done:false
                    # - yaml id:<[target_player].uuid> set quests.active.<[quest_id]>:!
                    # - narrate 'xxQuest <[quest_title]> Abandoned'

                # - yaml id:<[target_player].uuid> copykey:quests.active.<[quest_id]> quests.completed.<[quest_id]>
                # - yaml id:<[target_player].uuid> set quests.completed.<[quest_id]>.ended:<util.time_now.epoch_millis>
                # - yaml id:<[target_player].uuid> set quests.completed.<[quest_id]>.objectives:!
                # - yaml id:<[target_player].uuid> set quests.active.<[quest_id]>:!
                

qm_quest:
    type: task
    script:
        - determine <empty>
    
    yaml:
        load:
            - if <server.has_file[/serverdata/quests.yml]>:
                - yaml load:/serverdata/quests.yml id:quests
            - else:
                - yaml create id:quests

            - run qm_quest.yaml.save

        save:
            - yaml savefile:/serverdata/quests.yml id:quests
    
    player:
        accept:
            - define target_player:<[1]||<empty>>
            - define quest_id:<[2]||<empty>>
            - define announce:<[3]||true>

            - if <[quest_id].is_integer> && <[target_player].is_player>:
                - yaml id:<[target_player].uuid> set quests.active.<[quest_id]>.start_time:<util.time_now.epoch_millis>
                - if <[announce]>:
                    - narrate <proc[qmp_language].context[quest_accepted|quest|<map[title/<yaml[quests].read[quests.<[quest_id]>.title]>].escaped>]>

                    - define npc_text:<yaml[quests].read[quests.<[quest_id]>.npc_start_speak]||<empty>>
                    - if <[npc_text]> != <empty>:
                        - narrate <&nl><proc[qmp_chat].context[<npc[<yaml[quests].read[quests.<[quest_id]>.npc_start]||0>]||<empty>>|<[npc_text]>|<map[name/<[target_player].name>].escaped>]><&nl>
                
                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.give]||<list[]>>:
                    - define quantity:<yaml[quests].read[quests.<[quest_id]>.give.<[value]>]>
                    - give <[value]> quantity:<[quantity]>
                    - if <[announce]>:
                        - define item:<[value].to_titlecase>
                        - if <[quantity]> > 1:
                            - define 'item:<[item]> (<[quantity]>)'
                        - narrate <proc[qmp_language].context[quest_received|quest|<map[item/<[item]>].escaped>]>

        
        abandon:
            - define target_player:<[1]||<empty>>
            - define quest_id:<[2]||<empty>>
            - define announce:<[3]||true>

            - if <[quest_id].is_integer> && <[target_player].is_player>:
                - yaml id:<[target_player].uuid> set quests.active.<[quest_id]>:!
                - if <[announce]>:
                    - narrate <proc[qmp_language].context[quest_abandoned|quest|<map[title/<yaml[quests].read[quests.<[quest_id]>.title]>].escaped>]>

        close:
            - define target_player:<[1]||<empty>>
            - define quest_id:<[2]||<empty>>
            - define announce:<[3]||true>

            - if <[quest_id].is_integer> && <[target_player].is_player>:
                - yaml id:<[target_player].uuid> set quests.complete.<[quest_id]>.start_time:<yaml[<[target_player].uuid>].read[quests.active.<[quest_id]>.start_time]>
                - yaml id:<[target_player].uuid> set quests.complete.<[quest_id]>.end_time:<util.time_now.epoch_millis>
                - yaml id:<[target_player].uuid> set quests.active.<[quest_id]>:!

                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
                    - define objective_id:<[value]>
                    - choose <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]>:
                        - case give:
                            - take <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.material]> quantity:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.material]> from:<[target_player]>

                - if <[announce]>:
                    - narrate <proc[qmp_language].context[quest_completed|quest|<map[title/<yaml[quests].read[quests.<[quest_id]>.title]>].escaped>]>

                - define money:<yaml[quests].read[quests.<[quest_id]>.rewards.money]||0>
                - if <[money]> > 0:
                    - money give quantity:<[money]>
                    - if <[announce]>:
                        - define item:<proc[qmp_server.format.money].context[<[money]>]>
                        - narrate <proc[qmp_language].context[quest_received|quest|<map[item/<[item]>].escaped>]>
                
                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.rewards.materials]||<list[]>>:
                    - define quantity:<yaml[quests].read[quests.<[quest_id]>.rewards.materials.<[value]>]>
                    - give <[value]> quantity:<[quantity]>
                    - if <[announce]>:
                        - define item:<[value].to_titlecase>
                        - if <[quantity]> > 1:
                            - define 'item:<[item]> (<[quantity]>)'
                        - narrate <proc[qmp_language].context[quest_received|quest|<map[item/<[item]>].escaped>]>
                
                - if <[announce]>:
                    - define npc_text:<yaml[quests].read[quests.<[quest_id]>.npc_end_speak]||<empty>>
                    - if <[npc_text]> != <empty>:
                        - narrate <&nl><proc[qmp_chat].context[<npc[<yaml[quests].read[quests.<[quest_id]>.npc_end]||0>]||<empty>>|<[npc_text]>|<map[name/<[target_player].name>].escaped>]><&nl>



qmp_quest:
    type: procedure
    script:
        - determine <empty>
    
    list:
        - determine <yaml[quests].list_keys[quests]>
    
    player:
        list:
            available:
                - define target_player:<[1]||<empty>>
                - define target_npc:<[2]||<empty>>
                - define quest_list:<list[]>

                - if <[target_player].is_player> && <[target_npc].is_npc>:
                    - foreach <yaml[quests].list_keys[quests]>:
                        - define quest_id:<[value]>

                        - if <yaml[quests].read[quests.<[quest_id]>.npc_start]||0> == <[target_npc].id> && !<yaml[<[target_player].uuid>].list_keys[quests.active].contains[<[quest_id]>]||false> && !<yaml[<[target_player].uuid>].list_keys[quests.complete].contains[<[quest_id]>]||false>:
                            - define quest_list:->:<[quest_id]>

                - determine <[quest_list]>

            active:
                - define target_player:<[1]||<empty>>
                - define quest_list:<list[]>

                - if <[target_player]> != <empty>:
                    - foreach <yaml[<[target_player].uuid>].list_keys[quests.active]||<list[]>>:
                        - define quest_id:<[value]>

                        - if !<proc[qmp_quest.player.quest_complete].context[<[target_player]>|<[quest_id]>]>:
                            - define quest_list:->:<[quest_id]>

                - determine <[quest_list]>

            completed:
                - define target_player:<[1]||<empty>>
                - define target_npc:<[2]||<empty>>
                - define quest_list:<list[]>

                - if <[target_player]> != <empty>:
                    - foreach <yaml[<[target_player].uuid>].list_keys[quests.active]||<list[]>>:
                        - define quest_id:<[value]>

                        - if <proc[qmp_quest.player.quest_complete].context[<[target_player]>|<[quest_id]>]>:
                            - if !<[target_npc].is_npc> || <yaml[quests].read[quests.<[quest_id]>.npc_end]||0> == <[target_npc].id>:
                                - define quest_list:->:<[quest_id]>

                - determine <[quest_list]>

            closed:
                - define target_player:<[1]||<empty>>

                - if <[target_player]> != <empty>:
                    - determine <yaml[<[target_player].uuid>].list_keys[quests.closed]||<list[]>>

                - determine <list[]>
        
        quest_complete:
            - define target_player:<[1]||<empty>>
            - define quest_id:<[2]||<empty>>

            - if <[target_player].is_player> && <[quest_id]> != <empty>:
                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
                    - define objective_id:<[value]>

                    - choose <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.type]>:
                        - case block_break block_place:
                            - if <yaml[<[target_player].uuid>].read[quests.active.<[quest_id]>.objectives.<[objective_id]>.quantity]||0> < <yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.quantity]||0>:
                                - determine false
                        - case give:
                            - define material:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.material]>
                            - define quantity:<yaml[quests].read[quests.<[quest_id]>.objectives.<[objective_id]>.quantity]>

                            - if !<[target_player].inventory.contains.material[<[material]>].quantity[<[quantity]>]>:
                                - determine false

                - determine true

            - determine false
        
    lore:
        - define target_player:<[1]||<empty>>
        - define quest_id:<[2]||<empty>>
        - define player_menu:<[3]||false>

        - if <[target_player]> != <empty> && <[quest_id]> != <empty>:
            - define 'title:<&e><yaml[quests].read[quests.<[quest_id]>.title]> <&0>/<[quest_id]>'
            - define description:<&f><yaml[quests].read[quests.<[quest_id]>.description].split_lines[40].replace_text[<&nl>].with[<&nl><&f>]||<empty>><&nl>
            - define 'objectives:<&3>Objectives:<&nl>'
            - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]>:
                - choose <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.type]>:
                    - case block_break:
                        - define quantity:<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]>
                        - if <[player_menu]>:
                            - define quantity:<yaml[<[target_player].uuid>].read[quests.active.<[quest_id]>.objectives.<[value]>.quantity]||0>/<[quantity]>

                        - define material:<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.material].to_titlecase>
                        - if <[material]> == '*':
                            - define material:Blocks
                        - else:
                            - define 'material:<[material]> blocks'

                        - define 'objectives:<[objectives]><&f>  - Break <[quantity]> <[material]> at <proc[qmp_region.get.title].context[<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.region]>]><&nl>'
                    - case block_place:
                        - define quantity:<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]>
                        - if <[player_menu]>:
                            - define quantity:<yaml[<[target_player].uuid>].read[quests.active.<[quest_id]>.objectives.<[value]>.quantity]||0>/<[quantity]>

                        - define material:<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.material].to_titlecase>
                        - if <[material]> == '*':
                            - define material:Blocks
                        - else:
                            - define 'material:<[material]> blocks'

                        - define 'objectives:<[objectives]><&f>  - Place <[quantity]> <[material]> at <proc[qmp_region.get.title].context[<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.region]>]><&nl>'
                    - case give:
                        - define 'objectives:<[objectives]><&f>  - Give <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.material]> to <npc[<yaml[quests].read[quests.<[quest_id]>.npc_end]>].name><&nl>'
            - define 'rewards:<&3>Rewards:<&nl>'
            - if <yaml[quests].read[quests.<[quest_id]>.rewards.money]||0> > 0:
                - define 'rewards:<[rewards]><&f>  - <proc[qmp_server.format.money].context[<yaml[quests].read[quests.<[quest_id]>.rewards.money]>]><&nl>'
            - foreach <yaml[quests].list_keys[quests.<[quest_id]>.rewards.materials]||<list[]>>:
                - define 'rewards:<[rewards]><&f>  - <yaml[quests].read[quests.<[quest_id]>.rewards.materials.<[value]>]> <[value]><&nl>'
            
            - if <yaml[<[target_player].uuid>].list_keys[quests.active].contains[<[quest_id]>]>:
                - if <[player_menu]>:
                    - define 'action:Click to abandon'
                - else:
                    - define 'action:Click to complete'
            - else if <yaml[<[target_player].uuid>].list_keys[quests.closed].contains[<[quest_id]>]>:
                - define action:<element[]>
            - else:
                - define 'action:Click to accept'

            - define 'lore:<[title]><&nl><[description]><&nl><[objectives]><&nl><[rewards]><&nl><&6><&o><[action]>'
            - determine <[lore]>
        
        - determine <element[]>




qm_quest_trait_events:
    type: task
    script:
        - define event_type:<[1]||<empty>>
        - define target_npc:<[2]||<empty>>
        - define target_player:<[3]||<empty>>

        - if <[event_type]> == click:
            - if <proc[qmp_quest.player.list.available].context[<[target_player]>|<[target_npc]>].size||0> > 0 || <proc[qmp_quest.player.list.completed].context[<[target_player]>|<[target_npc]>].size||0> > 0:
                - determine <list[qm_quest_shop|qm_quest_trait_menu]>
                # - run qm_menu.add 'def:<map[title/Quests|id/quests|handler/qm_quest_trait_menu]>'


qm_quest_shop:
    type: item
    material: book
    display name: Quests


qm_quest_trait_menu:
    type: task
    script:
        - note "in@generic[size=45;title=Quests]" as:quests_<player.uuid>
        - define slots:<map[]>

        - inventory set d:in@quests_<player.uuid> o:<[slots]>

        - foreach <proc[qmp_quest.player.list.available].context[<player>|<player.flag[npc_engaged].as_npc>]>:
            - define quest_id:<[value]>
            - define lore:<proc[qmp_quest.lore].context[<player>|<[quest_id]>]>

            - define slot_id:<[slots].keys.highest.add[1]||1>
            - define slots:<[slots].with[<[slot_id]>].as[questbook]>
            - inventory set d:in@quests_<player.uuid> slot:<[slot_id]> o:questbook
            - inventory adjust d:in@quests_<player.uuid> slot:<[slot_id]> 'lore:<[lore]>'

        - foreach <proc[qmp_quest.player.list.completed].context[<player>|<player.flag[npc_engaged].as_npc>]>:
            - define quest_id:<[value]>
            - define lore:<proc[qmp_quest.lore].context[<player>|<[quest_id]>]>

            - define slot_id:<[slots].keys.highest.add[1]||1>
            - define slots:<[slots].with[<[slot_id]>].as[questbookcomplete]>
            - inventory set d:in@quests_<player.uuid> slot:<[slot_id]> o:questbookcomplete
            - inventory adjust d:in@quests_<player.uuid> slot:<[slot_id]> 'lore:<[lore]>'
        
        - inventory open d:in@quests_<player.uuid>


qm_quests_cmd:
    type: task
    debug: true
    script:
        - choose <[1].get[command]>:
            - case quests:
                - choose <[1].get[option]>:
                    - case list null:
                        - run qm_menu.close
                        - run quests_menu_all
                        - run qm_menu.run def:quests_menu_all

                    - case listnpc:
                        - run qm_menu.close
                        - define target_npc:<player.location.find.npcs.within[10].get[1]||null>
                        - if <[target_npc]> != null:
                            - define quest_count:0

                            - foreach <yaml[quests].list_keys[quests]>:
                                - define quest_id:<[value]>
                                - define npc_start:false
                                - define npc_end:false

                                - if <yaml[quests].read[quests.<[quest_id]>.npc_start]||0> == <[target_npc].id>:
                                    - define npc_start:true
                                - if <yaml[quests].read[quests.<[quest_id]>.npc_end]||0> == <[target_npc].id>:
                                    - define npc_end:true
                                
                                - if <[npc_start]> || <[npc_end]>:
                                    - define quest_name:<yaml[quests].read[quests.<[quest_id]>.title]>
                                    - define 'quest_name:<[quest_name]>  <&f>('
                                    - if <[npc_start]>:
                                        - define 'quest_name:<[quest_name]>Start NPC'
                                        - if <[npc_end]>:
                                            - define 'quest_name:<[quest_name]>/'
                                    - if <[npc_end]>:
                                        - define 'quest_name:<[quest_name]>End NPC'

                                    - define quest_name:<[quest_name]>)

                                    - if <[quest_count]> == 0:
                                        - narrate '<&6>-- Quests (<[target_npc].name>) --'
                                    
                                    - define quest_count:++
                                    - run qm_menu.add 'def:<map[title/<[quest_name]>|id/<[value]>|handler/quests_menu]>'
                            
                            - if <[quest_count]> == 0:
                                - narrate <proc[qmp_lang].context[<player||null>|npc_no_quests|quests|<map[npc/<[target_npc].name>].escaped>]>

                            - run qm_menu.run def:quests_cmd
                        - else:
                            - narrate <proc[qmp_lang].context[<player||null>|no_npc_nearby|quests]>
                    - case create:
                        - run qm_menu.close
                        - run quests_menu
                        - run qm_menu.run def:quests_menu











quests_menu_all:
    type: task
    script:
        - run qm_menu.header def:Quests
        - foreach <yaml[quests].list_keys[quests]>:
            - define quest_id:<[value]>
            - run qm_menu.add 'def:<map[title/<yaml[quests].read[quests.<[quest_id]>.title]>|id/<[value]>|handler/quests_menu]>'









quests_menu:
    type: task
    script:
        - define quest_id:<[1]||null>
        - define option:<[quest_id]>

        - if <[option].contains_text[_]>:
            - define quest_id:<[option].after_last[_]>
            - define option:<[option].before_last[_]>

        - choose <[option]>:
            - case exit:
                - run qm_menu.clear
                - run qm_menu.close

            - case name:
                - define 'quest_name:<yaml[quests].read[quests.<[quest_id]>.title]||null>'
                - run qm_menu.add 'def:<map[title/Enter new quest name:|id/name_set_<[quest_id]>|handler/quests_menu|key/*]>'
                - run qm_menu.add 'def:<map[title/<&7>(<[quest_name]>)]>'
            
            - case name_set:
                - define chat:<[3]||null>
                - yaml id:quests set quests.<[quest_id]>.title:<[chat]>
                - run qm_menu.back
            
            - case npc_start:
                - define quest_npc_start:<yaml[quests].read[quests.<[quest_id]>.npc_start]||null>
                - if <[quest_npc_start]> != null:
                    - define 'quest_npc_start:<npc[<[quest_npc_start]>].name> (<[quest_npc_start]>)'
                - else:
                    - define 'quest_npc_start:(not set)'

                - run qm_menu.add 'def:<map[title/Enter new starting NPC id (or * for closest NPC):|id/npc_start_set_<[quest_id]>|handler/quests_menu|key/*]>'
                - run qm_menu.add 'def:<map[title/<&7>(<[quest_npc_start]>)]>'

            - case npc_start_set:
                - define chat:<[3]||null>
                - if <[chat]> == '*':
                    - define closest_npc:<player.location.find.npcs.within[10].get[1].id||null>
                    - if <[closest_npc]> == null:
                        - run qm_menu.add 'def:<map[title/XXThere are no NPCs near you]>'
                    - else:
                        - define chat:<[closest_npc]>
                
                - if <[chat].is_integer> && <npc[<[chat]>].id||null> != null:
                    - run qm_npc.trait.add def:quests|<npc[<[chat]>]>
                    - yaml id:quests set quests.<[quest_id]>.npc_start:<[chat]>
                - else:
                    - if <[chat]> != '*':
                        - run qm_menu.add 'def:<map[title/XXUnknown NPC ID]>'
                
                - run qm_menu.back

            - case npc_start_speak:
                - define npc_start_speak:<yaml[quests].read[quests.<[quest_id]>.npc_start_speak]||null>
                - if <[npc_start_speak]> == null:
                    - define 'npc_start_speak:not set'
                - run qm_menu.add 'def:<map[title/Enter new NPC start speak (- to remove):|id/npc_start_speak_set_<[quest_id]>|handler/quests_menu|key/*]>'
                - run qm_menu.add 'def:<map[title/<&7>(<[npc_start_speak]>)]>'

            - case npc_start_speak_set:
                - define chat:<[3]||null>
                - if <[chat]> == '-':
                    - yaml id:quests set quests.<[quest_id]>.npc_start_speak:!
                - else:
                    - yaml id:quests set quests.<[quest_id]>.npc_start_speak:<[chat]>
                
                - run qm_menu.back

            - case npc_end:
                - define quest_npc_end:<yaml[quests].read[quests.<[quest_id]>.npc_end]||null>
                - if <[quest_npc_end]> != null:
                    - define 'quest_npc_end:<npc[<[quest_npc_end]>].name> (<[quest_npc_end]>)'
                - else:
                    - define 'quest_npc_end:(not set)'

                - run qm_menu.add 'def:<map[title/Enter new ending NPC id (or * for closest NPC):|id/npc_end_set_<[quest_id]>|handler/quests_menu|key/*]>'
                - run qm_menu.add 'def:<map[title/<&7>(<[quest_npc_end]>)]>'

            - case npc_end_set:
                - define chat:<[3]||null>
                - if <[chat]> == '*':
                    - define closest_npc:<player.location.find.npcs.within[10].get[1].id||null>
                    - if <[closest_npc]> == null:
                        - run qm_menu.add 'def:<map[title/XXThere are no NPCs near you]>'
                    - else:
                        - define chat:<[closest_npc]>
                
                - if <[chat].is_integer> && <npc[<[chat]>].id||null> != null:
                    - run qm_npc.trait.add def:quests|<npc[<[chat]>]>
                    - yaml id:quests set quests.<[quest_id]>.npc_end:<[chat]>
                - else:
                    - if <[chat]> != '*':
                        - run qm_menu.add 'def:<map[title/XXUnknown NPC ID]>'
                
                - run qm_menu.back

            - case npc_end_speak:
                - define npc_end_speak:<yaml[quests].read[quests.<[quest_id]>.npc_end_speak]||null>
                - if <[npc_end_speak]> == null:
                    - define 'npc_end_speak:not set'
                - run qm_menu.add 'def:<map[title/Enter new NPC end speak (- to remove):|id/npc_end_speak_set_<[quest_id]>|handler/quests_menu|key/*]>'
                - run qm_menu.add 'def:<map[title/<&7>(<[npc_end_speak]>)]>'

            - case npc_end_speak_set:
                - define chat:<[3]||null>
                - if <[chat]> == '-':
                    - yaml id:quests set quests.<[quest_id]>.npc_end_speak:!
                - else:
                    - yaml id:quests set quests.<[quest_id]>.npc_end_speak:<[chat]>
                
                - run qm_menu.back

            - case description:
                - define description:<yaml[quests].read[quests.<[quest_id]>.description]||null>
                - if <[description]> == null:
                    - define 'description:not set'
                - run qm_menu.add 'def:<map[title/Enter new quest description (- to remove):|id/description_set_<[quest_id]>|handler/quests_menu|key/*]>'
                - run qm_menu.add 'def:<map[title/<&7>(<[description]>)]>'

            - case description_set:
                - define chat:<[3]||null>
                - if <[chat]> == '-':
                    - yaml id:quests set quests.<[quest_id]>.description:!
                - else:
                    - yaml id:quests set quests.<[quest_id]>.description:<[chat]>
                
                - run qm_menu.back
            
            - case give:
                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.give]||<list[]>>:
                    - run qm_menu.add 'def:<map[title/<[value]> x <yaml[quests].read[quests.<[quest_id]>.give.<[value]>]>|id/give_edit_<[quest_id]>;<[value]>|handler/quests_menu]>'

                - run qm_menu.add 'def:<map[title/Add item|id/give_edit_<[quest_id]>|handler/quests_menu|key/a]>'
            
            - case give_edit:
                - define material:<[quest_id].after[;]||null>
                - define quest_id:<[quest_id].before[;]>

                - define remove_prompt:<element[]>
                - if <[material]> != null:
                    - define 'remove_prompt: (- to remove)'

                - run qm_menu.add 'def:<map[title/Enter material name and quantity <[remove_prompt]>:|id/give_edit_set_<[quest_id]>;<[material]>|handler/quests_menu|key/*]>'
                - if <[material]> != null:
                    - run qm_menu.add 'def:<map[title/<&7>(<[material]> x <yaml[quests].read[quests.<[quest_id]>.give.<[material]>]>)]>'

            - case give_edit_set:
                - define chat:<[3]||null>
                - define old_material:<[quest_id].after[;]||null>
                - define quest_id:<[quest_id].before[;]>
                - define 'material:<[chat].before[ ]||dirt>'
                - define 'quantity:<[chat].after[ ]||1>'
                
                - if <material[<[material]>]||null> != null:
                    - if <[quantity].is_integer>:
                        - if <[old_material]> != null:
                            - yaml id:quests set quests.<[quest_id]>.give.<[old_material]>:!
                        - if <[material]> != '-':
                            - yaml id:quests set quests.<[quest_id]>.give.<[material]>:<[quantity]>
                    - else:
                        - run qm_menu.add def:<map[title/<proc[qmp_lang].context[<player||null>|quest_material_qty_bad|quests]>]>
                - else:
                    - run qm_menu.add def:<map[title/<proc[qmp_lang].context[<player||null>|quest_material_bad|quests]>]>

                - run qm_menu.back
                
            - case objectives:
                - foreach <yaml[quests].list_keys[quests.<[quest_id]>.objectives]||<list[]>>:
                    - choose <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.type]>:
                        - case break_block:
                            - run qm_menu.add 'def:<map[title/<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.type]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.material]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<element[]>>|id/objectives_edit_<[quest_id]>;<[value]>|handler/quests_menu]>'
                        - case place_block:
                            - run qm_menu.add 'def:<map[title/<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.type]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.material]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<element[]>>|id/objectives_edit_<[quest_id]>;<[value]>|handler/quests_menu]>'
                        - case give:
                            - run qm_menu.add 'def:<map[title/<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.type]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.material]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]>|id/objectives_edit_<[quest_id]>;<[value]>|handler/quests_menu]>'
                        - case enter:
                            - run qm_menu.add 'def:<map[title/<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.type]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.region]>|id/objectives_edit_<[quest_id]>;<[value]>|handler/quests_menu]>'
                        - case kill:
                            - run qm_menu.add 'def:<map[title/<yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.type]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.entity]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.quantity]> <yaml[quests].read[quests.<[quest_id]>.objectives.<[value]>.region]||<element[]>>|id/objectives_edit_<[quest_id]>;<[value]>|handler/quests_menu]>'

                - run qm_menu.add 'def:<map[title/Add objective|id/objective_edit_<[quest_id]>|handler/quests_menu|key/a]>'

            - case objectives_edit:
                - define objective_id:<[quest_id].after[;]||null>
                - define quest_id:<[quest_id].before[;]>

                - define remove_prompt:<element[]>
                - if <[objective_id]> != null:
                    - define 'remove_prompt: (- to remove)'

                - run qm_menu.add 'def:<map[title/Enter objective information <[remove_prompt]>:|id/give_edit_set_<[quest_id]>;<[objective_id]>|handler/quests_menu|key/*]>'
                - if <[objective_id]> != null:
                    - run qm_menu.add 'def:<map[title/<&7>(<[material]> x <yaml[quests].read[quests.<[quest_id]>.give.<[material]>]>)]>'
                
                - run qm_menu.add 'def:<map[title/<&7>(<[material]> x <yaml[quests].read[quests.<[quest_id]>.give.<[material]>]>)]>'


            - case objectives_edit_set:
                - define chat:<[3]||null>
                - define objective_id:<[quest_id].after[;]||null>
                - define quest_id:<[quest_id].before[;]>
                - define args:<[chat].space_separated||<list[]>>




                - if <material[<[material]>]||null> != null:
                    - if <[quantity].is_integer>:
                        - if <[old_material]> != null:
                            - yaml id:quests set quests.<[quest_id]>.give.<[old_material]>:!
                        - if <[material]> != '-':
                            - yaml id:quests set quests.<[quest_id]>.give.<[material]>:<[quantity]>
                    - else:
                        - run qm_menu.add def:<map[title/<proc[qmp_lang].context[<player||null>|quest_material_qty_bad|quests]>]>
                - else:
                    - run qm_menu.add def:<map[title/<proc[qmp_lang].context[<player||null>|quest_material_bad|quests]>]>

                - run qm_menu.back



            - default:
                - define 'quest_name:<yaml[quests].read[quests.<[quest_id]>.title]||<element[(not set)]>>'
                - define quest_npc_start:<yaml[quests].read[quests.<[quest_id]>.npc_start]||null>
                - if <[quest_npc_start]> != null:
                    - define 'quest_npc_start:<npc[<[quest_npc_start]>].name> (<[quest_npc_start]>)'
                - else:
                    - define 'quest_npc_start:(not set)'

                - run qm_menu.header def:<[quest_name]>

                - define quest_npc_start_speak:<yaml[quests].read[quests.<[quest_id]>.npc_start_speak]||null>
                - if <[quest_npc_start_speak]> != null:
                    - define quest_npc_start_speak:(set)
                - else:
                    - define 'quest_npc_start_speak:(not set)'

                - define quest_npc_end:<yaml[quests].read[quests.<[quest_id]>.npc_end]||null>
                - if <[quest_npc_end]> != null:
                    - define 'quest_npc_end:<npc[<[quest_npc_end]>].name> (<[quest_npc_end]>)'
                - else:
                    - define 'quest_npc_end:(not set)'

                - define quest_npc_end_speak:<yaml[quests].read[quests.<[quest_id]>.npc_end_speak]||null>
                - if <[quest_npc_end_speak]> != null:
                    - define quest_npc_end_speak:(set)
                - else:
                    - define 'quest_npc_end_speak:(not set)'

                - define quest_description:<yaml[quests].read[quests.<[quest_id]>.description]||null>
                - if <[quest_description]> != null:
                    - define quest_description:(set)
                - else:
                    - define 'quest_description:(not set)'
                
                - define quest_give:<yaml[quests].list_keys[quests.<[quest_id]>.give].size||0>
                - define 'quest_give:(<[quest_give]> item/s)'

                - define quest_objectives:<yaml[quests].list_keys[quests.<[quest_id]>.objectives].size||0>
                - define 'quest_objectives:(<[quest_objectives]> item/s)'

                - define quest_rewards:<yaml[quests].list_keys[quests.<[quest_id]>.rewards.materials].size||0>
                - define 'quest_rewards:(<proc[qmp_server.format.money].context[<yaml[quests].read[quests.<[quest_id]>.rewards.money]>]><&f> & <[quest_rewards]> item/s)'

                - define quest_requires:<yaml[quests].list_keys[quests.<[quest_id]>.requires]||null>
                - if <[quest_requires]> != null:
                    - define 'quest_requires:(<yaml[quests].read[quests.<yaml[quests].read[quests.<[quest_id]>.requires]>.name]>)'
                        
                - else:
                    - define 'quest_requires:(not set)'


                - run qm_menu.add 'def:<map[title/Name:   <&f><[quest_name]>|id/name_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Starting NPC:   <&f><[quest_npc_start]>|id/npc_start_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Starting NPC speak   <&f><[quest_npc_start_speak]>|id/npc_start_speak_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Ending NPC   <&f><[quest_npc_end]>|id/npc_end_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Ending NPC speak   <&f><[quest_npc_end_speak]>|id/npc_end_speak_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Description   <&f><[quest_description]>|id/description_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Give items   <&f><[quest_give]>|id/give_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Objectives   <&f><[quest_objectives]>|id/objectives_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Rewards   <&f><[quest_rewards]>|id/rewards_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Requirements   <&f><[quest_requirements]>|id/requirements_<[quest_id]>|handler/quests_menu]>'
                - run qm_menu.add 'def:<map[title/Exit|id/exit|handler/quests_menu|key/x]>'


qm_quests_cmd_quests:
    type: command
    debug: true
    name: quests
    description: Displays current quests
    usage: /quests
    script:
        - define quest_list_active:<proc[qmp_quest.player.list.active].context[<player>]>
        - define quest_list_completed:<proc[qmp_quest.player.list.completed].context[<player>]>

        - if <[quest_list_active].size> > 0 || <[quest_list_completed].size> > 0:
            - note 'in@generic[size=45;title=My Quests]' as:quests_<player.uuid>
            - define slots:<map[]>

            - inventory set d:in@quests_<player.uuid> o:<[slots]>

            - foreach <[quest_list_active]>:
                - define quest_id:<[value]>
                - define lore:<proc[qmp_quest.lore].context[<player>|<[quest_id]>|true]>

                - define slot_id:<[slots].keys.highest.add[1]||1>
                - define slots:<[slots].with[<[slot_id]>].as[questbook]>
                - inventory set d:in@quests_<player.uuid> slot:<[slot_id]> o:questbook
                - inventory adjust d:in@quests_<player.uuid> slot:<[slot_id]> 'lore:<[lore]>'

            - foreach <[quest_list_completed]>:
                - define quest_id:<[value]>
                - define lore:<proc[qmp_quest.lore].context[<player>|<[quest_id]>|true]>

                - define slot_id:<[slots].keys.highest.add[1]||1>
                - define slots:<[slots].with[<[slot_id]>].as[questbook]>
                - inventory set d:in@quests_<player.uuid> slot:<[slot_id]> o:questbookcomplete
                - inventory adjust d:in@quests_<player.uuid> slot:<[slot_id]> 'lore:<[lore]>'

            - inventory open d:in@quests_<player.uuid>
        - else:
            - narrate <proc[qmp_language].context[no_quests|quest]>






questbook:
    type: item
    material: book
    display name: <&d>Quest


questbookcomplete:
    type: item
    material: writable_book
    display name: <&d>Quest <&6>(Complete)