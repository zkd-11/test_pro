#!/bin/bash

# 启用错误检查
set -e

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
    local local_commit=$(git rev-parse HEAD)
    echo -e "$remote \n 远程$remote_commit \n 本地$local_commit \n"
    cd ..
    if [ "$remote_commit" == "$local_commit" ]; then
        return 1 # 不需要更新
    else
        return 0 # 需要更新
    fi
}

# 更新流程
update_submodule() {
    local submodule_name=$1

    if ! submodule_needs_update "$submodule_name"; then
        echo "子模块 '$submodule_name'不需要更新"
        return
    fi

    echo "正在更新子模块 $submodule_name ..."
    git submodule update --remote --merge --recursive "$submodule_name"

    echo "进入子模块目录 $submodule_name ..."
    cd "$submodule_name"

    echo "添加更改..."
    git add .

    echo "提交更改..."
    git commit -m "更新子模块 $submodule_name" || true

    echo "推送更改到远程仓库..."
    git push origin HEAD:main

    echo "返回父目录..."
    cd ..

    echo "更新父项目中的子模块引用..."
    git add "$submodule_name"
    git commit -m "chore(auto): 更新子模块 $submodule_name 引用" || true
    git push
}

# 主函数
main() {
    check_git_repo
    check_submodule_exists "readMe"
    update_submodule "readMe"
}

# 运行主函数
main