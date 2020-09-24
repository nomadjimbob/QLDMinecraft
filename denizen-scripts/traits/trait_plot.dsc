qmw_trait_plot:
    type: world
    events:
        on load:
            - run qm_npc.trait.register def:plotmaster|qm_trait_plot_events

            - run qm_command.add.command def:trait_plot_cmd|plot|developer
            - run qm_command.add.tabcomplete def:plot|add
            - run qm_command.add.tabcomplete def:plot|update
            - run qm_command.add.tabcomplete def:plot|del
            - run qm_command.add.tabcomplete def:plot|name
            - run qm_command.add.tabcomplete def:plot|npc
            - run qm_command.add.tabcomplete def:plot|group
            - run qm_command.add.tabcomplete def:plot|sign
            - run qm_command.add.tabcomplete def:plot|signupdate
            - run qm_trait_plot.yaml.load
        
        on save:
            - run qm_trait_plot.yaml.save
        
        on player places block priority:-1:
            - foreach <yaml[plots].list_keys[plots]>:
                - if <context.location.is_within[<yaml[plots].read[plots.<[value]>.cuboid]>]>:
                    - if <yaml[plots].read[plots.<[value]>.owner]||null> == <player.uuid>:
                        - flag player block_place_allow:true

        on player breaks block priority:-1:
            - foreach <yaml[plots].list_keys[plots]>:
                - if <context.location.is_within[<yaml[plots].read[plots.<[value]>.cuboid]>]>:
                    - if <yaml[plots].read[plots.<[value]>.owner]||null> == <player.uuid>:
                        - flag player block_break_allow:true

        on player drags in inventory:
            - if '<context.inventory.title.starts_with[Plots]>':
                - determine cancelled
        
        on player clicks in inventory:
            - if '<context.inventory.title.starts_with[Plots]>':
                - determine passively cancelled
                - if <inventory[plots_<player.uuid>].map_slots.get[<context.slot>].material.name||<empty>> != <empty>:
                    - if <context.clicked_inventory.title> != 'inventory':
                        - define plot_id:<inventory[plots_<player.uuid>].map_slots.get[<context.slot>].lore.get[1].after_last[/]||<empty>>
                        - if <[plot_id]> != <empty>:
                            - if <inventory[plots_<player.uuid>].map_slots.get[<context.slot>].script.name> == qm_trait_plotmaster_sell_item:
                                - run qm_trait_plot.plot.sell def:<player>|<[plot_id]>
                            - else:
                                - run qm_trait_plot.plot.buy def:<player>|<[plot_id]>


                - inventory close
        
        on player closes inventory:
            - if '<context.inventory.title.starts_with[Plots]>':
                - note remove as:plots_<player.uuid>

