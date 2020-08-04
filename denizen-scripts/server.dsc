server_handler:
    type: world
    debug: false
    events:
        on server start:
        - if <server.has_file[/serverdata/server.yml]>:
            - yaml load:/serverdata/server.yml id:server
            - inject locally server_yaml_defaults
        - else:
            - yaml create id:server
            - inject locally server_yaml_defaults
            - yaml savefile:/serverdata/server.yml id:server

    server_yaml_defaults:
    - if !<yaml[server].contains[Flags.Chat]>:
        - yaml id:server set Flags.Chat:1


server_yaml_save:
    type: task
    script:
    - yaml savefile:/serverdata/server.yml id:server