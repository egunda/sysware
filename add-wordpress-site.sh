clear
echo "----------------------------------------------"
echo "Script by vivek"
echo "This is to add a new website"
echo "----------------------------------------------"
echo "Please enter your website [without www] :"
read website
echo your website name is $website. Please press y to confirm or n to exit
read choice
case "$choice" in
    n)
    break
    ;;
    y)
      mkdir /var/www/`echo $website`
      echo "<VirtualHost *:80>" >> /etc/httpd/conf/httpd.conf
      echo "ServerName www.`echo $website`" >> /etc/httpd/conf/httpd.conf
      echo "ServerAlias `echo $website`" >> /etc/httpd/conf/httpd.conf
      echo "DocumentRoot /var/www/`echo $website`" >> /etc/httpd/conf/httpd.conf
      echo "</VirtualHost>" >> /etc/httpd/conf/httpd.conf
      service httpd restart
	  cd /var/www/`echo $website`
	  wget https://wordpress.org/latest.zip
	  unzip latest.zip
	  cd wordpress
	  mv * ../
	  cd ..
	  rm -rf wordpress
	  cd ..
	  chown apache: -R /var/www/`echo $website`
    ;;
    *)
    echo Please retry with valid option
    ;;
esac
echo "Task completed successfully"
