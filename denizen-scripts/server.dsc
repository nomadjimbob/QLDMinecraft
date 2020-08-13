# File:     server.dsc
# Contains: Server Base Handler
# Package:  QLD Minecraft
# Build:    114
# URL:      http://play.qldminecraft.com.au/

server_handler:
    type: world
    debug: true
    events:

        # server start
        on server start:
        - ~run qm_server_yaml_load
        - execute as_server "train removeall"


        # 5 minute timer
        on system time minutely every:5:

            # save server data
            - run qm_server_yaml_save

            # save player data
            - foreach <server.online_players>:
                - run qm_player_yaml_save def:<[value]>

            # regenerate regions
            - define regionList:<yaml[server].list_keys[regions]||null>
            - if <[regionList]> != null:
                - foreach <[regionList]>:
                    - define regenerateList:<list[block|spawn]>
                    - foreach <[regenerateList]>:
                        - define regenerateType:<[value]>
                        - define regenerateList:<yaml[server].read[regions.<[value]>.regenerate.interval.<[regenerateType]>]||null>
                        - if <[regenerateList]> != null:
                            - foreach <[regenerateList]>:
                                - define region:<yaml[server].read[regions.<[value]>.cuboid]>
                                - chunkload <[region].partial_chunks>
                                
                                - define itemType:<[value]>

                                - if <[regenerateType]> == block:
                                    - define itemCount:<[region].blocks[<[itemType]>].size>
                                - else if <[regenerateType]> == spawn:
                                    - define itemCount:<[region].living_entities[<[itemType]>].size>
                                - else:
                                    - foreach stop
                                
                                - define itemAmount:<yaml[server].read[regions.<[value]>.regenerate.interval.<[regenerateType]>.<[itemType]>]||0>
                                - define itemMin:<yaml[server].read[regions.<[value]>.regenerate.min.<[regenerateType]>.<[itemType]>]||0>
                                - define itemMax:<yaml[server].read[regions.<[value]>.regenerate.max.<[regenerateType]>.<[itemType]>]||0>

                                - if <[itemAmount]> < 1:
                                    - foreach stop
                                - if <[itemMin]> > 0 && <[itemCount]> < <[itemMin]>:
                                    - define itemAmount:+:<[itemMin].sub[<[itemCount]>]>
                                - if <[itemMax]> > 0 && <[itemCount]>:
                                    - define itemAmount:<[itemMax].sub[<[itemCount]>]>
                                
                                - define attempts:0
                                - while <[itemAmount]> > 0:
                                    - define attemps:++
                                    - if <[attempts]> > <[itemAmount].mul[3]>:
                                        - stop
                                    
                                    - define x:<util.random.int[<[region].min.x>].to[<[region].max.x>]>
                                    - define z:<util.random.int[<[region].min.z>].to[<[region].max.z>]>
                                    - define y:<[region].min.y>
                                    - define ymax:<[region].max.y>

                                    - while <[y]> < <[ymax]>:
                                        - define loc:<location[<[x]>,<[y]>,<[z]>,<[region].min.world.name>]>
                                        - if <[loc].material.name> == air:
                                            - if <[regenerateType]> == block:
                                                - modifyblock <[loc]> <[itemType]>
                                            - else if <[regenerateType]> == spawn:
                                                - spawn <[loc]> <[itemType]>
                                            
                                            - define amount:--
                                            - while stop
                                            
                                        - define y:++


# Load server data
qm_server_yaml_load:
    type: task
    script:
        - if <server.has_file[/serverdata/server.yml]>:
            - ~yaml load:/serverdata/server.yml id:server
        - else:
            - ~yaml create id:server
            - yaml savefile:/serverdata/server.yml id:server

        - ~run qm_server_sync_regions


# Saves server data
qm_server_yaml_save:
    type: task
    script:
        - yaml savefile:/serverdata/server.yml id:server


# Sync Regions
qm_server_sync_regions:
    type: task
    script:
        - foreach <server.notables[cuboids]>:
            - note remove as:<[value].note_name>
        
        - define regions:<yaml[server].list_keys[regions]||null>
        - if <[regions]> != null:
            - foreach <[regions]>:
                - define region:<yaml[server].read[regions.<[value]>.cuboid]||null>
                - if <[region]> != null:
                    - note <[region]> as:<[value]>