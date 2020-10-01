qm_sql:
    type: task
    debug: false
    username: qm
    password: NONE
    script:
        - define def_id:1

        - if <server.sql_connections.contains[mysql]||false>:
            - ~sql id:mysql disconnect

        - ~sql id:mysql connect:localhost:3306/qldminecraft username:<script[qm_sql].data_key[username]> password:<script[qm_sql].data_key[password]>
        
        - while <queue.definition[<[def_id]>]> != null:
            - ~sql id:mysql update:<queue.definition[<[def_id]>]>
            - define def_id:++
        
        - ~sql id:mysql disconnect


qmw_sql:
    type: world
    debug: false
    events:
        after player joins:
            - run qm_sql 'def:INSERT into login(datetime,uuid,action) VALUES("<util.time_now.epoch_millis>","<player.uuid>","0");|INSERT into username(uuid,username) VALUES("<player.uuid>","<player.name.sql_escaped>");'
        
        on player quits:
            - run qm_sql 'def:INSERT into login(datetime,uuid,action) VALUES("<util.time_now.epoch_millis>","<player.uuid>","1");'

        on player chats:
            - run qm_sql 'def:INSERT into chat(datetime,fromuuid,message) VALUES("<util.time_now.epoch_millis>","<player.uuid>","<context.message.sql_escaped>");'