qm_trait_plot:
    type: task
    script:
        - determine <empty>

    yaml:
        load:
            - if <server.has_file[/serverdata/plots.yml]>:
                - yaml load:/serverdata/plots.yml id:plots
            - else:
                - yaml create id:plots

            - run qm_trait_plot.yaml.save

        save:
            - yaml savefile:/serverdata/plots.yml id:plots
    
    sign:
        update:
            - define id:<[1]||null>
            - if <[id]> != null:
                - define sign_location:<yaml[plots].read[plots.<[id]>.sign]||null>
                - if <[sign_location]> != null:
                    - define name:<yaml[plots].read[plots.<[id]>.name]||null>
                    - define owner:<yaml[plots].read[plots.<[id]>.owner]||null>
                    - define cost:<yaml[plots].read[plots.<[id]>.cost]||0>

                    - if <[owner]> == null:
                        - if <[cost]> == 0:
                            - define cost:<&7>Free
                        - else:
                            - define cost:<proc[qmp_server.format.money].context[<[cost]>]>

                        - sign type:automatic '<&6>For Sale|<[name]>| |<[cost]>' <[sign_location]>
                    - else:
                        - define owner_name:<player[<[owner]>].name>
                        - sign type:automatic '<&6><[name]>| |<&7>Owner|<[owner_name]>' <[sign_location]>

    plot:
        buy:
            - define target_player:<[1]||<empty>>
            - define plot_id:<[2]||<empty>>
            - if <[target_player].is_player||false> && <[plot_id]> != <empty>:
                - define name:<yaml[plots].read[plots.<[plot_id]>.name]||Plot_<[plot_id]>>
                - define group:<yaml[plots].read[plots.<[plot_id]>.group]||<empty>>
                - define own_group_already:false

                - if <[group]> != <empty>:
                    - foreach <yaml[plots].list_keys[plots]>:
                        - if <yaml[plots].read[plots.<[value]>.owner]||<empty>> == <[target_player].uuid> && <yaml[plots].read[plots.<[value]>.group]||<empty>> == <[group]>:
                            - define own_group_already:true
                            - foreach stop
                
                - if !<[own_group_already]>:
                    - if <yaml[plots].read[plots.<[plot_id]>.owner]||<empty>> == <empty>:
                        - define cost:<proc[qmp_trait_plot.cost.buy].context[<[plot_id]>]>

                        - if <[target_player].money> >= <[cost]>:
                            - yaml id:plots set plots.<[plot_id]>.owner:<[target_player].uuid>
                            - run qm_trait_plot.yaml.save
                            - run qm_trait_plot.sign.update def:<[plot_id]>
                            - if <[cost]> > 0:
                                - take money quantity:<[cost]> from:<[target_player]>
                            - narrate <proc[qmp_language].context[bought_plot|plotmaster|<map[plot/<[name]>].escaped>]>
                            - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<[target_player].money>]>
                        - else:
                            - narrate <proc[qmp_language].context[not_enough_buy|plotmaster|<map[plot/<[name]>].escaped>]>
                    - else:
                        - narrate <proc[qmp_language].context[already_owned|plotmaster|<map[plot/<[name]>].escaped>]>
                - else:
                    - narrate <proc[qmp_language].context[already_own_in_group|plotmaster|<map[plot/<[name]>].escaped>]>

        sell:
            - define target_player:<[1]||<empty>>
            - define plot_id:<[2]||<empty>>
            - if <[target_player].is_player||false> && <[plot_id]> != <empty>:
                - define name:<yaml[plots].read[plots.<[plot_id]>.name]||Plot_<[plot_id]>>
                - if <yaml[plots].read[plots.<[plot_id]>.owner]||<empty>> == <[target_player].uuid>:
                    - define cost:<proc[qmp_trait_plot.cost.sell].context[<[plot_id]>]>

                    - yaml id:plots set plots.<[plot_id]>.owner:!
                    - run qm_trait_plot.yaml.save
                    - run qm_trait_plot.sign.update def:<[plot_id]>
                    - if <[cost]> > 0:
                        - give money quantity:<[cost]> from:<[target_player]>
                    - narrate <proc[qmp_language].context[sold_plot|plotmaster|<map[plot/<[name]>].escaped>]>
                    - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<[target_player].money>]>
                - else:
                    - narrate <proc[qmp_language].context[do_not_own_to_sell|plotmaster|<map[plot/<[name]>].escaped>]>


qmp_trait_plot:
    type: procedure
    script:
        - determine <empty>

    cost:
        buy:
            - define plot_id:<[1]||<empty>>
            - define cost:0
            - if <[plot_id]> != <empty>:
                - define cost:<yaml[plots].read[plots.<[plot_id]>.cost]||0>

            - determine <[cost]>

        sell:
            - define plot_id:<[1]||<empty>>
            - define cost:0
            - if <[plot_id]> != <empty>:
                - define cost:<yaml[plots].read[plots.<[plot_id]>.cost]||0>

            - determine <[cost]>



qm_trait_plot_events:
    type: task
    script:
        - define event_type:<[1]||<empty>>
        - define target_npc:<[2]||<empty>>
        - define target_player:<[3]||<empty>>

        - if <[event_type]> == click:
            - determine <list[qm_trait_plotmaster_item|qm_trait_plotmaster_shop]>


