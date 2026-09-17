#!/usr/bin/env bash
# Выложить APK из CI на прод — чтобы механик скачал его с сайта.
#
# Запускается с ноутбука, не на сервере: у сервера нет ни `gh`, ни доступа к
# артефактам Actions, а у ноутбука есть и то и другое плюс ssh-алиас `els`.
#
#     scripts/publish-apk.sh                       # последний зелёный frontend на main
#     scripts/publish-apk.sh --run 35249858830     # конкретный прогон (в том числе откат)
#     scripts/publish-apk.sh --notes "Что нового"  # текст на странице скачивания
#
# Что происходит:
#   1. скачивается артефакт `els-apk` прогона `frontend`;
#   2. версия берётся из pubspec.yaml того же коммита — с тем же awk, что в CI,
#      иначе на сайте и внутри APK окажутся разные номера;
#   3. sha256 файла сверяется с тем, что напечатал CI: GitHub отдаёт артефакт
#      zip-ом, и это единственная проверка, что по дороге ничего не пережалось;
#   4. файл и `release.json` копируются в том `static_data` контейнера backend —
#      сначала APK, потом манифест: бэкенд считает «манифест есть, файла нет»
#      за «раздавать нечего», и такой порядок не оставляет окна с 404.
#
# Формат манифеста и путь `static/app/` — backend/src/core/app_release.py.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SSH_HOST=els
REMOTE_REPO=/var/www/els
COMPOSE_PROD="docker compose --project-directory $REMOTE_REPO -f $REMOTE_REPO/infra/docker-compose.prod.yml"

run_id=""
notes=""
while [ $# -gt 0 ]; do
    case "$1" in
        --run) run_id=$2; shift 2 ;;
        --notes) notes=$2; shift 2 ;;
        -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

for tool in gh git ssh scp shasum; do
    command -v "$tool" >/dev/null || { echo "нужен $tool" >&2; exit 1; }
done

# --- 1. прогон ---------------------------------------------------------------
if [ -z "$run_id" ]; then
    run_id=$(gh run list -w frontend -b main -s success -L 1 --json databaseId \
        --jq '.[0].databaseId')
    [ -n "$run_id" ] || { echo "зелёных прогонов frontend на main нет" >&2; exit 1; }
fi
head_sha=$(gh run view "$run_id" --json headSha,conclusion,headBranch \
    --jq 'if .conclusion == "success" then .headSha else error("прогон \(.headBranch) не зелёный: \(.conclusion)") end')
echo "==> прогон $run_id, коммит ${head_sha:0:7}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

gh run download "$run_id" -n els-apk -D "$work"
apk_src="$work/app-release.apk"
[ -f "$apk_src" ] || { echo "в артефакте нет app-release.apk" >&2; exit 1; }

# --- 2. версия из pubspec того же коммита -----------------------------------
git -C "$REPO_ROOT" cat-file -e "$head_sha" 2>/dev/null \
    || git -C "$REPO_ROOT" fetch -q origin "$head_sha" \
    || { echo "коммита $head_sha нет локально — сделайте git fetch" >&2; exit 1; }
version=$(git -C "$REPO_ROOT" show "$head_sha:frontend/pubspec.yaml" | awk '/^version:/{print $2}')
version_name=${version%%+*}
version_code=${version##*+}
[ -n "$version_name" ] && [ "$version_code" -gt 0 ] 2>/dev/null \
    || { echo "не разобрал версию «$version» из pubspec.yaml" >&2; exit 1; }
file_name="els-$version_name.apk"

# --- 3. sha256 против лога CI -------------------------------------------------
sha=$(shasum -a 256 "$apk_src" | awk '{print $1}')
ci_log=$(gh run view "$run_id" --log 2>/dev/null || true)
# Ищем вывод шага, а не его текст: gh печатает в лог и сам скрипт шага, где
# слово «debug-ключом» есть всегда. Вывод идёт сразу после метки времени.
if ! grep -qE '^[^\t]*\t[^\t]*\t[0-9TZ:.-]+ подписан ключом релиза$' <<<"$ci_log"; then
    echo "!!! CI не подтвердил подпись ключом релиза — APK debug, механикам не раздавать" >&2
    exit 1
fi
ci_sha=$(grep -o '[0-9a-f]\{64\}  *[^ ]*app-release\.apk' <<<"$ci_log" | tail -1 | awk '{print $1}')
if [ -z "$ci_sha" ]; then
    echo "!!! в логе прогона нет sha256 — лог уже стёрт? Сверить не с чем" >&2
    exit 1
elif [ "$ci_sha" != "$sha" ]; then
    echo "!!! sha256 не совпал: CI $ci_sha, скачано $sha" >&2
    exit 1
fi
size=$(stat -f %z "$apk_src" 2>/dev/null || stat -c %s "$apk_src")
echo "==> $file_name (код $version_code), $((size / 1024 / 1024)) МБ, sha256 $sha"

# --- 4. манифест ---------------------------------------------------------------
python3 - "$work/release.json" "$version_name" "$version_code" "$file_name" "$sha" "$notes" <<'PY'
import datetime, json, sys
out, name, code, file, sha, notes = sys.argv[1:]
manifest = {
    "versionName": name,
    "versionCode": int(code),
    "file": file,
    "sha256": sha,
    "publishedAt": datetime.date.today().isoformat(),
}
if notes:
    manifest["notes"] = notes
with open(out, "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
cat "$work/release.json"

# --- 5. на сервер ------------------------------------------------------------
remote_tmp="/tmp/els-release"
echo "==> копируем на $SSH_HOST"
ssh "$SSH_HOST" "mkdir -p $remote_tmp"
scp -q "$apk_src" "$SSH_HOST:$remote_tmp/$file_name"
scp -q "$work/release.json" "$SSH_HOST:$remote_tmp/release.json"

ssh "$SSH_HOST" bash -s -- "$remote_tmp" "$file_name" "$sha" <<EOF
set -euo pipefail
tmp=\$1; file=\$2; sha=\$3
cid=\$($COMPOSE_PROD ps -q backend)
[ -n "\$cid" ] || { echo "контейнер backend не запущен" >&2; exit 1; }
docker exec "\$cid" mkdir -p /app/static/app
docker cp "\$tmp/\$file" "\$cid:/app/static/app/\$file"
got=\$(docker exec "\$cid" sha256sum "/app/static/app/\$file" | awk '{print \$1}')
[ "\$got" = "\$sha" ] || { echo "sha256 в контейнере не совпал: \$got" >&2; exit 1; }
docker cp "\$tmp/release.json" "\$cid:/app/static/app/release.json"
rm -rf "\$tmp"
echo "в контейнере:"
docker exec "\$cid" ls -l /app/static/app
EOF

echo
echo "Готово: $version_name ($file_name) раздаётся с сайта — https://els23.ru/app"
