PIS=("10.1.1.116" "10.1.1.117" "10.1.1.118")
USER="ucanlab" # username
REMOTE_DIR="/home/ucanlab/Downloads" # Pi dir
REMOTE_CMD="rxRadio.py"  # rx script name
LOCAL_SCRIPT_XMLRPC="./xmlrpcScript.py" # xmlrpc script
LOCAL_SCRIPT_ZMQ="./zmqScript.py" # ZMQ script
LOCAL_TX_SCRIPT="./txRadio.py" # tx script name

# shown in -h
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p Y|y    Populate nodes with scripts and exit (default main.py line 1)"
    echo "  -r RANGE  Specify range for populate (e.g., 116,118)"
    echo "  -l LIST   Specify list for populate (e.g., 116,117,118)"
    echo "  -n        Create a new CSV file (needs fix-dont use-just move csv manually and it will auto-create new one)"
    echo "  -z        Random channel gains (updates to channelGains.py)"
    echo "  -f1 INT   Start frequency (default 500000)"
    echo "  -f2 INT   End frequency (default 1000000)"
    echo "  -c INT    Number of channels (default 3)"
    echo "  -h        Show this help message"
    echo ""
}

# flags given from above
P_FLAG="N"
RANGE=""
LIST=""
N_FLAG="N"
Z_FLAG="N"
F1=500000
F2=1000000
C=3
while getopts "p:r:l:nz f1:f2:c:h" opt; do
    case $opt in
        p) P_FLAG="$OPTARG" ;;
        r) RANGE="$OPTARG" ;;
        l) LIST="$OPTARG" ;;
        n) N_FLAG="Y" ;;
        z) Z_FLAG="Y" ;;
        f1) F1="$OPTARG" ;;
        f2) F2="$OPTARG" ;;
        c) C="$OPTARG" ;;
        h) usage ; exit 0 ;;
        *) echo "Invalid option: -$OPTARG" >&2 ; usage ; exit 1 ;;
    esac
done

if [ "$P_FLAG" = "Y" ] || [ "$P_FLAG" = "y" ]; then
    if [ -n "$RANGE" ]; then
        python3 "$(dirname "$0")/populate.py" -r "$RANGE" --user "$USER" --remote-dir "$REMOTE_DIR"
    elif [ -n "$LIST" ]; then
        python3 "$(dirname "$0")/populate.py" -l "$LIST" --user "$USER" --remote-dir "$REMOTE_DIR"
    else
        python3 "$(dirname "$0")/populate.py" -L "${PIS[*]}" --user "$USER" --remote-dir "$REMOTE_DIR"
    fi
    exit 0
fi

echo "------------------Running Remote Rx Scripts---------------------"
for PI in "${PIS[@]}"; do
    echo "Connecting to $PI..."
    ssh -tt "${USER}@${PI}" "cd ${REMOTE_DIR} && python3 ${REMOTE_CMD} -c $C >/dev/null 2>&1" &
done

echo "------------------Running Local Tx Script---------------------"
echo "Connecting to localhost..."
python3 "${LOCAL_TX_SCRIPT}" -c $C >/dev/null 2>&1 &
echo "sleep 3"
sleep 3
echo "------------------Running XMLRPC Script---------------------"
XMLRPC_ARGS="--pis ${PIS[@]} -f1 $F1 -f2 $F2 -c $C"
if [ "$Z_FLAG" = "Y" ]; then
    XMLRPC_ARGS="$XMLRPC_ARGS -z"
fi
python3 "${LOCAL_SCRIPT_XMLRPC}" $XMLRPC_ARGS
echo "------------------Running ZMQ Script---------------------"
if [ "$N_FLAG" = "Y" ]; then
    python3 "${LOCAL_SCRIPT_ZMQ}" --pis "${PIS[@]}" -f1 "$F1" -f2 "$F2" -c "$C" -n
else
    python3 "${LOCAL_SCRIPT_ZMQ}" --pis "${PIS[@]}" -f1 "$F1" -f2 "$F2" -c "$C"
fi

echo "------------------Killing Scripts & Closing Connections---------------------"
sleep 1

for PI in "${PIS[@]}"; do
    ssh $USER@$PI "pkill -f ${REMOTE_CMD}";
done
pkill -f ${LOCAL_TX_SCRIPT}
