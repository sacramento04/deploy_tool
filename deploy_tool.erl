-module(deploy_tool).

-export([main/0]).

%% show
-define(MSG(S), io:format(S)).
-define(MSG(S, A), io:format(S, A)).

%% transform
-define(A2L(A), erlang:atom_to_list(A)).
-define(T2L(T), erlang:tuple_to_list(T)).
-define(T2B(T), erlang:term_to_binary(T)).
-define(A2B(A), erlang:atom_to_binary(A, utf8)).
-define(B2L(B), erlang:binary_to_list(B)).
-define(B2I(B), erlang:list_to_integer(?B2L(B))).
-define(I2L(I), erlang:integer_to_list(I)).
-define(L2B(S), erlang:list_to_binary(S)).
-define(L2I(S), erlang:list_to_integer(S)).
-define(L2A(S), erlang:list_to_atom(S)).

%% character
-define(TUP(S), string:to_upper(S)).
-define(TLW(S), string:to_lower(S)).

%% dict
-define(SDF(N, V), erlang:put(N, V)).
-define(GDF(N), erlang:get(N)).
-define(EDF(N), erlang:erase(N)).

%% file
-define(FOPEN(F, M), file:open(F, M)).
-define(FCLOSE(F), file:close(F)).
-define(FREAD(F), file:read_file(F)).
-define(FWRITE(F, S), file:pwrite(F, cur, ?L2B(S))).
-define(FWRITE(F, S, O), file:pwrite(F, {cur, O}, ?L2B(S))).

%% filename
-define(FN_JN(L), filename:join(L)).
-define(FN_NN(P), filename:nativename(P)).
-define(FN_NN_JN(L), ?FN_NN(?FN_JN(L))).
-define(FN_SP(P), filename:split(P)).
-define(FN_JN2(L1, L2), filename:join(L1, L2)).


main () ->
    Line = io:get_line(standard_io, 
        "\n===================================="
        "====================================\n"
        "1 -- deploy server\n"
        "2 -- update database\n"
        "3 -- import database\n"
        "4 -- clean server\n"
        "5 -- start server\n"
        "6 -- reload module\n"
        "7 -- generate php\n"
        "8 -- stop server\n"
        "0 -- test\n"
        "<other key to exit>\n"
        "(0-8):"),
    
    case re:run(Line, "(.*)\n", [{capture, [1], list}]) of
        {match, [Option]} -> run(Option);
        _ -> ok
    end.
    
get_config () ->
    {ok, [Config]} = file:consult("config.hrl"),
    Config.
    
run ("1") ->
    ?MSG("Run step:  deploy server~n"),
    run_deploy_server(get_config()),
    main();
run ("2") ->
    ?MSG("Run step:  update database~n"),
    run_update_database(get_config()),
    main();
run ("3") ->
    ?MSG("Run step:  import database~n"),
    run_import_database(get_config()),
    main();
run ("4") ->
    ?MSG("Run step:  clean server~n"),
    run_clean_server(get_config()),
    main();
run ("5") ->
    ?MSG("Run step:  start server~n"),
    run_start_server(get_config()),
    main();
run ("6") ->
    ?MSG("Run step:  reload module~n"),
    run_reload_module(get_config()),
    main();
run ("7") ->
    ?MSG("Run step:  generate php~n"),
    run_generate_server_php(get_config()),
    main();
run ("8") ->
    ?MSG("Run step:  stop server~n"),
    run_stop_server(get_config()),
    main();
run ("0") ->
    ?MSG("Run step:  test~n"),
    main();
run (_) ->
    ok.
    
run_deploy_server (Config) ->   
    OS = os:type(),
    create_server_dir(Config, OS),
    copy_need_files(Config, OS),
    generate_start_script(Config, OS),
    generate_server_app(Config, OS),
    generate_node_txt(Config, OS),
    generate_assault_txt(Config, OS),
    generate_army_search_node_txt(Config, OS),
    generate_army_node_txt(Config, OS).
    
run_update_database (Config) ->
    OS = os:type(),
    create_database_config(Config, OS),
    update_database(Config, OS),
    restore_database_config(Config, OS).
    
