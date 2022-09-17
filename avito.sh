if grep -q "avito.ru www.avito.ru" /etc/hosts; then
  echo "Exists"
else
  echo "0.0.0.0 avito.ru www.avito.ru" >> /etc/hosts;
fi
