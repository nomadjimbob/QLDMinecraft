qm_trait_firstjoin:
    type: world
    events:
        on load:
            - run qm_npc.trait.register def:firstjoin|qm_trait_firstjoin_events
        
        on trait proximity entry firstjoin:
            - if <yaml[<player.uuid>].read[first_join]||0> == 0:
                - define 'text:Howdy there $NAME$'
                - narrate <proc[qmp_chat].context[<context.npc>|<[text]>|<map[name/<player.name>].escaped>]>
                - wait 2s
                - define 'text:Glad you finally woke up...'
                - narrate <proc[qmp_chat].context[<context.npc>|<[text]>|<map[name/<player.name>].escaped>]>
                - wait 3s
                - define 'text:We have arrived at Ironport'
                - narrate <proc[qmp_chat].context[<context.npc>|<[text]>|<map[name/<player.name>].escaped>]>
                - wait 5s
                - define 'text:When your ready, tap on me and I will give you your things'
                - narrate <proc[qmp_chat].context[<context.npc>|<[text]>|<map[name/<player.name>].escaped>]>
                - yaml id:<player.uuid> set first_join:1
                


qm_trait_firstjoin_events:
    type: task
    script:
        - define event_type:<[1]||<empty>>
        - define target_npc:<[2]||<empty>>
        - define target_player:<[3]||<empty>>

        - if <[event_type]> == click:
            - if <yaml[<[target_player].uuid>].read[first_join]||0> <= 1:
                - if <yaml[<[target_player].uuid>].read[first_join]||0> == 1:
                    - define 'text:Oi, not so hard...'
                    - narrate <proc[qmp_chat].context[<[target_npc]>|<[text]>|<map[name/<[target_player].name>].escaped>]>
                    - wait 2s
                    - define 'text:Here you go, that is all you brought'
                    - narrate <proc[qmp_chat].context[<[target_npc]>|<[text]>|<map[name/<[target_player].name>].escaped>]>
                    - foreach <yaml[server].list_keys[first_join.items]||<list[]>>:
                        - give <[value]> qty:<yaml[server].read[first_join.items.<[value]>]> to:<[target_player].inventory>
                    - wait 2s
                    - define 'text:...'
                    - narrate <proc[qmp_chat].context[<[target_npc]>|<[text]>|<map[name/<[target_player].name>].escaped>]>
                    - wait 2s
                    - define 'text:Hey you got a guide! You should read that, it may have some info about this place'
                    - narrate <proc[qmp_chat].context[<[target_npc]>|<[text]>|<map[name/<[target_player].name>].escaped>]>
                    - define 'text:Good luck $NAME$'
                    - narrate <proc[qmp_chat].context[<[target_npc]>|<[text]>|<map[name/<[target_player].name>].escaped>]>
                    - yaml id:<[target_player].uuid> set first_join:2
                    - determine greeting:false