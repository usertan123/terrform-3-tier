#!/bin/bash

# Create SSH key file
cat <<EOF > /home/ubuntu/appserver.pem
${private_key_pem}
EOF

chmod 400 /home/ubuntu/appserver.pem
chown ubuntu:ubuntu /home/ubuntu/appserver.pem
