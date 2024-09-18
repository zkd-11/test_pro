#!/bin/bash

# 启用错误检查
set -e

styled_echo() {
    # $1
    # 黑色: 30
    # 红色: 31
    # 绿色: 32
    # 黄色: 33
    # 蓝色: 34
    # 品红色: 35
    # 青色: 36
    # 白色: 37
    local style=$1
    shift
    printf "\033[%sm%s\033[0m\n" "$style" "$*"
}

# 函数：检查是否在 git 仓库根目录
check_git_repo() {
    if [ ! -d ".git" ]; then
        echo "错误：请在 git 仓库根目录运行此脚本"
        exit 1
    fi
}

# 函数：检查子模块是否存在
check_submodule_exists() {
    if [ ! -d "$1" ]; then
        echo "错误：子模块 '$1' 不存在"
        exit 1
    fi
}

# 函数：检查子模块是否需要更新
submodule_needs_update() {
    cd "$1"
    git fetch
    local remote=$(git config --get remote.origin.url)
    local remote_commit=$(git rev-parse origin/main)
    local local_commit=$(git rev-parse head)
    echo -e "$remote \n 远程仓库哈希$remote_commit \n 本地仓库哈希$local_commit \n"
    cd ..
    if [ "$remote_commit" == "$local_commit" ]; then
        styled_echo 34 "当前git历史已为最新，跳过拉取代码~"
        return 1 # 不需要更新
    else
        styled_echo 34 "当前git历史落后远程仓库，更新中.."
        return 0 # 需要更新
    fi
}

# 更新流程
update_submodule() {
    local submodule_name=$1
    local add_changes=$2  # 第二个参数，决定是否添加更改，默认为 "false"
    local need_update_parent=1  # 默认不需要更新父模块
    local sub_commit_message=${3:-"更新子模块 $submodule_name"} # 子模块更新内容备注更新备注

    # 检查子模块是否需要更新
    if submodule_needs_update "$submodule_name"; then
        echo "正在更新子模块 $submodule_name ..."
        git submodule update --remote --merge --recursive "$submodule_name"
        need_update_parent=0  # 需要更新父模块
    fi

    echo "进入子模块目录 $submodule_name ..."
    cd "$submodule_name"

    # 检查子模块是否有未提交的更改
    if git status --porcelain | grep -q '\S' && [ $add_changes = true ]; then
    
        echo "添加更改 ..."
        git add .

        if ! git commit -m "$sub_commit_message"; then
            echo "提交失败，跳过推送"
            cd ..
            return 1
        fi

        echo "推送更改到远程仓库..."
        git push origin HEAD:main
        need_update_parent=0  # 需要更新父模块
    elif [ $add_changes = true ]; then
        styled_echo 32 "子模块 $submodule_name 并未存在需要提交的文件"
    fi

    if [ "$need_update_parent" -eq 0 ]; then
        cd ..
        echo "更新父项目中的子模块引用哈希..."
        git add "$submodule_name"
        if ! git commit -m "chore(auto): 更新子模块 $submodule_name 引用"; then
            echo "提交失败，跳过推送"
            return 1
        fi
        git push
        styled_echo 32 "更新完成!"
    else
        styled_echo 32 "子仓库与远程仓库数据已保持一致, 暂不需要更新!"
    fi
}


# 主函数
main() {
    check_git_repo
    local submodule_name="readMe" # 仅引入一个子模块， 固定使用
    local add_changes=${1:-"false"}  # 默认值为 "false" 更新子模块模式
    local sub_commit_message # 子模块更新内容备注更新备注

    if [ "$add_changes" = "true" ]; then
        # 清空屏幕
        clear
        # 获取用户输入的提交信息
        styled_echo 34 "请输入子模块更新的commmit提交信息(未输入时将使用默认文案)："
        read -r sub_commit_message
        styled_echo 33 "您输入的提交信息为: $sub_commit_message"
        styled_echo 33 "按任意键继续，或 Ctrl+C 退出。"
        read -r confirmation
    fi

    check_submodule_exists "$submodule_name"
    update_submodule "$submodule_name" "$add_changes" "$sub_commit_message"
}

# 运行主函数
main "$@"