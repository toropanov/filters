# #!/bin/sh

git pull origin master

echo 'TOTAL GENERATED'

config_file=blocked.json
output_file=generated/rules.txt
output_desktop_file=generated/desktop.txt
output_mobile_file=generated/mobile.txt
output_hosts_file=generated/hosts
output_duck_file=generated/duck.txt
vpn_conf_file=generated/ovpn.conf

join_arr() {
  local IFS="$1"; shift; echo "$*";
}

exclude_from_duckduckgo() {
  local domains=("$@")
  local squashed_domains=$(join_arr "|" "${domains[@]}")
  echo "duckduckgo.com##span:has-text(/${squashed_domains}/ig):upward(article)" >> $output_duck_file
}

exclude_from_yandex() {
  local domains=("$@")
  local squashed_domains=$(join_arr "|" "${domains[@]}")
  echo "yandex.ru##b:has-text(/${squashed_domains}/ig):upward(.serp-item)" >> $output_file
  echo "yandex.ru##.serp-item:has-text(/${squashed_domains}/ig)" >> $output_file
}

exclude_from_music() {
  local keywords=("$@")
  local squashed_keywords=$(join_arr "|" "${keywords[@]}")
  
  echo "music.yandex.ru##.d-track:has-text(/${squashed_keywords}/i)" >> $output_file
  echo "music.yandex.ru##.playlist:has-text(/${squashed_keywords}/i)" >> $output_file
  echo "music.yandex.ru##.album:has-text(/${squashed_keywords}/i)" >> $output_file
  echo "music.yandex.ru##.artist:has-text(/${squashed_keywords}/i)" >> $output_file
}

exclude_from_youtube() {
  local keywords=("$@")
  local squashed_keywords=$(join_arr "|" "${keywords[@]}")
  echo "youtube.com##ytd-channel-name:has-text(/${squashed_keywords}/i):upward(12)" >> $output_file
  echo "youtube.com##h1:has-text(/${squashed_keywords}/i):upward(4)" >> $output_file
  echo "youtube.com##h3:has-text(/${squashed_keywords}/i):upward(10)" >> $output_file
}

exclude_from_vk() {
  local keywords=("$@")
  local squashed_keywords=$(join_arr "|" "${keywords[@]}")
  
  echo "vk.com##body:has-text(/${squashed_keywords}/i)" >> $output_file
}

domains=()
keywords=()
music=()
youtube=()

> $output_file
> $output_desktop_file
> $output_mobile_file
> $output_hosts_file
> $vpn_conf_file

jq -r '.domains[]' $config_file | {
  while read -r domain; do
    echo "0.0.0.0 ${domain} www.${domain}" >> $output_hosts_file
    domains+=($domain)
  done

  squashed_domains=$(join_arr , "${domains[@]}")

  exclude_from_duckduckgo "${domains[@]}"
  exclude_from_yandex "${domains[@]}"
  echo "${squashed_domains}##*" >> $output_file

  echo "Domains: ${#domains[@]}"
}

jq -r '.domains_only_desktop[]' $config_file | {
  while read -r domain; do
    domains+=($domain)
  done

  squashed_domains=$(join_arr , "${domains[@]}")
  echo "${squashed_domains}##*" >> $output_desktop_file
}

jq -r '.domains_only_mobile[]' $config_file | {
  while read -r domain; do
    domains+=($domain)
  done

  squashed_domains=$(join_arr , "${domains[@]}")
  echo "${squashed_domains}##*" >> $output_mobile_file
}

jq -r '.keywords[]' $config_file | {
  while read -r keyword; do
    keywords+=("$keyword")
  done

  exclude_from_duckduckgo "${keywords[@]}"
  exclude_from_yandex "${keywords[@]}"
  exclude_from_vk "${keywords[@]}"
  exclude_from_youtube "${keywords[@]}"
  exclude_from_music "${keywords[@]}"

  echo "Keywords: ${#keywords[@]}"
}

jq -r '.vk[]' $config_file | {
  while read -r keyword; do
    keywords+=($keyword)
  done

  exclude_from_vk "${keywords[@]}"

  echo "VK: ${#keywords[@]}"
}

jq -r '.music[]' $config_file | {
  while read -r keyword; do
    keywords+=($keyword)
  done

  exclude_from_music "${keywords[@]}"

  echo "Music: ${#keywords[@]}"
}

jq -r '.youtube[]' $config_file | {
  while read -r keyword; do
    keywords+=($keyword)
  done

  exclude_from_youtube "${keywords[@]}"

  echo "YouTube: ${#keywords[@]}"
}

jq -r '.unlocked_domains[]' $config_file | {
  while read -r domain; do
    route_domains+=($domain)
    echo "route ${domain}" >> $vpn_conf_file
    echo "route www.${domain}" >> $vpn_conf_file
  done

  echo "Unlocked domains: ${#route_domains[@]}"
}

echo "\n"

git add .
git commit -m 'Update filters'
git push
