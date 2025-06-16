#!/bin/bash

sudo apt update -y
sudo apt install nginx -y
sudo rm -rf /usr/share/nginx/html/index.html 
cat <<EOF > /tmp/index.html
${index_html}
EOF
sudo mv /tmp/index.html /usr/share/nginx/html/index.html 

# Replace default nginx config with custom reverse proxy
cat <<EOF > /tmp/proxy.conf 
server {
    listen 80;
    listen [::]:80;
  
    server_name _;

    location /student {
        proxy_pass http://${app_alb_dns}:8080/student/;
    }
}
EOF
sudo mv /tmp/proxy.conf /etc/nginx/conf.d/proxy.conf
sudo unlink /etc/nginx/sites-enabled/default 
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
