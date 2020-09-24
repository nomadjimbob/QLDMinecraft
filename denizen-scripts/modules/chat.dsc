qmw_chat:
    type: world
    debug: false
    events:
        on player chats:
            - if <server.sql_connections.contains[mysql]||false> == false:
                - ~sql id:mysql connect:localhost:3306/qldminecraft username:qm password:XXHIDDENXX
            - sql id:mysql 'update:INSERT into chat(datetime,fromuuid,message) VALUES("<util.time_now.epoch_millis>","<player.uuid>","<context.message.sql_escaped>");'

            - if <proc[qmp_player.is_developer].context[<player>]>:
                - determine RAW_FORMAT:<proc[qmp_chat].context[<player>|<context.message>]>
            - else:
                - determine RAW_FORMAT:<proc[qmp_chat].context[<player>|<context.message>]>
            

qmp_chat:
    type: procedure
    debug: true
    script:
        - define entity:<[1]||<empty>>
        - define colour:f
        - define name:<[entity].name.strip_color||<[entity]>>
        - define message:<[2]||<empty>>

        - if <[message].contains_text[$]>:
            - define subs:<[3].unescaped||<map[]>>

            - if <[subs]> != null:
                - foreach <[subs].as_map.keys>:
                    - define message:<[message].replace_text[$<[value]>$].with[<[subs].as_map.get[<[value]>]>]>

        - if <[name]> != <empty>:
            - if <[entity].is_player>:
                - if <proc[qmp_player.is_developer].context[<[entity]>]>:
                    - define colour:d
            - else if <[entity].is_npc>:
                - define colour:6
            
            - if <[message].starts_with[*]>:
                - determine '<element[&<[colour]><[name]> <[message].after[*]>].parse_color>'
            - else:
                - determine '<element[&<[colour]>[<[name]>]: <[message]>].parse_color>'

        
            

    # player:
    #     - determine '<&e>[<[1]>]: <[2]>'
    
    # developer:
    #     - determine '<&d>[<[1]>]: <[2]>'

    # npc:
    #     - define name:<[1]||null>
    #     - define text:<[2]||null>
    #     - if <[text].contains_text[$]>:
    #         - define subs:<[3].unescaped||<map[]>>

    #         - if <[subs]> != null:
    #             - foreach <[subs].as_map.keys>:
    #                 - define text:<[text].replace_text[$<[value]>$].with[<[subs].as_map.get[<[value]>]>]>

    #     # todo if name is <empty>, dont include []!

    #     - determine '<&6>[<[name]>]: <[text]>'