run_import_database (Config) ->
    OS = os:type(),
    export_database(Config, OS),
    create_database_config(Config, OS),
    import_database(Config, OS),
    restore_database_config(Config, OS).
    
run_clean_server (Config) ->
    OS = os:type(),
    remove_server_dir(Config, OS).
    
run_start_server (Config) ->
    OS = os:type(),
    start_server(Config, OS).
    
run_reload_module (Config) ->
    OS = os:type(),
    copy_change_module(Config, OS),
    reloader_doit(Config).
    
run_generate_server_php (Config) ->
    OS = os:type(),
    generate_game_php(Config, OS),
    generate_chat_php(Config, OS),
    generate_assault_php(Config, OS),
    generate_army_search_php(Config, OS),
    generate_army_server_php(Config, OS).
    
run_stop_server (Config) ->
    OS = os:type(),
    stop_server(Config, OS).
    
create_server_dir (Config, {win32, _}) ->
    create_server_dir(Config);
create_server_dir (Config, {unix, _}) ->
    create_server_dir(Config);
create_server_dir (_, _) ->
    exit(system_not_supported).
    
create_server_dir (Config) ->
    #{game_server := GameServerList, deploy_path := DeployPath} = Config,
    {Path1, Path2} = lists:split(1, ?FN_SP(DeployPath)),
    ensure_dir(Path1, Path2),

    lists:foreach(fun (R) ->
        #{name := N} = R,
        file:make_dir(?FN_JN([DeployPath, N])),
        file:make_dir(?FN_JN([DeployPath, N, "ebin"]))
    end, 
    GameServerList).
    