qm_trait_plotmaster_item:
    type: item
    material: grass_block
    display name: <&d>Plots

qm_trait_plotmaster_buy_item:
    type: item
    material: grass_block
    display name: '<&d>Buy Plot'

qm_trait_plotmaster_sell_item:
    type: item
    material: grass_path
    display name: '<&d>Sell Plot'


qm_trait_plotmaster_shop:
    type: task
    script:
        - define buy_plots:<list[]>
        - define sell_plots:<list[]>
        - define npc_id:<player.flag[npc_engaged].as_npc.id>

        - foreach <yaml[plots].list_keys[plots]>:
            - define plot_id:<[value]>
            - if <yaml[plots].read[plots.<[plot_id]>.npc].contains[<[npc_id]>]||false>:
                - define owner_id:<yaml[plots].read[plots.<[plot_id]>.owner]||<empty>>
                - if <[owner_id]> == <player.uuid>:
                    - define sell_plots:->:<[plot_id]>
                - else if <[owner_id]> == <empty>:
                    - define buy_plots:->:<[plot_id]>

        - if <[buy_plots].size> > 0 || <[sell_plots].size> > 0:
            - define slots:<map[]>
            - note "in@generic[size=45;title=Plots]" as:plots_<player.uuid>
            - inventory set d:in@plots_<player.uuid> o:<[slots]>

            - foreach <[buy_plots]>:
                - define plot_id:<[value]>
                - define slot_id:<[slots].keys.highest.add[1]||1>
                - define slots:<[slots].with[<[slot_id]>].as[qm_trait_plotmaster_buy_item]>
                - inventory set d:in@plots_<player.uuid> slot:<[slot_id]> o:qm_trait_plotmaster_buy_item
                
                - define name:<yaml[plots].read[plots.<[plot_id]>.name]>
                - define cost:<yaml[plots].read[plots.<[plot_id]>.cost]||0>

                - if <[cost]> > 0:
                    - define cost:<proc[qmp_server.format.money].context[<[cost]>]>
                - else:
                    - define cost:<proc[qmp_language].context[free|price]>
                
                - inventory adjust d:in@plots_<player.uuid> slot:<[slot_id]> 'lore:<&f><[name]>  - <[cost]><&0>/<[value]>'

            - define slot_id:45
            - foreach <[sell_plots]>:
                - define plot_id:<[value]>
                - define slots:<[slots].with[<[slot_id]>].as[qm_trait_plotmaster_sell_item]>
                - inventory set d:in@plots_<player.uuid> slot:<[slot_id]> o:qm_trait_plotmaster_sell_item
                
                - define name:<yaml[plots].read[plots.<[plot_id]>.name]>
                - define cost:<yaml[plots].read[plots.<[plot_id]>.cost]||0>

                # - foreach <yaml[plots].read[plots.<[plot_id]>.cuboid].blocks>:
                #     - if !<list[air|dirt|grass_block|stone|granite|diorite|iron_ore].contains[<[value].block.material.name>]>:
                #         - narrate <[value].block.material.name>
                #         - define cost:+:<proc[qmp_prices.get.sell.price].context[<[value].block.material.name>]>

                - if <[cost]> > 0:
                    - define cost:<proc[qmp_server.format.money].context[<[cost]>]>
                - else:
                    - define cost:<proc[qmp_language].context[free|price]>

                - inventory adjust d:in@plots_<player.uuid> slot:<[slot_id]> 'lore:<&f><[name]>  - <[cost]><&0>/<[value]>'
                - define slot_id:--

            - inventory open d:in@plots_<player.uuid>
        - else:
            - narrate <proc[qmp_language].context[no_plots_available|plotmaster]>


            

