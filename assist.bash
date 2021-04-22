#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

# shellcheck source=/dev/null
source "story-mapper/.env"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/src/load.bash"

COMPOSE_FILE="story-mapper/docker-compose.yml"

opt="$1"
ts="latest" #"$(date +%Y-%m-%d_%H_%M_%S)"
action=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
check_preconditions

case $action in
    build)
      time DOCKER_BUILDKIT=1 docker-compose -f $COMPOSE_FILE build
      ;;
    up)
      docker-compose -f $COMPOSE_FILE up -d
      ;;
    status)
      display_url_status "http://localhost:8080"
      docker-compose -f $COMPOSE_FILE ps
      ;;
    down)
      docker-compose -f $COMPOSE_FILE down
      ;;
    backup)
      [ -e file ] && rm -f backup/dump_"${ts}"
      docker exec -t "${DB_CONTAINER_NAME}" \
          pg_dumpall -c -U "${FEATMAP_DB_USER}"  \
          | gzip >  backup/dump_"${ts}".gz || echo "Backup ❌ "

      echo "Backup for ${DB_CONTAINER_NAME} DONE ✅"
      ;;
    restore)
        gunzip < backup/dump_"${ts}".gz | docker exec -i "${DB_CONTAINER_NAME}" \
          psql -U "${FEATMAP_DB_USER}" -d "${FEATMAP_DB}" || echo "Restore ❌ "
      echo "Backup for ${DB_CONTAINER_NAME} DONE ✅"
      ;;
    *)
      echo "${RED}Usage: ./assist <command>${NC}"
cat <<-EOF
Commands:
---------
  build                -> Build the Container
  up                   -> Brings up application and services
  status               -> Status of the application and services
  down                 -> Brings down application and services
  backup               -> Backupup DB
  restore              -> Restores DB
EOF
    ;;
esac
