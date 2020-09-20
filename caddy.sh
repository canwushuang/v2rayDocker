#!/bin/bash
# FILE="/etc/Caddy"
domain="$1"
psname="$2"
uuid="51be9a06-299f-43b9-b713-1ec5eb76e3d7"
if  [ ! "$3" ] ;then
    uuid=$(uuidgen)
    echo "uuid 将会系统随机生成"
else
    uuid="$3"
fi
cat > /etc/Caddyfile <<'EOF'
localhost:18443 {
        basicauth / admin admin
        webdav / {
            scope /media/gdrive
            allow_r regex
            modify false
        }
}
domain:8080 {
        gzip
        proxy / 127.0.0.1:18080 {
          websocket
          transparent
        }
}

domain {
        log ./caddy.log
        proxy /one :2333 {
          websocket
          header_upstream -Origin
  }
}

domain:18081 {
        proxy / https://ttt.us-south.cf.appws.swins.top.cloud {
          websocket
          header_upstream -Origin
        }
}

EOF
sed -i "s/domain/${domain}/" /etc/Caddyfile

# v2ray
cat > /etc/v2y/config.json <<'EOF'
{
  "reverse": {
      "bridge":[
        {
          "tag":"bridge",
          "domain":"tx.localhost"
        }
      ]
  },
  "inbounds": [
    {
      "tag":"tunnel",
      "port": 2333,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "uuid",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/one"
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag":"out",
      "protocol": "freedom",
      "settings": {}
    }
  ],
  "routing": {
      "rules": [
        {
          "type": "field",
          "inboundTag": [
            "tunnel"
          ],
          "domain": [
            "full:tx.localhost"
          ],
          "outboundTag": "out"
        }
      ]
    }
}

EOF

sed -i "s/uuid/${uuid}/" /etc/v2y/config.json

cat > /srv/sebs.js <<'EOF'
 {
    "add":"domain",
    "aid":"0",
    "host":"",
    "id":"uuid",
    "net":"ws",
    "path":"/one",
    "port":"443",
    "ps":"sebsclub",
    "tls":"tls",
    "type":"none",
    "v":"2"
  }
EOF

if [ "$psname" != "" ] && [ "$psname" != "-c" ]; then
  sed -i "s/sebsclub/${psname}/" /srv/sebs.js
  sed -i "s/domain/${domain}/" /srv/sebs.js
  sed -i "s/uuid/${uuid}/" /srv/sebs.js
else
  $*
fi
pwd
cp /etc/Caddyfile .
nohup /bin/parent caddy  --log stdout --agree=false &
echo "配置 JSON 详情"
echo " "
cat /etc/v2y/config.json
echo " "
node v2ray.js
/usr/bin/v2y -config /etc/v2y/config.json
