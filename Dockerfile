FROM alpine:latest
RUN apk add --no-cache git zip
WORKDIR /app
COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# 设置环境变量（可选，默认值可在运行时覆盖）
ENV GITHUB_USER="" 
ENV GITHUB_TOKEN="" 
ENV GIT_REMOTE_URL="" 
ENV GIT_EMAIL="github-actions[bot]@users.noreply.github.com"
ENV GIT_NAME="AutoBackup"
ENV CRON_SCHEDULE="0 * * * *"

CMD ["/bin/sh", "-c", "/usr/local/bin/backup.sh && echo \"$CRON_SCHEDULE /bin/sh /usr/local/bin/backup.sh\" | crontab - && crond -f"]
