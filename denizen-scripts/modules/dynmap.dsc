dynmap:
    type: world
    debug: true
    events:
        on load:
            - run qm_command.add.command def:dynmap_cmd|dynmap|developer
            - run qm_command.add.tabcomplete def:dynmap|sync
            # - run qm_lang.add def:dynmap


dynmap_cmd:
    type: task
    debug: true
    script:
        - define action:<[1].get[command]||null>
        - define option:<[1].get[option]||null>
        - define region:<[1].get[args].get[1]||null>
        - define value:<[1].get[args].get[2]||null>

        - choose <[action]>:
            - case dynmap:
                - choose <[option]>:
                    - case sync:
                        - execute as_server 'dmarker deleteset id:towns'
                        - execute as_server 'dmarker addset id:towns Towns hide:false prio:0'
                        - execute as_server 'dmarker deleteset id:areas'
                        - execute as_server 'dmarker addset id:areas Areas hide:false prio:0'
                        - execute as_server 'dmarker deleteset id:creative'
                        - execute as_server 'dmarker addset id:creative Creative hide:false prio:0'
                        - foreach <yaml[regions].list_keys[regions]||<list[]>>:
                            - if <yaml[regions].read[regions.<[value]>.title]||null> != null:
                                - choose <yaml[regions].read[regions.<[value]>.type]||null>:
                                    - case town:
                                        - execute as_server 'dmarker add id:<[value]> "<yaml[regions].read[regions.<[value]>.title]>" icon:default set:towns x:<yaml[regions].read[regions.<[value]>.cuboid].center.x.round> y:64 z:<yaml[regions].read[regions.<[value]>.cuboid].center.z.round> world:<yaml[regions].read[regions.<[value]>.cuboid].center.world.name>'
                                    - case creative:
                                        - execute as_server 'dmarker add id:<[value]> "<yaml[regions].read[regions.<[value]>.title]>" icon:hammer set:creative x:<yaml[regions].read[regions.<[value]>.cuboid].center.x.round> y:64 z:<yaml[regions].read[regions.<[value]>.cuboid].center.z.round> world:<yaml[regions].read[regions.<[value]>.cuboid].center.world.name>'
                                    - default:
                                        - execute as_server 'dmarker add id:<[value]> "<yaml[regions].read[regions.<[value]>.title]>" icon:pin set:areas x:<yaml[regions].read[regions.<[value]>.cuboid].center.x.round> y:64 z:<yaml[regions].read[regions.<[value]>.cuboid].center.z.round> world:<yaml[regions].read[regions.<[value]>.cuboid].center.world.name>'
                                - narrate 'Added <[value]>'
                        - narrate 'Dynmap updated'