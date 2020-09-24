qm_trait_banker:
    type: world
    events:
        on load:
            - run qm_npc.trait.register def:banker|qm_trait_banker_events

        on player closes inventory:
            - if '<context.inventory.title.starts_with[Bank Vault]>':
                - define slots <context.inventory.map_slots>
                - note remove as:bankvault_<player.uuid>
                - ~yaml id:<player.uuid> set bankvault.slots:<[slots]>
                - run qm_player.yaml.save def:<player>


qm_trait_banker_events:
    type: task
    script:
        - define event_type:<[1]||<empty>>
        - define target_npc:<[2]||<empty>>
        - define target_player:<[3]||<empty>>

        - if <[event_type]> == click:
            - determine <list[qm_trait_banker_shop_item|qm_trait_banker_shop]>


qm_trait_banker_shop_item:
    type: item
    material: chest
    display name: Bank


qm_trait_banker_shop:
    type: task
    script:
        - define bankvault_slots:<yaml[<player.uuid>].read[bankvault.size]||0>
        - if <[bankvault_slots]> > 0:
            - define slots:<yaml[<player.uuid>].read[bankvault.slots]||<map[]>>
            - note "in@generic[size=<[bankvault_slots]>;title=Bank Vault]" as:bankvault_<player.uuid>
            - inventory set d:in@bankvault_<player.uuid> o:<[slots]>
            - inventory open d:in@bankvault_<player.uuid>
        - else:
            - narrate <proc[qmp_language].context[no_access|banker]>