copy_need_files (Config, {win32, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        project_path := ProjectPath, source_code := SourceCode} = Config,
        
    lists:foreach(fun (R) ->
        #{name := N} = R,
        ?MSG("copy files to ~p ...~n", [N]),
        SrcDir = [ProjectPath, "server_new"],
        DstDir = [DeployPath, N],
        
        os:cmd("copy /y " ++ ?FN_NN_JN(SrcDir ++ ["ebin", "*.beam"]) ++
            " " ++ ?FN_NN_JN(DstDir ++ ["ebin"])),
        
        case SourceCode of
            true ->
                os:cmd("copy /y " ++ 
                    ?FN_NN_JN(SrcDir ++ ["ebin", "*.erl"]) ++ " " ++
                    ?FN_NN_JN(DstDir ++ ["ebin"])),
                os:cmd("xcopy " ++ 
                    ?FN_NN_JN(SrcDir ++ ["include"]) ++ " " ++
                    ?FN_NN_JN(DstDir ++ ["include"]) ++ 
                    ?FN_NN("/") ++ " /s/e/y"),
                os:cmd("xcopy " ++ 
                    ?FN_NN_JN(SrcDir ++ ["src"]) ++ " " ++
                    ?FN_NN_JN(DstDir ++ ["src"]) ++ 
                    ?FN_NN("/") ++ " /s/e/y");
            _ ->
                ok
        end
    end,
    GameServerList);
copy_need_files (Config, {unix, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        project_path := ProjectPath} = Config,
        
    lists:foreach(fun (R) ->
        #{name := N} = R,
        ?MSG("copy files to ~p ...~n", [N]),
        SrcDir = [ProjectPath, "server_new"],
        DstDir = [DeployPath, N],
        
        os:cmd("cp " ++ ?FN_NN_JN(SrcDir ++ ["ebin", "*.beam"]) ++
            " " ++ ?FN_NN_JN(DstDir ++ ["ebin"]))
    end,
    GameServerList);
copy_need_files (_, _) ->
    exit(system_not_supported).
    
generate_start_script (Config, {win32, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        local_ip := LocalIP, local_db_port := LocalDP, local_db_user := LocalDU, 
        local_db_password := LocalDPW, build_code_db := Codedb} = Config,
        
    lists:foreach(fun (R) ->
        #{name := N, server_port := SP, http_port := HP} = R,
        {ok, Fd} = ?FOPEN(?FN_JN([DeployPath, N, "start.bat"]), [write]),
        
        ?FWRITE(Fd, 
            "@echo off\n"
            "cls\n"
            "erl ^\n"
            "-boot start_sasl ^\n"
            "-pa ebin ^\n"
            "-run game start ^\n"
            "-name " ++ N ++ "@" ++ LocalIP ++" ^\n"
            "-setcookie the_cookie ^\n"
            "-env ERL_MAX_ETS_TABLES 65535 ^\n"
            "-game ^\n\t"
            "server_port '\"" ++ SP ++ "\"' ^\n\t"
            "http_port '\"" ++ HP ++ "\"' ^\n\t"),
            
        case maps:find(db_name, R) of
            {ok, DBN} ->
                ?FWRITE(Fd, 
                    "mysql_host '127.0.0.1' ^\n\t"
                    "mysql_port '" ++ LocalDP ++ "' ^\n\t"
                    "mysql_username '" ++ LocalDU ++ "' ^\n\t"
                    "mysql_password '" ++ LocalDPW ++ "' ^\n\t"
                    "mysql_database '" ++ DBN ++ "' ^\n\t"
                    "build_code_db '" ++ ?A2L(Codedb) ++ "' ^\n\t"
                    "vsn \\\"2014060501\\\"\n"
                    "pause\n");
            _ ->
                ?FWRITE(Fd,
                    "build_code_db '" ++ ?A2L(Codedb) ++ "' ^\n\t"
                    "vsn \\\"2014060501\\\"\n"
                    "pause\n")
        end,
            
        ?FCLOSE(Fd)
    end,
    GameServerList);
generate_start_script (Config, {unix, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        local_ip := LocalIP, local_db_port := LocalDP, local_db_user := LocalDU, 
        local_db_password := LocalDPW, build_code_db := Codedb} = Config,
        
    lists:foreach(fun (R) ->
        #{name := N, server_port := SP, http_port := HP} = R,
        {ok, Fd} = ?FOPEN(?FN_JN([DeployPath, N, "start.sh"]), [write]),
        
        ?FWRITE(Fd, 
            "#!/bin/sh\n"
            "ulimit -n 50000\n"
            "erl \\\n"
            "+K true \\\n"
            "+P 10240000 \\\n"
            "-pa ebin \\\n"
            "-run game start \\\n"
            "-setcookie the_cookie \\\n"
            "-name " ++ N ++ "@" ++ LocalIP ++ " \\\n"
            "-boot start_sasl \\\n"
            "-env ERL_MAX_ETS_TABLES 65535 \\\n"
            "-game \\\n\t"
            "server_port '\"" ++ SP ++ "\"' \\\n\t"
            "http_port '\"" ++ HP ++ "\"' \\\n\t"),
        
        case maps:find(db_name, R) of
            {ok, DBN} ->
                ?FWRITE(Fd,
                    "mysql_host '\"127.0.0.1\"' \\\n\t"
                    "mysql_port '\"" ++ LocalDP ++ "\"' \\\n\t"
                    "mysql_username '\"" ++ LocalDU ++ "\"' \\\n\t"
                    "mysql_password '\"" ++ LocalDPW ++ "\"' \\\n\t"
                    "mysql_database '\"" ++ DBN ++ "\"' \\\n\t"
                    "build_code_db '" ++ ?A2L(Codedb) ++ "' \\\n\t"
                    "vsn '\"2014060501\"'\n");
            _ ->
                ?FWRITE(Fd,
                    "build_code_db '" ++ ?A2L(Codedb) ++ "' \\\n\t"
                    "vsn '\"2014060501\"'\n")
        end,
        
        ?FCLOSE(Fd),
        os:cmd("chmod u+x " ++ DeployPath ++ "/" ++ N ++ "/*.sh")
    end,
    GameServerList);
generate_start_script (_, _) ->
    exit(system_not_supported).
    
generate_server_app (Config, {win32, _}) ->
    generate_server_app(Config);
generate_server_app (Config, {unix, _}) ->
    generate_server_app(Config);
generate_server_app (_, _) ->
    exit(system_not_supported).
    
generate_server_app (Config) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        local_ip := LocalIP} = Config,
    
    lists:foreach(fun (R) ->
        #{name := N, type := T, server_num := SN} = R,
        {ok, Fd} = ?FOPEN(?FN_JN([DeployPath, N, "ebin", "game.app"]), [write]),
        
        ?FWRITE(Fd, 
            "{application, game,\n"
            "[\n\t"
            "{description, \"Game Server\"},\n\t"
            "{vsn, \"0.0.0\"},\n\t"
            "{registered, [game]},\n\t"
            "{applications, [kernel, stdlib]},\n\t"
            "{mod, {game, [" ++ ?A2L(T) ++ "]}},\n\t"
            "{env, [\n\t\t"
            "{socket_server_max_conn, 50000},\n\t\t"
            "{server_number, " ++ ?I2L(SN) ++ "},"),
            
        VipStr = case find_server(Config, vip) of
            [VS] ->
                #{name := VSN} = VS,
                "\n\t\t{vip_server_ip, '" ++ VSN ++ "@" ++ LocalIP ++ "'},";
            _ ->
                "\n\t\t{vip_server_ip, 'vip@192.168.1.73'},"
        end,
        
        case T of
            vip -> ?FWRITE(Fd, "\n\t\t{vip_server, true}," ++ VipStr);
            _ -> ?FWRITE(Fd, "\n\t\t{vip_server, false}," ++ VipStr)
        end,
        
        CommentStr = case find_server(Config, comment) of
            [CS] ->
                #{name := CSN} = CS,
                "\n\t\t{hero_comments_ip, '" ++ CSN ++ "@" ++ LocalIP ++ "'},";
            _ ->
                "\n\t\t{hero_comments_ip, 'hero_comments@192.168.1.73'},"
        end,
        
        case T of
            comment -> 
                ?FWRITE(Fd, "\n\t\t{hero_comments_server, true}," ++ CommentStr);
            _ -> 
                ?FWRITE(Fd, "\n\t\t{hero_comments_server, false}," ++ CommentStr)
        end,
            
        ?FWRITE(Fd, "\n\t\t"
            "{is_ipv6, false},\n\t\t"
            "{ipv6_port, 9526}\n\t]}\n]}.\n"),

        ?FCLOSE(Fd)
    end,
    GameServerList).
    
find_server (Config, Type) ->
    #{game_server := GameServerList} = Config,

    lists:filter(fun (R) ->
        #{type := T} = R,
        case T of Type -> true; _ -> false end
    end,
    GameServerList).
    
generate_node_txt (Config, {win32, _}) ->
    generate_node_txt(Config);
generate_node_txt (Config, {unix, _}) ->
    generate_node_txt(Config);
generate_node_txt (_, _) ->
    exit(system_not_supported).
    
generate_node_txt (Config) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        local_ip := LocalIP} = Config,
        
    NameTxt = "node.txt",
    {ok, Fd} = ?FOPEN(?FN_JN([DeployPath, NameTxt]), [write]),
    ?FWRITE(Fd, "[ "),
    
    lists:foreach(fun (R) ->
        #{name := N, server_num := SN} = R,
        ?FWRITE(Fd, "\n\t{" ++ ?I2L(SN) ++ ", '" ++ N ++ "@" ++ 
            LocalIP ++ "', []},")
    end,
    find_server(Config, game)),
    
    ?FWRITE(Fd, "\n].\n", -1),
    ?FCLOSE(Fd),
    
    lists:foreach(fun (R) ->
        #{name := N} = R,
        file:copy(?FN_JN([DeployPath, NameTxt]), 
            ?FN_JN([DeployPath, N, "ebin", NameTxt]))
    end,
    GameServerList),
    
    file:delete(?FN_JN([DeployPath, NameTxt])).
    
generate_assault_txt (Config, {win32, _}) ->
    generate_txt_by_type(Config, assault, "assault_node.txt");
generate_assault_txt (Config, {unix, _}) ->
    generate_txt_by_type(Config, assault, "assault_node.txt");
generate_assault_txt (_, _) ->
    exit(system_not_supported).
    
generate_army_search_node_txt (Config, {win32, _}) ->
    generate_txt_by_type(Config, army_group_search, 
        "army_group_search_node.txt");
generate_army_search_node_txt (Config, {unix, _}) ->
    generate_txt_by_type(Config, army_group_search, 
        "army_group_search_node.txt");
generate_army_search_node_txt (_, _) ->
    exit(system_not_supported).
    
generate_army_node_txt (Config, {win32, _}) ->
    generate_txt_by_type(Config, army_group, 
        "army_group_node.txt");
generate_army_node_txt (Config, {unix, _}) ->
    generate_txt_by_type(Config, army_group, 
        "army_group_node.txt");
generate_army_node_txt (_, _) ->
    exit(system_not_supported).
    
generate_txt_by_type (Config, Type, Filename) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        local_ip := LocalIP} = Config,

    {ok, Fd} = ?FOPEN(?FN_JN([DeployPath, Filename]), [write]),
    ?FWRITE(Fd, "[ "),
    
    lists:foreach(fun (R) ->
        #{name := N, server_num := SN} = R,
        ?FWRITE(Fd, "\n\t{" ++ ?I2L(SN) ++ ", '" ++ N ++ "@" ++ 
            LocalIP ++ "'},")
    end,
    find_server(Config, Type)),
    
    ?FWRITE(Fd, "\n].\n", -1),
    ?FCLOSE(Fd),
    
    lists:foreach(fun (R) ->
        #{name := N} = R,
        file:copy(?FN_JN([DeployPath, Filename]), 
            ?FN_JN([DeployPath, N, "ebin", Filename]))
    end,
    GameServerList),
    
    file:delete(?FN_JN([DeployPath, Filename])).
    
create_database_config (Config, {win32, _}) ->
    create_database_config(Config);
create_database_config (Config, {unix, _}) ->
    create_database_config(Config);
create_database_config (_, _) ->
    exit(system_not_supported).
    
create_database_config (Config) ->
    #{game_server := GameServerList, project_path := ProjectPath, 
        local_db_port := LocalDP, local_db_user := LocalDU, 
        local_db_password := LocalDPW} = Config,
        
    LocalIP = "127.0.0.1",
    BakFile = [ProjectPath, "database", "conf.php.bak"],
    ConfFile = [ProjectPath, "database", "conf.php"],
    
    case filelib:is_file(?FN_JN(BakFile)) of
        true -> file:delete(?FN_JN(BakFile));
        _ -> ok
    end,
    
    case filelib:is_file(?FN_JN(ConfFile)) of
        true -> file:copy(?FN_JN(ConfFile), ?FN_JN(BakFile));
        _ -> ok
    end,
    
    {ok, Fd} = ?FOPEN(?FN_JN(ConfFile), [write]),
    ?FWRITE(Fd, "<?php\n$db_argv = array( "),
    
    lists:foreach(fun (R) ->
        case maps:find(db_name, R) of
            {ok, _} ->
                #{name := N, db_name := DN} = R,
                ?FWRITE(Fd, 
                    "\n\t'" ++ N ++ "' => array(\n\t\t"
                    "'host' => '" ++ LocalIP ++ "',\n\t\t"
                    "'user' => '" ++ LocalDU ++ "',\n\t\t"
                    "'pass' => '" ++ LocalDPW ++ "',\n\t\t"
                    "'name' => '" ++ DN ++ "',\n\t\t"
                    "'port' => " ++ LocalDP ++ "\n\t),");
            _ ->
                ok
        end
    end,
    GameServerList),
    
    ?FWRITE(Fd, "\n);\n?>\n", -1),
    ?FCLOSE(Fd).
    