trait_plot_cmd:
    type: task
    debug: true
    script:
        - define action:<[1].get[command]||null>
        - define option:<[1].get[option]||null>
        - define value:<[1].get[args].get[1]||null>

        - choose <[option]>:
            - case add create:
                - define id:<yaml[plots].list_keys[plots].highest||0>
                - define id:<[id].add[1]>
                - yaml id:plots set plots.<[id]>.cuboid:<player.we_selection>
                - narrate 'xxplot <[id]> created'
                - run trait_plot.yaml.save
            - case update:
                - if <[value]> != null:
                    - if <yaml[plots].read[plots.<[value]>.cuboid]||null> != null:
                        - yaml id:plots set plots.<[value]>.cuboid:<player.we_selection>
                        - narrate 'xxplot updated'
                    - else:
                        - narrate 'xxno plot id doesnt exist'
                - else:
                    - narrate 'xxno plot id entered'
            - case del delete rem remove:
                - if <[value]> != null:
                    - if <yaml[plots].read[plots.<[value]>.cuboid]||null> != null:
                        - yaml id:plots set plots.<[value]>:!
                        - narrate 'xxplot removed'
                    - else:
                        - narrate 'xxno plot id doesnt exist'
                - else:
                    - narrate 'xxno plot id entered'
            - case name:
                - if <[value]> != null:
                    - if <yaml[plots].read[plots.<[value]>.cuboid]||null> != null:
                        - narrate <[1].get[args].get[2]>
                        - define name:<[1].get[args].get[2]||null>
                        - if <[name]> != null:
                            - yaml id:plots set plots.<[value]>.name:<[name]>
                            - narrate 'xxplot name updated'
                        - else:
                            - narrate 'xxno name entered'
                    - else:
                        - narrate 'xxno plot id doesnt exist'
                - else:
                    - narrate 'xxno plot id entered'
            - case npc:
                - if <[value]> != null:
                    - if <yaml[plots].read[plots.<[value]>.cuboid]||null> != null:
                        - define target_npc:<[1].get[args].get[2]||null>
                        - if <[target_npc]> != null:
                            - yaml id:plots set plots.<[value]>.npc:->:<[target_npc]>
                            - narrate 'xxplot npc added'
                        - else:
                            - narrate 'xxno npc entered'
                    - else:
                        - narrate 'xxno plot id doesnt exist'
                - else:
                    - narrate 'xxno plot id entered'
            - case group:
                - if <[value]> != null:
                    - if <yaml[plots].read[plots.<[value]>.cuboid]||null> != null:
                        - define group:<[1].get[args].get[2]||null>
                        - if <[group]> != null:
                            - yaml id:plots set plots.<[value]>.group:<[group]>
                            - narrate 'xxplot gtoup updated'
                        - else:
                            - narrate 'xxno npc entered'
                    - else:
                        - narrate 'xxno plot id doesnt exist'
                - else:
                    - narrate 'xxno plot id entered'
            - case cost:
                - if <[value]> != null:
                    - if <yaml[plots].read[plots.<[value]>.cuboid]||null> != null:
                        - define group:<[1].get[args].get[2]||null>
                        - if <[group]> != null:
                            - yaml id:plots set plots.<[value]>.cost:<[group]>
                            - narrate 'xxplot cost updated'
                        - else:
                            - narrate 'xxno vost entered'
                    - else:
                        - narrate 'xxno plot id doesnt exist'
                - else:
                    - narrate 'xxno plot id entered'
            - case sign:
                - if <[value]> != null:
                    - if <yaml[plots].read[plots.<[value]>.cuboid]||null> != null:
                        - if <player.cursor_on.material.contains[sign]>:
                            - yaml id:plots set plots.<[value]>.sign:<player.cursor_on>
                            - narrate 'xxplot sign updated'
                        - else:
                            - narrate 'xxcursor is not on a sign'
                    - else:
                        - narrate 'xxno plot id doesnt exist'
                - else:
                    - narrate 'xxno plot id entered'
            - case signupdate:
                - foreach <yaml[plots].list_keys[plots]>:
                    - run qm_trait_plot.sign.update def:<[value]>
