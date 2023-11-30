#!/bin/bash

app_name="dashboard.py"
app_official_name="WGDashboard"

dashes='------------------------------------------------------------'
equals='============================================================'



start_wgd () {
    #create_wiresentinel_user &&
    uwsgi --ini wg-uwsgi.ini
    #uwsgi --uid wiresentinel --ini wg-uwsgi.ini
    #su - wiresentinel -c "uwsgi --ini ./wg-uwsgi.ini"
}






newconf_wgd () {
  newconf_wgd0
  newconf_wgd1
  newconf_wgd2
}



newconf_wgd0() {
  local num_configs=$CONFIG_
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

  

    cat <<EOF >"/etc/wireguard/wg0.conf"
[Interface]
PrivateKey = $private_key
Address = 10.0.0.1/24
ListenPort = 770
SaveConfig = true
PostUp =  /home/app/Admins/wg0-nat.sh
PreDown = /home/app/Admins/wg0-dwn.sh

EOF

   

  if [ ! -f "/master-key/master.conf" ]; then
    make_master_config  # Only call make_master_config if master.conf doesn't exist
  fi 
}


newconf_wgd1() {
  local num_configs=$CONFIG_
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

    cat <<EOF >"/etc/wireguard/wg1.conf"
[Interface]
PrivateKey = $private_key
Address = 192.168.0.1/24
ListenPort = 771
SaveConfig = true
PostUp =  /home/app/Guest/wg1-nat.sh
PreDown = /home/app/Guest/wg1-dwn.sh

EOF
}



newconf_wgd2() {
  local num_configs=$CONFIG_
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

    cat <<EOF >"/etc/wireguard/wg2.conf"
[Interface]
PrivateKey = $private_key
Address = 172.16.0.1/24
ListenPort = 772
SaveConfig = true
PostUp =  /home/app/Resdnts/wg2-nat.sh
PreDown = /home/app/Resdnts/wg2-dwn.sh

EOF
}


make_master_config() {
        local svr_config="/etc/wireguard/wg0.conf"
        # Check if the specified config file exists
        if [ ! -f "$svr_config" ]; then
            echo "Error: Config file $svr_config not found."
            exit 1
        fi


        #Function to generate a new peer's public key
        generate_public_key() {
            local private_key="$1"
            echo "$private_key" | wg pubkey
        }

        # Function to generate a new preshared key
        generate_preshared_key() {
            wg genpsk
        }   



    # Generate the new peer's public key, preshared key, and allowed IP
    wg_private_key=$(wg genkey)
    peer_public_key=$(generate_public_key "$wg_private_key")
    preshared_key=$(generate_preshared_key)

    # Add the peer to the WireGuard config file with the preshared key
    echo -e "\n[Peer]" >> "$svr_config"
    echo "PublicKey = $peer_public_key" >> "$svr_config"
    echo "PresharedKey = $preshared_key" >> "$svr_config"
    echo "AllowedIPs = 10.0.0.254/32" >> "$svr_config"


    server_public_key=$(grep -E '^PrivateKey' "$svr_config" | awk '{print $NF}')
    svrpublic_key=$(echo "$server_public_key" | wg pubkey)


    # Generate the client config file
    cat <<EOF >"/home/app/master-key/master.conf"
[Interface]
PrivateKey = $wg_private_key
Address = 10.0.0.254/32
DNS = 10.2.0.100,10.2.0.100
MTU = 1420

[Peer]
PublicKey = $svrpublic_key
AllowedIPs = 0.0.0.0/0
Endpoint = $SERVER_IP:$START_PORT
PersistentKeepalive = 21
PresharedKey = $preshared_key
EOF
}

start_wgd_debug() {
  printf "%s\n" "$dashes" > /dev/null 2>&1
  printf "| Starting WGDashboard in the foreground.                  |\n" > /dev/null 2>&1
  python3 "$app_name" > /dev/null 2>&1
  printf "%s\n" "$dashes" > /dev/null 2>&1
}




if [ "$#" != 1 ];
  then
    help
  
      elif [ "$1" = "install" ]; then
        install_wgd
      elif [ "$1" = "debug" ]; then
        start_wgd_debug
      elif [ "$1" = "start" ]; then
        start_wgd
      elif [ "$1" = "newconfig" ]; then
        newconf_wgd
      else
        help
    
fi
