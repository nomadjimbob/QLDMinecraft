# todo when buying items, lore is not updated
# todo when editing a shop, it is cleared!

qm_shopkeeper:
    type: world
    events:
        on load:
            - run qm_npc.trait.register def:shopkeeper|qm_shopkeeper_events
            - run qm_shopkeeper.yaml.load

            # todo change qm_shopkeeper_events to qm_shopkeeper_trrait_events
        
        on save:
            - run qm_shopkeeper.yaml.save

        on trait added shopkeeper:
            - if !<yaml[shopkeeper].list_keys[shops].contains[<context.npc.id>]>:
                - yaml id:shopkeeper set shops.<context.npc.id>.slots:<map[]>


        on player drags in inventory:
            - if '<context.inventory.title.starts_with[Shop Keeper]>':
                - if !<proc[qmp_server.player.in_developer_mode].context[<player>]>:
                    - determine cancelled
        
        on player clicks in inventory:
            - if '<context.inventory.title.starts_with[Shop Keeper]>':
                - if !<proc[qmp_server.player.in_developer_mode].context[<player>]>:
                    - determine passively cancelled
                    - if <inventory[shopkeeper_<player.uuid>].map_slots.get[<context.slot>].material.name||<empty>> != <empty>:
                        - if <context.clicked_inventory.title> == 'inventory':
                            - define name:<player.inventory.map_slots.get[<context.slot>].material.name||null>
                            - define cost:<proc[qmp_prices.get.sell.price].context[<[name]>]>
                            - if <[cost]> >= 0:
                                - money give quantity:<[cost]>
                                - inventory adjust slot:<context.slot> 'quantity:<player.inventory.map_slots.get[<context.slot>].quantity.sub[1]>'
                                - narrate <proc[qmp_language].context[sold_item|shopkeeper|<map[material/<[name]>].escaped>]>
                                - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<player.money>]>

                                - inventory set d:in@shopkeeper_<player.uuid> slot:45 o:<[name]>
                                - inventory adjust d:in@shopkeeper_<player.uuid> slot:45 'lore:Buy back for <proc[qmp_prices.get.sell.price_text].context[<[name]>]>'
                            - else:
                                - narrate <proc[qmp_language].context[not_want|shopkeeper|<map[material/<[name]>].escaped>]>
                        - else:
                            - if <player.inventory.is_full>:
                                - narrate <proc[qmp_language].context[inventory_full|shopkeeper]>
                            - else:
                                - define name:<inventory[shopkeeper_<player.uuid>].map_slots.get[<context.slot>].material.name||null>
                                - define cost:<proc[qmp_prices.get.buy.price].context[<[name]>]>
                                - if <[cost]> <= <player.money> && <[cost]> > 0:
                                    - money take quantity:<[cost]>
                                    # - inventory adjust d:in@shopkeeper_<player.uuid> slot:<context.slot> 'quantity:<player.inventory.map_slots.get[<context.slot>].quantity.sub[1]>'
                                    - give <[name]>
                                    - narrate <proc[qmp_language].context[bought_item|shopkeeper|<map[material/<[name]>].escaped>]>
                                    - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<player.money>]>

                                    - foreach <player.inventory.map_slots.get_subset[<player.inventory.map_slots.keys.filter[is[less].than[37]]>].keys>:
                                        - inventory adjust slot:<[value]> 'lore:Sell: <proc[qmp_prices.get.sell.price_text].context[<player.inventory.map_slots.get[<[value]>].material.name||null>]>'

                                    - if <context.slot> == 45:
                                        - inventory set d:in@shopkeeper_<player.uuid> slot:45 o:air
                                - else if <[cost]> < 0:
                                    - narrate <proc[qmp_language].context[not_for_sale|shopkeeper]>
                                - else:
                                    - narrate <proc[qmp_language].context[not_enough_money|shopkeeper]>
        
        on player closes inventory:
            - if '<context.inventory.title.starts_with[Shop Keeper]>':
                - foreach <inventory[shopkeeper_<player.uuid>].map_slots.keys>:
                    - inventory adjust d:in@shopkeeper_<player.uuid> slot:<[value]> 'lore:'

                - foreach <player.inventory.map_slots.get_subset[<player.inventory.map_slots.keys.filter[is[less].than[37]]>].keys>:
                    - inventory adjust slot:<[value]> 'lore:'

                - if <proc[qmp_server.player.in_developer_mode].context[<player>]>:
                    - define slots <context.inventory.map_slots>
                    - yaml id:shopkeeper set shops.<player.selected_npc.id>.slots:<[slots]>
                    - run qm_shopkeeper.yaml.save
                

                - note remove as:shopkeeper_<player.uuid>

        

    yaml:
        load:
            - if <server.has_file[/serverdata/shopkeeper.yml]>:
                - yaml load:/serverdata/shopkeeper.yml id:shopkeeper
            - else:
                - yaml create id:shopkeeper

            - run qm_shopkeeper.yaml.save

        save:
            - yaml savefile:/serverdata/shopkeeper.yml id:shopkeeper



qm_shopkeeper_events:
    type: task
    script:
        - define event_type:<[1]||<empty>>
        - define target_npc:<[2]||<empty>>
        - define target_player:<[3]||<empty>>

        - if <[event_type]> == click:
            - determine <list[qm_shopkeeper_shop|trait_shop_menu]>


qm_shopkeeper_shop:
    type: item
    material: armor_stand
    display name: Shop


trait_shop_menu:
    type: task
    script:
        - define 'title:Shop Keeper'
        - if <proc[qmp_server.player.in_developer_mode].context[<player>]>:
            - define 'title:Shop Keeper (Edit)'

        - note "in@generic[size=45;title=<[title]>]" as:shopkeeper_<player.uuid>
        - define slots:<yaml[shopkeeper].read[shops.<player.flag[npc_engaged].as_npc.id>.slots].as_map||<map[]>>
        - inventory set d:in@shopkeeper_<player.uuid> o:<[slots]>

        - foreach <inventory[shopkeeper_<player.uuid>].map_slots.keys>:
            - inventory adjust d:in@shopkeeper_<player.uuid> slot:<[value]> 'lore:Buy: <proc[qmp_prices.get.buy.price_text].context[<inventory[shopkeeper_<player.uuid>].map_slots.get[<[value]>].material.name||null>]>'

        - foreach <player.inventory.map_slots.get_subset[<player.inventory.map_slots.keys.filter[is[less].than[37]]>].keys>:
            - inventory adjust slot:<[value]> 'lore:Sell: <proc[qmp_prices.get.sell.price_text].context[<player.inventory.map_slots.get[<[value]>].material.name||null>]>'

        - adjust <player> selected_npc:<player.flag[npc_engaged].as_npc>
        - inventory open d:in@shopkeeper_<player.uuid>
        - narrate <proc[qmp_language].context[money_amount|server]><proc[qmp_server.format.money].context[<player.money>]>