update_database (Config, {win32, _}) ->
    update_database(Config);
update_database (Config, {unix, _}) ->
    update_database(Config);
update_database (_, _) ->
    exit(system_not_supported).
    
update_database (Config) ->
    #{game_server := GameServerList, project_path := ProjectPath} = Config,
    
    lists:foreach(fun (R) ->
        case maps:find(db_name, R) of
            {ok, _} ->
                #{name := N} = R,
                ?MSG("update ~p ...~n", [N]),
                os:cmd("cd " ++ ?FN_NN_JN([ProjectPath, "database"]) ++ 
                    " && php main.php update " ++ N);
            _ ->
                ok
        end
    end,
    GameServerList).
    
export_database (Config, {win32, _}) ->
    export_database(Config);
export_database (_Config, {unix, _}) ->
    ok;
export_database (_, _) ->
    exit(system_not_supported).
    
export_database (Config) ->
    #{deploy_path := DeployPath, public_db_ip := PublicDIP,
        public_db_port := PublicDP, public_db_name := PublicDN,
        public_db_user := PublicDU, public_db_password := PublicDPW} = Config,

    SqlFile = [DeployPath, PublicDN ++ ".sql"],
    
    os:cmd("mysqldump --single-transaction --add-drop-table -h" ++ PublicDIP ++ 
        " -P" ++ PublicDP ++ " -u" ++ PublicDU ++ " -p" ++ PublicDPW ++ " " ++ 
        PublicDN ++ " > " ++ ?FN_NN_JN(SqlFile)).
    
