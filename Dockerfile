FROM alpine:latest

RUN apk add --no-cache postgresql-client rclone tzdata curl busybox-suid

ENV TZ='America/Sao_Paulo'

WORKDIR /scripts

COPY pg_backup.sh .
COPY rclone.conf /root/.config/rclone/rclone.conf

RUN mkdir /pg_dumps

RUN chmod +x *.sh
RUN touch /var/log/pg_backup_error.log

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
