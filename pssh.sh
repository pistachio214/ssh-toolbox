#!/bin/bash

# 服务器列表文件
BASE_PATH=$(
    cd "$(dirname "$0")"
    pwd
)

echo "$BASE_PATH"
FILE_SERVER_LIST=$BASE_PATH"/config.ini"
echo "$FILE_SERVER_LIST"

# 暂存服务器列表，用于登录操作
CONFIG_ARR=()

# 记录默认分隔符，用于修改后的还原
IFS_OLD=$IFS

# 输出table的row
function print_table_row() {
    id="$1"
    host="$2"
    port="$3"
    username="$4"
    title="$5"

    printf "| %-10s | %-17s | %-10s | %-20s | %-35s \n" "$id" "$host" "$port" "$username" "$title"
    printf "+------------+-------------------+------------+----------------------+-----------------------------------------------|\n"
}

# 初始化
function initialize() {
    # 检查配置文件
    if [ ! -f $FILE_SERVER_LIST ]; then
        echo "Config file not found."
        exit 1
    fi

    # 读取配置文件，显示待操作服务器列表
    clear

    local serverNum=1 # 服务器列表索引
    local config=()

    print_table_header

    while read line || [ -n "$line" ]; do
        if [[ ${line} != \#* && "$line" != "" ]]; then
            IFS=, # 定义读取配置文件时的分隔符
            config=($line)
            CONFIG_ARR[$serverNum]=$line

            # 输出一行服务器信息
            print_table_row "$serverNum" "${config[2]}" "${config[3]}"  "${config[1]}" "${config[0]}"

            # 累加服务器索引，直到配置文件读取完毕
            serverNum=$(($serverNum + 1))
        fi
    done <$FILE_SERVER_LIST

    IFS=$IFS_OLD # 还原分隔符

    echo -en "请输入 \033[32m序号\033[0m 选择要登录的服务器: "
    handleChoice
}

# 过滤掉注释后的配置
is_comment() {
    [[ $1 =~ ^[[:space:]]*# ]]
}

# 输出列表的header
print_table_header() {
    printf "+------------+-------------------+------------+----------------------+-----------------------------------------------+\n"
    printf "| %-10s | %-17s | %-10s | %-20s | %-45s |\n" "ID" "Host" "Port" "Username" "Title"
    printf "+------------+-------------------+------------+----------------------+-----------------------------------------------|\n"
}

# 生成最后的长度
genereatr_header_right() {
    number="$1"

    # 使用循环生成对应数量的连字符
    result=""
    for ((i = 0; i < number; i++)); do
        result="${result}-"
    done

    echo $result
}

# 处理用户输入
function handleChoice {
    read -n 2 choice
    local serverListLength=${#CONFIG_ARR[@]}
    if [[ "$choice" -lt 1 || "$choice" -gt serverListLength ]]; then
        echo -en "\n\033[31m无效的序号[ $choice ], 是否重新输入( y 是 | n 否 ):\033[0m"
        read -n 1 retry
        if [[ -n "$retry" && "$retry" = "y" ]]; then
            clear
            initialize
        else
            echo ""
            exit 1
        fi
    else
        sshLogin $choice
    fi
}

# 执行 ssh 登录
function sshLogin {

    IFS=, # 定义读取分隔符
    local config=(${CONFIG_ARR[$1]})

    # 默认用户 root
    local user=${config[1]}
    if [[ $user == "" ]]; then
        user="root"
    fi

    # 默认端口号 22
    local port=${config[3]}
    if [[ $port == "" ]]; then
        port="22"
    fi

    # 开始登录
    echo -e "\n\n\033[32m==>\033[0m 正在登录【\033[32m${config[0]}\033[0m】，请稍等...\n"
    sleep 1
    $(which expect) $BASE_PATH/go_ssh.ex ${config[0]} ${config[2]} $port $user ${config[4]}
    echo -e "\n\033[32m==>\033[0m 您已退出【\033[32m${config[0]}\033[0m】\n"
}

# 执行初始化
initialize
