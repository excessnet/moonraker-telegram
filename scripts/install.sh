#!/bin/bash

MYDIR=`dirname $0`
DIR="`cd $MYDIR/../; pwd`"

echo "========= moonraker-telegram - Installation Script ==========="

sudo apt-get install bc python3 python3-pip python3-setuptools
pip3 install wheel websocket_client requests telepot

echo -e "\n========= Check for config ==========="

if ! grep -q "config_dir=" $DIR/multi_config.sh
    then
    echo -e "========= pleas input your settings description on github ==========="
    echo -e "please enter your moonraker config path"
    echo -e "and press enter (like /home/pi/klipper_config):"
    read CONFIG 
    echo "# moonraker config path" >> $DIR/multi_config.sh
    echo "config_dir=$CONFIG" >> $DIR/multi_config.sh
fi
if ! grep -q "multi_instanz=" $DIR/multi_config.sh
    then 
    echo "if you want to use multiple instances on one pi, enter an identifier here. this is needed to create the sytemd service"
    echo "If you only use it once per hardware, simply press enter."
    read INSTANZ 
    echo "# if you want to use multiple instances on one pi, enter an identifier here. this is needed to create the sytemd service." >> $DIR/multi_config.sh
    echo "multi_instanz="moonraker-telegram$INSTANZ"" >> $DIR/multi_config.sh      
fi

. $DIR/multi_config.sh

if ! [ -e $config_dir/telegram_config.sh ]
then
    sudo cp $DIR/example_config.sh $config_dir/telegram_config.sh
    sudo chmod 777 $config_dir/telegram_config.sh
fi

if [ -L $config_dir/telegram_config.sh ]
then
    sudo rm $config_dir/telegram_config.sh
    sudo cp $DIR/telegram_config.sh $config_dir/telegram_config.sh
    sudo rm $DIR/telegram_config.sh
    sudo chmod 777 $config_dir/telegram_config.sh
fi

. $config_dir/telegram_config.sh
    
echo -e "\n========= set permissions ==========="
sleep 1
sudo chmod 777 $config_dir/telegram_config.sh

echo -e "\n========= install systemd ==========="

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
MTPATH=$(sed 's/\/scripts//g' <<< $SCRIPTPATH)

SERVICE=$(<$SCRIPTPATH/moonraker-telegram.service)
MTPATH_ESC=$(sed "s/\//\\\\\//g" <<< $MTPATH)
SERVICE=$(sed "s/MT_DESC/$multi_instanz/g" <<< $SERVICE)
SERVICE=$(sed "s/MT_USER/$USER/g" <<< $SERVICE)
SERVICE=$(sed "s/MT_DIR/$MTPATH_ESC/g" <<< $SERVICE)

echo "$SERVICE" | sudo tee /etc/systemd/system/$multi_instanz.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable $multi_instanz

if crontab -l | grep -i /home/pi; then
    crontab -u pi -l | grep -v "$DIR"  | crontab -u pi -
    sleep 1
    (crontab -u pi -l ; echo "") | crontab -u pi -
fi

echo -e "\n========= start systemd for $multi_instanz ==========="

sudo systemctl stop $multi_instanz
sudo systemctl start $multi_instanz

echo -e "\n========= installation end ==========="
echo "========= open and edit your config with ==========="
echo "========= mainsail or fluidd and edit the telegram_config.sh ==========="

exit 1
