# #!/bin/sh

git pull origin master

echo 'TOTAL GENERATED'

config_file=blocked.json
static_adblock_file=static/adblock.txt
static_desktop_file=static/desktop.txt
static_tablet_file=static/tablet.txt
static_mobile_file=static/mobile.txt

output_file=generated/rules.txt
output_adblock=generated/adblock.txt
output_desktop_file=generated/desktop.txt
output_tablet_file=generated/tablet.txt
output_mobile_file=generated/mobile.txt
output_hosts_file=generated/hosts

join_arr() {
  local IFS="$1"; shift; echo "$*";
}

hide_image() {
  echo "$1##img" >> $output_file
  echo "$1##img" >> $output_adblock
}

hide_link() {
  echo "##a[href^='https://$1']" >> $output_file
  echo "##a[href^='https://www.$1']" >> $output_file
}

exclude_from_duckduckgo() {
  echo "duckduckgo.com##span:has-text(/$1/i):upward(article)" >> $output_file
}

exclude_from_yandex() {
  echo "yandex.ru##b:has-text(/$1/i):upward(.serp-item)" >> $output_file
  echo "yandex.ru##.serp-item:has-text(/$1/i)" >> $output_file
}

exclude_from_music() {
  echo "music.yandex.ru##.d-track:has-text(/$1/i)" >> $output_file
  echo "music.yandex.ru##.playlist:has-text(/$1/i)" >> $output_file
  echo "music.yandex.ru##.album:has-text(/$1/i)" >> $output_file
  echo "music.yandex.ru##.artist:has-text(/$1/i)" >> $output_file
}

exclude_from_youtube() {
  echo "youtube.com###channel-header-container:has-text(/$1/i):upward(body):remove()" >> $output_file # Channel page
  echo "youtube.com##.watch-active-metadata h1.title:has-text(/$1/i):upward(body):remove()" >> $output_file # Video page
  echo "youtube.com##.watch-active-metadata ytd-channel-name:has-text(/$1/i):upward(body):remove()" >> $output_file # Video page

  echo "youtube.com##ytd-grid-video-renderer:has-text(/$1/i)" >> $output_file # Subscription page item
  echo "youtube.com##ytd-rich-item-renderer:has-text(/$1/i)" >> $output_file # Subscription page item

  #Mobile
  echo "youtube.com##h1.c4-tabbed-header-title:has-text(/$1/i):upward(body)" >> $output_file # Channel page
  echo "youtube.com##ytm-slim-video-metadata-section-renderer:has-text(/$1/i):upward(body):remove()" >> $output_file # Video page

  echo "youtube.com##ytm-item-section-renderer:has-text(/$1/i)" >> $output_file # Subscription page item
  echo "youtube.com##ytm-rich-grid-renderer:has-text(/$1/i)" >> $output_file # Subscription page item
}

exclude_from_avito() {
  echo "avito.ru##div[data-marker='item']:has-text(/$1/i)" >> $output_file
  echo "avito.ru##div[data-marker='profile-item']:has-text(/$1/i)" >> $output_file
}

exclude_from_aliexpress() {
  echo "aliexpress.ru##div[class*="ProductSnippet__name"]:has-text(/$1/i):upward(div[class*="ProductSnippet__container"])" >> $output_file
}

exclude_from_yandex_market() {
  echo "market.yandex.ru##article:has-text(/$1/i)" >> $output_file
  echo "market.yandex.ru##div[data-zone-name="productCardTitle"]:has-text(/$1/i):upward(div[data-zone-name="product-page"])" >> $output_file
}

exclude_from_ozon() {
  echo "ozon.ru##div[data-widget="fulltextResultsHeader"]:has-text(/$1/i):upward(body)" >> $output_file
}

domains=()
keywords=()
music=()
youtube=()

> $output_file
> $output_adblock
> $output_desktop_file
> $output_mobile_file
> $output_tablet_file
> $output_hosts_file

jq -r '.domains[]' $config_file | {
  while read -r domain; do
    echo "0.0.0.0         ${domain} www.${domain}" >> $output_hosts_file
    domains+=($domain)
  done

  squashed=$(join_arr "|" "${domains[@]}")
  squashed_with_comma=$(join_arr , "${domains[@]}")

  exclude_from_duckduckgo "${squashed}"
  exclude_from_yandex "${squashed}"
  echo "${squashed_with_comma}##*" >> $output_file

  echo "Domains: ${#domains[@]}"
}

jq -r '.only_hosts[]' $config_file | {
  while read -r domain; do
    echo "0.0.0.0         ${domain} www.${domain}" >> $output_hosts_file
    domains+=($domain)
  done

  echo "Only hosts: ${#domains[@]}"
}

jq -r '.domains_only_desktop[]' $config_file | {
  while read -r domain; do
    echo "0.0.0.0         ${domain} www.${domain}" >> $output_hosts_file
    domains+=($domain)
  done

  squashed_with_comma=$(join_arr , "${domains[@]}")
  echo "${squashed_with_comma}##*" >> $output_desktop_file
  
  cat $static_desktop_file >> $output_desktop_file
  cat $static_adblock_file >> $output_adblock_file
}

jq -r '.domains_only_mobile[]' $config_file | {
  while read -r domain; do
    domains+=($domain)
  done

  squashed_with_comma=$(join_arr , "${domains[@]}")

  echo "${squashed_with_comma}##*" >> $output_mobile_file

  cat $static_mobile_file >> $output_mobile_file
}

jq -r '.domains_only_tablet[]' $config_file | {
  while read -r domain; do
    domains+=($domain)
  done

  squashed_with_comma=$(join_arr , "${domains[@]}")

  echo "${squashed_with_comma}##*" >> $output_tablet_file

  cat $static_tablet_file >> $output_tablet_file
}

jq -r '.keywords[]' $config_file | {
  while IFS= read -r keyword; do
    keywords+=("$keyword")
  done

  squashed=$(join_arr "|" "${keywords[@]}")

  exclude_from_duckduckgo "${squashed}"
  exclude_from_yandex "${squashed}"
  exclude_from_youtube "${squashed}"
  exclude_from_avito "${squashed}"
  exclude_from_yandex_market "${squashed}"
  exclude_from_ozon "${squashed}"
  exclude_from_aliexpress "${squashed}"

  echo "Keywords: ${#keywords[@]}"
}

jq -r '.music[]' $config_file | {
  while IFS= read -r keyword; do
    keywords+=("$keyword")
  done

  squashed=$(join_arr "|" "${keywords[@]}")

  exclude_from_music "${squashed}"

  echo "Music: ${#keywords[@]}"
}

jq -r '.market[]' $config_file | {
  while IFS= read -r keyword; do
    keywords+=("$keyword")
  done

  squashed=$(join_arr "|" "${keywords[@]}")

  exclude_from_avito "${squashed}"
  exclude_from_yandex_market "${squashed}"

  echo "Market: ${#keywords[@]}"
}

jq -r '.hide_links[]' $config_file | {
  while read -r domain; do
    hide_link $domain
    domains+=($domain)
  done

  echo "Links: ${#domains[@]}"
}

jq -r '.hide_images[]' $config_file | {
  while read -r domain; do
    hide_image $domain
    domains+=($domain)
  done

  echo "Images: ${#domains[@]}"
}

echo "\n"

git add .
git commit -m 'Update filters'
git push
