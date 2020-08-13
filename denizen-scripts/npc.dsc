# File:     npc.dsc
# Contains: NPC base handler
# Package:  QLD Minecraft
# Version:  Season 1 (012)
# URL:      http://play.qldminecraft.com.au/

qm_npc_assignment:
    type: assignment
    actions:
        on assignment:
        - trigger name:click state:true
        - trigger name:chat state:true
        - trigger name:proximity state:true

    interact scripts:
    - qm_npc_interact

# default npc interactions
qm_npc_interact:
  type: interact
  speed: 0
  steps:
    1:
        # proximity trigger:
        #     exit:
        #         script:
        #             # reset npc engage
        #           - if <player.has_flag[npc_engage.npc]>:
        #             - if <player.flag[npc_engage.npc] == <npc.id>:
        #                 - flag player npc_engage.npc:!
            
        click trigger:
            script:
                # greeting
                # - if <yaml[server].contains[npcs.<npc.id>.greetings]>:
                #     - define greetings:<yaml[server].read[npcs.<npc.id>.greetings]>
                # - else:
                #     - define greetings:<yaml[server].read[npc.greetings]>
                    
                # - narrate format:npc <[greetings].get[<util.random.int[1].to[<[greetings].size>]>]>

                # npc menu
                - ~run qm_npc_menu_handler def:<npc>

        # chat trigger:
        #     1:
        #         trigger: /*/
        #         hide trigger message: true
        #         script:
        #         - ~run qm_npc_menu_handler def:<npc>|<context.message>
                
                #- if <player.flag[npc_engage.npc]> == <npc.id>:
                #    - 
                #- else:
                # - define actions:<yaml[server].read[npc.unknown_chat]>
                # - define action:<[actions].get[<util.random.int[1].to[<[actions].size>]>]>
                # - if <[action].starts_with[*]>:
                #     - narrate format:npc_action <[action].after_last[*]>
                # - else:
                #     - narrate format:npc <[action]>
                    

