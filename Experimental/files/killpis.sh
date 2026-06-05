PIS=("10.1.1.116" "10.1.1.117" "10.1.1.118")
USER="ucanlab" # username
REMOTE_DIR="/home/ucanlab/Downloads" # Pi dir
REMOTE_CMD="SingleRX1.py"  # Pi script name

for PI in "${PIS[@]}"; do
    ssh $USER@$PI "pkill -f ${REMOTE_CMD}";
done