import_database (Config, {win32, _}) ->
    import_database(Config);
import_database (_Config, {unix, _}) ->
    ok;
import_database (_, _) ->
    exit(system_not_supported).
    
import_database (Config) ->
    #{game_server := GameServerList, deploy_path := DeployPath,
        local_db_port := LocalDP, local_db_user := LocalDU, 
        local_db_password := LocalDPW, public_db_name := PublicDN} = Config,
    
    LocalIP = "127.0.0.1",
    SqlFile = [DeployPath, PublicDN ++ ".sql"],
    
    lists:foreach(fun (R) ->
        case maps:find(db_name, R) of
            {ok, _} ->
                #{db_name := DN} = R,
                ?MSG("import ~p ...~n", [DN]),
                os:cmd("mysql -h" ++ LocalIP ++ " -P" ++ LocalDP ++ " -u" ++
                    LocalDU ++ " -p" ++ LocalDPW ++ " " ++ DN ++ " < " ++
                    ?FN_NN_JN(SqlFile));
            _ ->
                ok
        end
    end,
    GameServerList),
    
    file:delete(?FN_JN(SqlFile)).
    
restore_database_config (Config, {win32, _}) ->
    restore_database_config(Config);
restore_database_config (Config, {unix, _}) ->
    restore_database_config(Config);