qm_npc_menu_handler:
    type: task
    definitions: npc|chat
    script:
        - define max_len:5
        - define menu_item:null

        # Quest title
        # Quest storyline
        # Quest objects
        # Quest rewards

        - if <queue.definitions.contains[chat]> && <player.flag[npc_engage.npc]||0> == <[npc]>:
            # player response
            - if <[chat].is_integer>:
                - if <[chat]> >= 1 && <[chat]> <= <player.flag[npc_engage.menu_items].as_list.size>:
                    - define menu_item:<player.flag[npc_engage.menu_items].as_list.get[<[chat]>].as_map>
                    - if <[menu_item].keys.contains[menu]>:
                        - flag player npc_engage.menu:->:<[menu_item].get[menu]>
                        - flag player npc_engage.menu_page:0
                    - else:
                        - narrate format:notice "An error occured"
                        - stop
                    
                    - if <[menu_item].keys.contains[id]>:
                        - flag player npc_engage.menu_item_id:<[menu_item].get[id]>
                - else:
                    - run qm_npc_unknown_chat def:<[npc]>
                    - flag player npc_engage:!
                    - stop
            - else if <[chat]> == b:
                - if <player.flag[npc_engage.menu_page]||0> > 0:
                    - flag player npc_engage.menu_page:--
                - else if <player.flag[npc_engage.menu].size> > 1:
                    - flag player npc_engage.menu:<-:<player.flag[npc_engage.menu].last>
                    - flag player npc_engage.menu_page:0
            - else if <[chat]> == n:
                - if <player.flag[npc_engage.menu_items].size> > <player.flag[npc_engage.menu_page].mul_int[<[max_len]>].add_int[<[max_len]>]>:
                    - flag player npc_engage.menu_page:++
                - else:
                    - run qm_npc_unknown_chat def:<[npc]>
                    - flag player npc_engage:!
                    - stop
            - else if <[chat]> == y:
                - narrate "confirmed (<player.flag[npc_engage.menu].last>) <player.flag[npc_engage.menu_item_id]>"
                # Quest accepted: <name>
                - flag player npc_engage:!
                - stop
            - else:
                - run qm_npc_unknown_chat def:<[npc]>
                - flag player npc_engage:!
                - stop
        - else:
            # player clicked
            - define greetings:<yaml[server].read[npcs.<[npc].id>.greetings]||null>
            - if <[greetings]> == null:
                - define greetings:<yaml[server].read[npcs.__default__.greetings]||null>

            - if <[greetings]> != null:
                - define text:<[greetings].get[<util.random.int[1].to[<[greetings].size>]>]>
            - if <[text].starts_with[*]>:
                - narrate format:npc_action <[text].after_last[*]>
            - else:
                - narrate format:npc <[text]>
            # - narrate ""
    
            - flag player npc_engage.npc:<[npc]>
            - flag player npc_engage.menu:!
            - flag player npc_engage.menu:->:main
            - flag player npc_engage.menu_page:0


        
        - define menu_loop:1
        - while <[menu_loop]> > 0:
            - define menu_loop:--
            - flag player npc_engage.menu_items:!
            - choose <player.flag[npc_engage.menu].last>:
                - case main:
                    - define quests:0
                    - foreach <yaml[server].list_keys[quests]>:
                        # is the npc part of a quest start
                        - if <yaml[server].read[quests.<[value]>.start_npc]> == <[npc].id>:
                            # is the quest not in return or completed state for the player
                            - if !<yaml[<player.uuid>].read[quests.return].contains[<[value]>]> && !<yaml[<player.uuid>].read[quests.completed].contains[<[value]>]>:
                                # does the quest have a requirement and does the player meet it
                                - define requires:<yaml[server].read[quests.<[value]>.requires]||null>
                                - if <[requires]> == null || <yaml[<player.uuid>].list_keys.[quests.completed].contains[<[requires]>]>:
                                    - define quests:1

                        # is the npc part of a quest hand-in?
                        - if <yaml[server].read[quests.<[value]>.finish_npc]> == <[npc].id>:
                            # is the quest in a return state for the player
                            - if <yaml[<player.uuid>].read[quests.return].contains[<[value]>]>:
                                - define quests:1
                    
                    - if <[quests]> == 1:
                        - flag player npc_engage.menu_items:->:<map[title/Quests|menu/quests]>

                    - if <yaml[server].read[npcs.<[npc].id>.plots]||null> != null:
                        - flag player npc_engage.menu_items:->:<map[title/Plots|menu/plots]>

                    - if <yaml[server].list_keys[npcs.<[npc].id>.travel]||null> != null:
                        - flag player npc_engage.menu_items:->:<map[title/Travel|menu/travel]>

                    - if <player.flag[npc_engage.menu_items].size> == 1:
                        - flag player npc_engage.menu:!
                        - flag player npc_engage.menu:->:<player.flag[npc_engage.menu_items].as_list.get[1].as_map.get[menu]>
                        - flag player npc_engage.menu_page:0
                        - define menu_loop:++

                - case quests:
                    - narrate "<&6>-- Quests --"
                    - narrate ""
                    - foreach <yaml[server].list_keys[quests]>:
                        # is the npc part of a quest start
                        - if <yaml[server].read[quests.<[value]>.start_npc]> == <[npc].id>:
                            # is the quest not in return or completed state for the player
                            - if !<yaml[<player.uuid>].read[quests.return].contains[<[value]>]> && !<yaml[<player.uuid>].read[quests.completed].contains[<[value]>]>:
                                # does the quest have a requirement and does the player meet it
                                - define requires:<yaml[server].read[quests.<[value]>.requires]||null>
                                - if <[requires]> == null || <yaml[<player.uuid>].list_keys.[quests.completed].contains[<[requires]>]>:
                                    - flag player "npc_engage.menu_items:->:<map[title/<yaml[server].read[quests.<[value]>.title]>|menu/questitem|id/<[value]>]>"

                        # is the npc part of a quest hand-in?
                        - if <yaml[server].read[quests.<[value]>.finish_npc]> == <[npc].id>:
                            # is the quest in a return state for the player
                            - if <yaml[<player.uuid>].read[quests.return].contains[<[value]>]>:
                                - flag player "npc_engage.menu_items:->:<map[title/<yaml[server].read[quests.<[value]>.title]> <&7>(Completed)|menu/questitem|id/<[value]>]>"

                    
                - case plots:
                    - narrate "<&6>-- Plots --"
                    - narrate ""
                    - foreach <yaml[server].read[npcs.<[npc].id>.plots]>:
                        - define owner:<yaml[server].read[plots.<[value]>.owner]||0>
                        - define cost:<yaml[server].read[plots.<[value]>.cost]||0>
                        - define name:<yaml[server].read[plots.<[value]>.name]||<[value]>>
                        - if <[cost]> == 0:
                            - define "cost:Free"
                        - else:
                            - define cost:<proc[qm_player_money_format].context[<[cost]>|6]>

                        - if <[owner]> == 0:
                            - define "info:<&7>(<[cost]>)"
                        - else:
                            - define "info:<&7>(Owned by <[owner]>)"

                        - flag player "npc_engage.menu_items:->:<map[title/<[name]> <[info]>|menu/plotitem|id/<[value]>]>"
                - case travel:
                    - narrate "<&6>-- Travel --"
                    - narrate ""
                    - define travel:<yaml[server].list_keys[npcs.<[npc].id>.travel]||null>
                    - if <[travel]> != null:
                        - foreach <[travel]>:
                            - define cost:<yaml[server].read[npcs.<[npc].id>.travel.<[value]>.cost]||0>
                            - if <[cost]> == 0:
                                - define "cost:Free"
                            - else:
                                - define cost:<proc[qm_player_money_format].context[<[cost]>|6]>
                            
                            - define name:<yaml[server].read[npcs.<[npc].id>.travel.<[value]>.name]||<[value]>>

                            - flag player "npc_engage.menu_items:->:<map[title/<[name]> <&7>(<[cost]>)|menu/travelitem|id/<[value]>]>"
                - case questitem:
                    - if <[menu_item]> != null:
                        - narrate "questitem - (<[menu_item].get[id]>)"
                        - narrate "<element[b - back].on_click[b]>"
                        - narrate "<element[y - confirm].on_click[y]>"
                    - else:
                        - narrate "An error occured"
                - case plotitem:
                    - narrate "plotitem"
                - case travelitem:
                    - narrate "<&o><&e>Travel accepted: <[menu_item].get[id]>"
                    - define cost:<yaml[server].read[npcs.<[npc].id>.travel.<[menu_item].get[id]>.cost]||0>

                    - if <player.money> < <[cost]>:
                        - narrate "<&e>You do not have enough money"
                    - else:
                        - take money quantity:<[cost]>
                        - execute as_op "dt travel <[menu_item].get[id]>"
                - default:
                    - narrate format:notice "An error occurred"

        - if <player.flag[npc_engage.menu_items].size||0> > 0:
            # TODO the following is wiping the greeting! and titles
            - narrate "<&nl.pad_right[7750].with[<&sp><&nl>]>"
            # - narrate ""
            - define from:<player.flag[npc_engage.menu_page].mul_int[<[max_len]>].add_int[1]>

            - foreach <player.flag[npc_engage.menu_items].as_list.get[<[from]>].to[<[from].add_int[<[max_len].sub_int[1]>]>]>:
                - narrate "<element[<&l><[loop_index]><&l.end_format> - <&e><[value].get[title]>].on_click[<[loop_index]>]>"
            
            - define footer_list:li@
            - if <player.flag[npc_engage.menu].size> > 1 || <player.flag[npc_engage.menu_page]> > 0:
                - define footer_list:->:<element[<&6><&lb>B<&rb>ack].on_click[b]>
            - if <player.flag[npc_engage.menu_items].size> > <player.flag[npc_engage.menu_page].mul_int[<[max_len]>].add_int[<[max_len]>]>:
                - define footer_list:->:<element[<&6><&lb>N<&rb>ext].on_click[n]>

            - if <[footer_list].size> > 0:
                - narrate ""


            - define footer_text:el@
            - foreach <[footer_list]>:
                - define "footer_text:<[footer_text]><[value]>   "

            #- if <[footer_text]||null> != null:
            - narrate <[footer_text]>








    # # respond
    # - define menu_item:null
    # - if <queue.definitions.contains[chat]>:
    
    # # setup menu
    # - choose <player.flag[npc_engage.menu].last>:
    #     # main
    #     - case main:
    #         - flag player npc_engage.menu_items:!

    #         - define questList:<yaml[server].list_keys[quests]||null>
    #         - if <[questList]> != null:
    #             - foreach <[questList]>:
    #                 - if <yaml[server].read[quests.<[value]>.start_npc]> == <[npc].id>:
    #                     - if <yaml[<player.uuid>].read[quests.completed.<[value]>]||null> != 0:
    #                         # TODO Check requirements are OK
    #                         - flag player npc_engage.menu_items:->:<map[title/Quests|menu/quests]>
    #                         - foreach stop
            
    #         - define plotList:<yaml[server].list_keys[npcs.<[npc].id>.plots]||null>
    #         - if <[plotList]> != null:
    #             - flag player npc_engage.menu_items:->:<map[title/Plots|menu/plots]>

    #         # Generate random title
    #         - define greetings:<yaml[server].read[npcs.<[npc].id>.greetings]||null>
    #         - if <[greetings]> == null:
    #             - define greetings:<yaml[server].read[npcs.__default__.greetings]||null>
            
    #         - if <[greetings]> != null:
    #             - define text:<[greetings].get[<util.random.int[1].to[<[greetings].size>]>]>
    #             - if <[text].starts_with[*]>:
    #                 - narrate format:npc_action <[text].after_last[*]>
    #             - else:
    #                 - narrate format:npc <[text]>
    #             - define menu_title:<[text]>

        # quests
        # - case quests:
        #     - flag player npc_engage.menu_items:!

        #     - define menu_title:Quests

        #     - foreach <yaml[server].list_keys[quests]>:
        #         - if <yaml[server].read[quests.<[value]>.start_npc]> == <[npc].id>:
        #             - flag player npc_engage.menu_items:->:<map[title/<yaml[server].read[quests.<[value]>.title]>|menu/questitem|id/<[value]>]>

        # - case questitem:
        #     - define menu_title:

        # unknown
        # - default:
        #     - run qm_npc_unknown_chat def:<[npc]>
        #     - flag player npc_engage:!
        #     - stop

    # render menu
    # - if <player.has_flag[npc_engage.menu_items]>:
        
    #     - narrate "<&6>-- <[npc].name>: <[menu_title]> --"
    #     - foreach <player.flag[npc_engage.menu_items].as_list>:
    #         - narrate "<&9><[loop_index]><&e> - <[value].get[title]>"
    #     - if <player.flag[npc_engage.menu].size> > 1:
    #         - narrate "<&6>b - Back"
    # - else:
    #     - flag player npc_engage:!


qm_npc_unknown_chat:
    type: task
    definitions: npc
    script:
        - define unknown:<yaml[server].read[npcs.<[npc].id>.unknown]||null>
        - if <[unknown]> == null:
            - define unknown:<yaml[server].read[npcs.__default__.unknown]||null>
        
        - if <[unknown]> != null:
            - define text:<[unknown].get[<util.random.int[1].to[<[unknown].size>]>]>
            - if <[text].starts_with[*]>:
                - narrate "<&f><[npc].name> <[text].after_last[*]>"
            - else:
                - narrate "<&f>[<[npc].name>]: <[text]>"
