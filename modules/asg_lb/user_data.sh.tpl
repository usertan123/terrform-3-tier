#!/bin/bash
# Basic setup
sudo apt update -y
sudo apt install openjdk-11-jre-headless git maven -y

# Download and install latest Tomcat 9
export latest_version=$(curl -s https://dlcdn.apache.org/tomcat/tomcat-9/ | grep -oE 'v9\.0\.[0-9]+' | sort -V | tail -1 | cut -d'v' -f2)
wget https://dlcdn.apache.org/tomcat/tomcat-9/v$latest_version/bin/apache-tomcat-$latest_version.tar.gz

# Set up Tomcat daemon
sudo bash -c 'cat <<EOF > /tmp/tomcat-daemon.service
[Unit]
Description=tomcat daemon
After=network.target

[Service]
Type=forking
User=root
Group=root
RuntimeDirectory=tomcat
WorkingDirectory=/opt/tomcat
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
KillMode=none

[Install]
WantedBy=multi-user.target
EOF'

sudo mv /tmp/tomcat-daemon.service /etc/systemd/system/tomcat-daemon.service
sudo tar -xvzf apache-tomcat-*.tar.gz
sudo rm -rf apache-tomcat-*.tar.gz
sudo mv apache-tomcat-* /opt/tomcat

# Build WAR file from GitHub repo using Maven
sudo git clone https://github.com/usertan123/student-ui.git /opt/student-app
cd /opt/student-app
sudo mvn clean package

# Move the WAR file to Tomcat
sudo mv target/*.war /opt/tomcat/webapps/student.war
sudo systemctl daemon-reload
sudo systemctl start tomcat-daemon
sudo systemctl enable tomcat-daemon

# Install MySQL connector
#sudo curl -O https://itachi-3-tier.s3.amazonaws.com/mysql-connector.jar
sudo curl -O https://seamless-3tier-jar.s3.ap-south-1.amazonaws.com/mariadb-java-client-3.5.0.jar
sudo mv mariadb-java-client-3.5.0.jar /opt/tomcat/lib

# sudo mv /tmp/mysql-connector.jar /opt/tomcat/lib

# Create /tmp/data.txt with DB configuration
cat <<EOF > /tmp/data.txt
<Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource"
            maxTotal="100" maxIdle="30" maxWaitMillis="10000"
            username="${db_user}" password="${db_pass}"
            driverClassName="org.mariadb.jdbc.Driver"
            url="jdbc:mariadb://${db_endpoint}:3306/studentapp"/>

EOF


# Inject DB config into Tomcat context.xml

sudo sed -i 20r/tmp/data.txt /opt/tomcat/conf/context.xml

# Start Tomcat service
# sudo systemctl daemon-reload
# sudo systemctl start tomcat-daemon
# sudo systemctl enable tomcat-daemon
sudo systemctl restart tomcat-daemon
