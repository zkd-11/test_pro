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
    local remote=$(git config --get remote.origin.url)
    local remote_commit=$(git rev-parse origin/main)
    local local_commit=$(git rev-parse head)
    echo -e "$remote \n 远程仓库哈希$remote_commit \n 本地仓库哈希$local_commit \n"
    cd ..
    if [ "$remote_commit" == "$local_commit" ]; then
        styled_echo 34 "当前git历史已为最新，跳过拉取代码~"
        return 1 # 不需要更新
    else
        return 0 # 需要更新
    fi
}

# 更新流程
update_submodule() {
    local submodule_name=$1
    local add_changes=$2  # 第二个参数，决定是否添加更改，默认为 "false"
    local need_update_parent=1  # 假设默认不需要更新父模块

    # 检查子模块是否需要更新
    if submodule_needs_update "$submodule_name"; then
        echo "正在更新子模块 $submodule_name ..."
        git submodule update --remote --merge --recursive "$submodule_name"
        need_update_parent=0  # 需要更新父模块
    fi

    echo "进入子模块目录 $submodule_name ..."
    cd "$submodule_name"

    # 检查子模块是否有未提交的更改
    if git status --porcelain | grep -q '\S' && [ "$need_update_parent" -eq 1 ]; then
        echo "添加更改 ..."
        git add .

        echo "提交更改..."
        if ! git commit -m "更新子模块 $submodule_name"; then
            echo "提交失败，跳过推送"
            cd ..
            return 1
        fi

        echo "推送更改到远程仓库..."
        git push origin HEAD:main
        need_update_parent=0  # 需要更新父模块
    fi

    cd ..
    if [ "$need_update_parent" -eq 0 ]; then
        echo "更新父项目中的子模块引用哈希..."
        git add "$submodule_name"
        if ! git commit -m "chore(auto): 更新子模块 $submodule_name 引用"; then
            echo "提交失败，跳过推送"
            return 1
        fi
        git push
        echo -e "\033[1;32m更新完成!\033[0m"
    else
        styled_echo 32 "子模块 $submodule_name 并未存在需要提交的文件"
    fi
}


# 主函数
main() {
    check_git_repo
    # 仅引入一个子模块， 固定使用
    local submodule_name="readMe"
    local add_changes=${1:-"false"}  # 默认值为 "false" 更新子模块模式
    echo $add_changes

    check_submodule_exists "$submodule_name"
    update_submodule "$submodule_name" "$add_changes"
}

# 运行主函数
main "$@"