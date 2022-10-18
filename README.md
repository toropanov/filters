function filters() {
  cd ~/Projects/filters/
  sudo sh generate.sh
  echo "Wait for update 15 seconds"
  sleep 15
  vpn
  hosts
  cd ~/Projects
}

<!-- ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs iCloud -->
