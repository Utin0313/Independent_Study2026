from here in terminal, run ./files/main.sh -h to see help

dataTaken folder : output P_OBS csv file and manual .txt explanation

channelGains.json : saves channel gains, if used more channels than defined gains, channels resort to default (i believe 1)

main.sh : main script ~ runs rest

killpis.sh : In case if connection (zmq) isnt closed automatically.

txRadio.py : TX GNUradio script

populate.py : Sends scripts (by default only SingleRX1.py) to other locations defined by -r and -l (ex: -r 116,119). Default locations to whatever is listed in main.sh at line 1.

rxRadio.py : RX GNUradio script

xmlrpcScript.py : XMLRPC script to control variables.

zmqScript.py : ZMQ script to collect data.
