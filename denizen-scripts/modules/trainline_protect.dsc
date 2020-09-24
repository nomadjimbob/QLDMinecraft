qm_trainline_protect:
    type: world
    debug: false
    protect_radius: 5
    events:
        on player places block:
            - if !<player.in_group[developer]>:
                - define radius:<script[qm_trainline_protect].data_key[protect_radius]||5>
                - if <context.location.find.blocks[rail].within[<[radius]>].size> != 0:
                    - narrate 'XXYou cannot place blocks this close to a railway'
                    - determine cancelled

        on player breaks block:
            - if !<player.in_group[developer]>:
                - define radius:<script[qm_trainline_protect].data_key[protect_radius]||5>
                - if <context.location.find.blocks[rail].within[<[radius]>].size> != 0:
                    - narrate 'XXYou cannot break blocks this close to a railway'
                    - determine cancelled

        on entity explodes:
            - define radius:<script[qm_trainline_protect].data_key[protect_radius]||5>
            - foreach <context.blocks>:
                - if <[value].find.blocks[rail].within[<[radius]>].size> == 0:
                    - define blocks:->:<[value]>
            
            - if <[blocks]||null> != null:
                - determine passively <[blocks]>
