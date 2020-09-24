qmw_trait_guard:
    type: world
    events:
        on load:
            - run qm_npc.trait.register def:guard|qm_trait_guard_events
        
        on trait added guard:
            - define region_list:<proc[qmp_region.find.list].context[<context.npc.location>]>
            - define prefix:<element[]>

            - foreach <[region_list]>:
                - if <proc[qmp_region.get.type].context[<[value]>]> == town:
                    - define 'prefix:<proc[qmp_region.get.title].context[<[value]>]> '
                    - foreach stop

            - adjust <player> selected_npc:<context.npc>
            - trait state:true sentinel to:<context.npc>

            - narrate <context.npc.inventory>
            - if !<context.npc.inventory.contains[crossbow]>:
                - give crossbow to:<context.npc.inventory>
            - if !<context.npc.inventory.contains[netherite_sword]>:
                - give netherite_sword to:<context.npc.inventory>
                
            - wait 1t
            - execute as_op 'sentinel autoswitch true'
            - execute as_op 'sentinel addtarget monsters'
            - execute as_op 'sentinel addtarget event:pvp'
            - execute as_op 'sentinel addtarget event:pvsentinel'
            - execute as_op 'sentinel spawnpoint'
            - execute as_op 'sentinel removeignore owner'
            - execute as_op 'sentinel invincible true'
            - execute as_op 'sentinel range 50'
            - execute as_op 'sentinel chaserange 70'
            - execute as_op 'sentinel realistic true'

            - adjust <context.npc> name:<&2><[prefix]>Guard
            - adjust <context.npc> item_in_offhand:shield
            - run qm_skin.set def:<context.npc>|guard
        
        on trait removed guard:
            - define name:<proc[qmp_npc.get.name].context[<context.npc.id>]||<empty>>
            - if <[name]> != <empty>:
                - adjust <context.npc> name:<[name]>
            
            - trait state:false sentinel to:<context.npc>

qm_trait_guard_events:
    type: task
    script:
        - determine <empty>