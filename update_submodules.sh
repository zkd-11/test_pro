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

# 函数：从 package.json 读取子模块列表
read_submodules_from_json() {
    if [ ! -f "package.json" ]; then
        echo "错误：package.json 文件不存在"
        exit 1
    fi
    

    # submodules=$('readMe')
    # 使用 grep 和 sed 从 package.json 中提取子模块列表，忽略大小写
    submodules=$(grep -i '"submodules"' package.json | sed -E 's/.*"submodules": *(\[.*\]).*/\1/' | sed 's/[",]//g')
    echo $submodules 
    if [ -z "$submodules" ]; then
        echo "错误：在 package.json 中没有找到 submodules 数组或数组为空"
        exit 1
    fi
}

# 主要更新流程
update_submodule() {
    local submodule_name=readMe

    echo "正在更新子模块 $submodule_name ..."
    git submodule update --remote --merge --recursive

    echo "进入子模块目录 $submodule_name ..."
    cd "$submodule_name"

    echo "添加更改..."
    git add .

    echo "提交更改..."
    git commit -m "更新子模块 $submodule_name" || true

    echo "推送更改到远程仓库..."
    git push

    echo "返回父目录..."
    cd ..

    echo "更新父项目中的子模块引用..."
    git add "$submodule_name"
    git commit -m "更新子模块 $submodule_name 引用" || true
    git push
}

# 主函数
main() {
    check_git_repo
    read_submodules_from_json

    for submodule_name in $submodules; do
        check_submodule_exists "$submodule_name"
        update_submodule "$submodule_name"
    done

    echo "所有子模块更新完成！"
}

# 运行主函数
main