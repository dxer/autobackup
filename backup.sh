#!/bin/sh

log() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$current_time:$*"
}

# 设置 Git 用户信息
GIT_EMAIL="${GIT_EMAIL:-github-actions[bot]@users.noreply.github.com}"
GIT_NAME="${GIT_NAME:-AutoBackup}"

# 检查/root/.gitconfig是否存在
if [ ! -f "/root/.gitconfig" ]; then
    cat > /root/.gitconfig << EOF
[user]
    email = $GIT_EMAIL
    name = $GIT_NAME
[credential]
    helper = store
[safe]
    directory = /app
EOF
    log "文件 /root/.gitconfig 已创建并写入配置。"
fi

# 检查环境变量 GITHUB_USER、GITHUB_TOKEN 和 GIT_REMOTE_URL 是否已设置
if [[ -n "$GITHUB_USER" ]] && [[ -n "$GITHUB_TOKEN" ]] && [[ -n "$GIT_REMOTE_URL" ]]; then
    # 验证 GIT_REMOTE_URL 格式
    if [[ ! "$GIT_REMOTE_URL" =~ ^https:\/\/.*\.git$ ]]; then
        log "GIT_REMOTE_URL 格式不正确，需以 https:// 开头并以 .git 结尾。"
        exit 1
    fi
    credentials="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com"
    if [[ -f /root/.git-credentials ]]; then
        existing_credentials=$(cat /root/.git-credentials)
        if [[ $existing_credentials != $credentials ]]; then
            echo "$credentials" > /root/.git-credentials
            log "凭据已更新到 /root/.git-credentials"
        fi
    else
        echo "$credentials" > /root/.git-credentials
        log "凭据已写入到 /root/.git-credentials"
    fi
else
    log "环境变量 GITHUB_USER、GITHUB_TOKEN 或 GIT_REMOTE_URL 未设置。"
    exit 1
fi

# 切换到 /app 目录
cd /app

# 检查是否是 Git 仓库
if [ ! -d ".git" ]; then
    git init
    git branch -M main
    git remote add origin "$GIT_REMOTE_URL"
    log "初始化 Git 仓库并设置远程地址为 $GIT_REMOTE_URL"
else
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [[ "$remote_url" != "$GIT_REMOTE_URL" ]]; then
        git remote set-url origin "$GIT_REMOTE_URL"
        log "更新远程地址为 $GIT_REMOTE_URL"
    fi
fi

# 执行自定义的脚本
if [ -f "/app/pre_script.sh" ];then
  sh /app/pre_script.sh
fi

# 执行 Git 提交和推送
git add -A
if git diff --cached --quiet; then
    log "没有需要提交的更改。"
else
    git commit -m "AutoBackup: $(date '+%Y-%m-%d %H:%M:%S')"
    if git push origin main; then
        log "备份成功"
    else
        log "推送失败，请检查网络连接或权限。"
    fi
fi
