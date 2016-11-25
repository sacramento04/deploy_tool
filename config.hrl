%% -*- coding: utf-8 -*-
#{
project_path => "/opt/game/trunk",      %% 项目路径
public_db_ip => "192.168.1.73",         %% 内网数据库ip
public_db_port => "3306",               %% 内网数据库端口
public_db_name => "gamedb",             %% 内网数据库名
public_db_user => "root",               %% 内网数据库用户
public_db_password => "ybybyb",         %% 内网数据库密码
local_ip => "192.168.1.73",             %% 本地ip
local_db_port => "3306",                %% 本地数据库端口
local_db_user => "root",                %% 本地数据库用户
local_db_password => "ybybyb",          %% 本地数据库密码
build_code_db => false,                 %% 生成模板
deploy_path => "/opt/game/group",       %% 部署路径
source_code => false,                   %% 复制源码

game_server => [                        %% 服务器列表
    #{
        type => game,                   %% 游戏服1
        name => "mobile_s1",            %% 服务器名
        db_name => "mobile_s1",         %% [数据库名]
        server_num => 1,                %% 服务器id
        server_port => "9527",          %% 游戏端口
        http_port => "9528",            %% http端口
        desc => "游戏服1",              %% [描述]
        enable => true                  %% 是否启动
    },
    
    #{
        type => game,
        name => "mobile_s2",
        db_name => "mobile_s2",
        server_num => 2,
        server_port => "9529",
        http_port => "9530",
        desc => "游戏服2",
        enable => true
    },
    
    #{
        type => assault,
        name => "assault",
        db_name => "assault",
        server_num => 1001,
        server_port => "9600",
        http_port => "9601",
        desc => "南华殿1",
        enable => true
    },
    
    #{
        type => vip,
        name => "vip",
        db_name => "gamedb_vip",
        server_num => 2001,
        server_port => "9538",
        http_port => "9531",
        desc => "vip服",
        enable => true
    },
    
    #{
        type => comment,
        name => "hero_comments",
        db_name => "hero_comments",
        server_num => 3001,
        server_port => "10255",
        http_port => "9540",
        desc => "评论服",
        enable => true
    },
    
    #{
        type => chat,
        name => "chat_1",               
        server_num => 4001,
        server_port => "20001",
        http_port => "20002",
        desc => "聊天服1",
        enable => true
    },
    
    #{
        type => chat,
        name => "chat_2",               
        server_num => 4002,
        server_port => "20003",
        http_port => "20004",
        desc => "聊天服2",
        enable => true
    }
]
}.