restore_database_config (_, _) ->
    exit(system_not_supported).
    
restore_database_config (Config) ->
    #{project_path := ProjectPath} = Config,
    file:delete(?FN_JN([ProjectPath, "database", "conf.php"])),
    file:rename(?FN_JN([ProjectPath, "database", "conf.php.bak"]),  
        ?FN_JN([ProjectPath, "database", "conf.php"])).
    
remove_server_dir (Config, {win32, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath} = Config,
    
    lists:foreach(fun (R) ->
        #{name := N} = R,
        os:cmd("rd /s/q " ++ ?FN_NN_JN([DeployPath, N]))
    end,
    GameServerList);
remove_server_dir (Config, {unix, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath} = Config,
    
    lists:foreach(fun (R) ->
        #{name := N} = R,
        os:cmd("rm -rf " ++ ?FN_NN_JN([DeployPath, N]))
    end,
    GameServerList);
remove_server_dir (_, _) ->
    exit(system_not_supported).
    
start_server (Config, {win32, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath} = Config,
    
    lists:foreach(fun (R) ->
        #{name := N, enable := E} = R,
        
        case E of
            true -> 
                ?MSG("start ~p ...~n", [N]),
                spawn(os, cmd, ["cd " ++ ?FN_NN_JN([DeployPath, N]) ++ 
                    " && start start.bat"]);
            _ -> 
                ok
        end
    end,
    GameServerList);
start_server (Config, {unix, _}) ->
    #{game_server := GameServerList, deploy_path := DeployPath} = Config,
    
    {ok, Fd} = ?FOPEN(?FN_JN([DeployPath, "uscreen"]), [write]),
    
    ?FWRITE(Fd, "#!/usr/bin/expect\n"
        "set sname [lindex $argv 0]\n"
        "spawn screen -S \"$sname\"\n"
        "expect -re \"#\"\n"
        "send \"cd $sname && ./start.sh\\r\"\n"
        "expect \"start\"\n"
        "send \"\\001\\004\"\n"),
        
    ?FCLOSE(Fd),
    os:cmd("cd " ++ ?FN_NN_JN([DeployPath]) ++ " && chmod u+x ./uscreen"),
    
    lists:foreach(fun (R) ->
        #{name := N, enable := E} = R,
        
        case E of
            true ->
                ?MSG("start ~p ...~n", [N]),
                os:cmd("ps -ef | grep " ++ N ++ " | grep SCREEN"
                    "| cut -c 9-15 | xargs kill"),
                os:cmd("cd " ++ ?FN_NN_JN([DeployPath]) ++ 
                    " && ./uscreen " ++ N);
            _ ->
                ok
        end
    end,
    GameServerList);
start_server (_, _) ->
    exit(system_not_supported).
    
copy_change_module (Config, {win32, _}) ->
    #{project_path := ProjectPath, game_server := GameServerList, 
        deploy_path := DeployPath, source_code := SourceCode} = Config,
        
    [GameServer | _] = GameServerList,
    #{name := GSN} = GameServer,
    SrcDir = [ProjectPath, "server_new"],
    DstDir = [DeployPath, GSN],
    
    lists:foreach(fun (RL) ->
        case RL of
            [] -> ok;
            _ ->
                copy_diff_file(Config, compare_diff_file(SrcDir ++ RL,
                    DstDir ++ RL, SourceCode), RL)
        end
    end,
    [RL -- ?FN_SP(?FN_JN(SrcDir)) || 
        RL <- find_path_dir([?FN_JN(SrcDir)], [])]);
copy_change_module (Config, {unix, _}) ->
    #{project_path := ProjectPath, game_server := GameServerList, 
        deploy_path := DeployPath, source_code := SourceCode} = Config,
        
    [GameServer | _] = GameServerList,
    #{name := GSN} = GameServer,
    SrcDir = [ProjectPath, "server_new"],
    DstDir = [DeployPath, GSN],
    
    copy_diff_file(Config, compare_diff_file(SrcDir ++ ["ebin"], 
        DstDir ++ ["ebin"], SourceCode), ["ebin"]);
copy_change_module (_, _) ->
    exit(system_not_supported).
    
compare_diff_file (SrcDir, DstDir, Code) ->
    lists:foldl(fun (F, L) ->
        SMT = filelib:last_modified(F),
        FN = filename:basename(F),
        
        case filelib:last_modified(?FN_JN(DstDir ++ [FN])) of
            0 -> [F | L];
            DMT when DMT < SMT -> [F | L];
            _ -> L
        end
    end,
    [],
    case Code of
        true -> filelib:wildcard(?FN_JN(SrcDir ++ ["*.{beam,hrl,erl}"]));
        _ -> filelib:wildcard(?FN_JN(SrcDir ++ ["*.{beam}"]))
    end).
    
copy_diff_file (_, [], _) ->
    ok;
copy_diff_file (Config, Files, Dir) ->
    #{game_server := GameServerList, deploy_path := DeployPath} = Config,
        
    lists:foreach(fun (R) ->
        #{name := N} = R,
        ensure_dir([DeployPath, N], Dir),
        
        lists:foreach(fun (F) ->
            FN = filename:basename(F),
            TF = ?FN_JN([DeployPath, N] ++ Dir ++ [FN]),
            ?MSG("copy ~p => ~p~n", [F, TF]),
            file:copy(F, TF)
        end,
        Files)
    end,
    GameServerList).
    
ensure_dir (_, []) ->
    ok;
ensure_dir (DirL1, [Dir | LeftDir]) ->
    CurDir = ?FN_JN(DirL1 ++ [Dir]),
    case filelib:is_dir(CurDir) of
        false -> file:make_dir(CurDir);
        _ -> ok
    end,
    ensure_dir(DirL1 ++ [Dir], LeftDir).
    
find_path_dir ([], Acc) -> 
    Acc;
find_path_dir ([Path | Paths], Acc) ->
    find_path_dir(Paths, case filelib:is_dir(Path) of
        false -> Acc;
        _ ->
            {ok, Listing} = file:list_dir(Path),
            SubPaths = [?FN_JN([Path, Name]) || Name <- Listing],
            find_path_dir(SubPaths, [?FN_SP(Path) | Acc])
    end).
    
reloader_doit (Config) ->
    #{game_server := GameServerList, local_ip := LocalIP} = Config,
    
    lists:foreach(fun (R) ->
        #{name := N} = R,
        Node = N ++ "@" ++ LocalIP,
        erlang:send({reloader, ?L2A(Node)}, doit)
    end,
    GameServerList).
    
generate_game_php (Config, {win32, _}) ->
    generate_php_by_type(Config, game, "game_info.php");
generate_game_php (Config, {unix, _}) ->
    generate_php_by_type(Config, game, "game_info.php");
generate_game_php (_, _) ->
    exit(system_not_supported).
    
generate_chat_php (Config, {win32, _}) ->
    generate_php_by_type(Config, chat, "chat_info.php");
generate_chat_php (Config, {unix, _}) ->
    generate_php_by_type(Config, chat, "chat_info.php");
generate_chat_php (_, _) ->
    exit(system_not_supported).
    
generate_assault_php (Config, {win32, _}) ->
    generate_php_by_type(Config, assault, "assault_info.php");
generate_assault_php (Config, {unix, _}) ->
    generate_php_by_type(Config, assault, "assault_info.php");
generate_assault_php (_, _) ->
    exit(system_not_supported).
    
generate_army_search_php (Config, {win32, _}) ->
    generate_php_by_type(Config, army_group_search, 
        "army_group_search_info.php");
generate_army_search_php (Config, {unix, _}) ->
    generate_php_by_type(Config, army_group_search, 
        "army_group_search_info.php");
generate_army_search_php (_, _) ->
    exit(system_not_supported).
    
generate_army_server_php (Config, {win32, _}) ->
    generate_php_by_type(Config, army_group, 
        "army_group_server_info.php");
generate_army_server_php (Config, {unix, _}) ->
    generate_php_by_type(Config, army_group, 
        "army_group_server_info.php");
generate_army_server_php (_, _) ->
    exit(system_not_supported).
    
generate_php_by_type (Config, Type, Filename) ->
    #{deploy_path := DeployPath, local_ip := LocalIP} = Config,
    {Path1, Path2} = lists:split(1, ?FN_SP(DeployPath)),
    ensure_dir(Path1, Path2),    
    {ok, Fd} = ?FOPEN(?FN_JN([DeployPath, Filename]), [write]),
    
    ?FWRITE(Fd, 
        "<?php\n"
        "header(\"Content-Type: text/html;charset=utf-8\");\n"
        "$data = array( "),

    lists:foreach(fun (R) ->
        #{name := N, server_num := SN, server_port := SP, 
            http_port := HP} = R,
            
        DCL = case maps:find(desc, R) of
            {ok, DC} -> binary_to_list(
                unicode:characters_to_binary(DC));
            _ -> N
        end,
        
        ?FWRITE(Fd, "\n\t"
            "array(\n\t\t"
            "'game_num' => " ++ ?I2L(SN) ++ ",\n\t\t"
            "'game_ip' => \"" ++ LocalIP ++ "\",\n\t\t"
            "'game_port' => " ++ SP ++ ",\n\t\t"
            "'http_port' => " ++ HP ++ ",\n\t\t"
            "'name' => urlencode(\"" ++ DCL ++ "\")\n\t"
            "),")
    end,
    find_server(Config, Type)),
    
    ?FWRITE(Fd, "\n);\n"
        "$json = json_encode($data);\n"
        "echo urldecode($json);\n", -1),
        
    ?FCLOSE(Fd).
    
stop_server (_Config, {win32, _}) ->
    ok;
stop_server (Config, {unix, _}) ->
    #{game_server := GameServerList} = Config,
    
    lists:foreach(fun (R) ->
        #{name := N, enable := E} = R,
        
        case E of
            true ->
                ?MSG("stop ~p ...~n", [N]),
                os:cmd("ps -ef | grep " ++ N ++ " | grep SCREEN"
                    "| cut -c 9-15 | xargs kill");
            _ ->
                ok
        end
    end,
    GameServerList);
stop_server (_, _) ->
    exit(system_not_supported).