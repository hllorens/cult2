#!/bin/bash

SCRIPT_PATH=$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")
destination="$SCRIPT_PATH/../../cult-data-stock-google";
destination_eps_hist="$SCRIPT_PATH/../../cult-data-stock-eps-hist";

if [ ! -d $destination ];then echo "ERROR $destination does not exist"; exit -1; fi
echo "$SCRIPT_PATH and $destination"

rm -rf $destination/*.log $destination/dividend_yield.json $destination/stocks.json $destination/stocks.formated.json2 $destination/eps-hist.json


timestamp=`date +'%Y-%m-%d_%H-%M-%S'` # consider using it in wget if somehow cache is used...
current_year=`date +'%Y'`
current_date=`date +'%Y-%m-%d'`

stock_query="INDEXBME:IB";
stock_query="$stock_query,BME:ACS,BME:ACX,BME:AENA,BME:AMS,BME:ANA,BME:BBVA,BME:BKIA,BME:BKT,BME:CABK,BME:DIA";
stock_query="$stock_query,BME:ELE,BME:ENG,BME:FCC,BME:FER,BME:SGRE,BME:GAS,BME:GRF,BME:IAG,BME:IBE,BME:IDR"; # BME:GAM -> BME:SGRE
stock_query="$stock_query,BME:ITX,BME:MAP,BME:MEL,BME:MTS,BME:OHL,BME:REE,BME:REP,BME:SAB,BME:SAN,BME:SCYR";
# IBEX quebrados o quitados: ,BME:POP
stock_query="$stock_query,BME:TEF,BME:TL5,BME:TRE";
stock_query="$stock_query,INDEXSTOXX:SX5E";
stock_query="$stock_query,INDEXNASDAQ:NDX";
stock_query="$stock_query,INDEXSP:.INX";
stock_query="$stock_query,NASDAQ:GOOG,NASDAQ:GOOGL,NASDAQ:MSFT,NASDAQ:EBAY,NASDAQ:AMZN"; # ,NASDAQ:YHOO no longer a company but a fund (AABA)
stock_query="$stock_query,NASDAQ:FB,NYSE:TWTR,NYSE:SNAP";
stock_query="$stock_query,NASDAQ:NUAN,NASDAQ:CMPR,NYSE:PSX,NASDAQ:AAPL,NASDAQ:INTC,NASDAQ:BKCC";
stock_query="$stock_query,NASDAQ:PCLN,NASDAQ:TRIP,NASDAQ:EXPE";
stock_query="$stock_query,NYSE:ING,NYSE:MMM,NYSE:JNJ,NYSE:GE,NYSE:WMT,NYSE:IBM,NYSE:SSI";
stock_query="$stock_query,NYSE:KO,NYSE:DPS,VTX:NESN,NYSE:PEP,EPA:BN";
stock_query="$stock_query,NYSE:VZ,NYSE:T,NASDAQ:VOD";
stock_query="$stock_query,NYSE:XOM,NYSE:DIS";
stock_query="$stock_query,NYSE:SNE,OTCMKTS:NTDOY";
stock_query="$stock_query,NASDAQ:NFLX,NYSE:TWX,NASDAQ:CMCSA,NASDAQ:FOXA"; # HBO is part of time Warner
stock_query="$stock_query,NYSE:TM,FRA:VOW,NYSE:GM,EPA:UG,NYSE:F";
stock_query="$stock_query,NASDAQ:SPWR,NASDAQ:TSLA";  # ,NASDAQ:SCTY acquired by TESLA 2016/2017?

# FUTURE:
# Uber is not yet in stock, IPO estimated 2017
# MagicLeap virutal reality (GOOG will buy it?)

# SEE HOW WE COULD ADD USDEUR to alert the user when dollar is expensive (close to 1...). Low pri
#https://finance.google.com/finance?q=usdeur


sendemail="false"
echo "$timestamp Downloading to $destination (timestamp=${timestamp})" | tee $destination/ERROR.log

# GETTING THE YELD
vals=","
for i in $(echo ${stock_query} | sed "s/,/\n/g");do
    echo "Getting div/yield for $i" | tee -a $destination/ERROR.log; 
    theinfo=`echo "https://www.google.com/finance?q=$i" | wget -O- -i- | tr "\n" " " |  sed "s/<title>/\ntd <title>/g" | sed "s/<\/title>/\n/g" |  sed "s/<td/\ntd/g" | sed "s/<\/td>/\n/g" | sed "s/<\/table>/\n/g" | grep "^td " | sed "s/&nbsp;//g"`
    title=`echo "$theinfo"  | grep "<title>" | sed "s/^[^>]*>[[:blank:]]*\([^:]*\):.*\$/\1/" | sed "s/ S\.\?A\.\?\$//" | sed "s/ [Ii][Nn][Cc]\.\?\$//"`
    yieldval=`echo "$theinfo"  | grep -A 1 dividend_yield | grep '="val"' | sed "s/^[^>]*>\([^[:blank:]]*\)[[:blank:]]*/\1/" | sed "s/^[^\/]*\/\([^[:blank:]]*\)[[:blank:]]*/\1/"`
    divval=`echo "$theinfo"  | grep -A 1 dividend_yield | grep '="val"' | sed "s/^[^>]*>\([^[:blank:]]*\)[[:blank:]]*/\1/" | sed "s/^\([^\/]*\)\/.*\$/\1/"`
    perval=`echo "$theinfo"  | grep -A 1 pe_ratio | grep '="val"' | sed "s/^[^>]*>\([^[:blank:]]*\)[[:blank:]]*/\1/"`
    betaval=`echo "$theinfo"  | grep -A 1 "\"beta\"" | grep '="val"' | sed "s/^[^>]*>\([^[:blank:]]*\)[[:blank:]]*/\1/"`
    epsval=`echo "$theinfo"  | grep -A 1 "\"eps\"" | tail -n 1 | sed "s/^[^>]*>\([^[:blank:]]*\)[[:blank:]]*/\1/"`
    roeval=`echo "$theinfo"  | grep -A 1 "Return on average equity" | grep '="val"' | sed "s/^[^>]*>\([^[:blank:]]*\)[[:blank:]]*/\1/"`
    range_52week=`echo "$theinfo"  | grep -A 1 range_52week | grep '="val"' | sed "s/^[^>]*>\([^[:blank:]]*\)[[:blank:]]*/\1/" | sed "s/,//g"`
    name=`echo $i | cut -d : -f 2`;
    market=`echo $i | cut -d : -f 1`
    vals="${vals},\"$i\": {\"name\": \"$name\",\"market\": \"$market\",\"title\": \"$title\",\"yield\": \"$yieldval\",\"dividend\": \"$divval\",\"eps\": \"$epsval\",\"beta\": \"$betaval\",\"per\": \"$perval\",\"roe\": \"$roeval\",\"range_52week\": \"$range_52week\" }"
    sleep 1; # to avoid overloading google
done
echo "{ ${vals} }" | sed "s/,,//g" > $destination/dividend_yield.new.json
if [ `cat "$destination/dividend_yield.new.json" | json_pp -f json  > /dev/null;echo $?` -ne 0 -o `cat $destination/dividend_yield.new.json | wc -c` -le 2000 ];then
    echo "ERROR: Dividend/yield info is not valid json or too small... < 2000 chars " >> $destination/ERROR.log;
    echo "START $destination/dividend_yield.new.json" >> $destination/ERROR.log;
    cat "$destination/dividend_yield.new.json" >> $destination/ERROR.log;
    echo "END $destination/dividend_yield.new.json" >> $destination/ERROR.log;
    cp $destination/ERROR.log ${destination}-errors/ERROR-$timestamp.log
    cat $destination/ERROR.log | mail -s "ERROR in stock download" hectorlm1983@gmail.com
    exit 1;
else
    mv $destination/dividend_yield.new.json $destination/dividend_yield.json
fi

echo 'Getting div/yield finished SUCCESS' | tee -a $destination/ERROR.log;

# GETTING STOCK INFO
echo "  wget -O $destination/stocks.json \"http://www.google.com/finance/info?q=${stock_query}\"" | tee -a $destination/ERROR.log;
wget -O $destination/stocks.json "http://www.google.com/finance/info?q=${stock_query}" 2> /dev/null
cat  $destination/stocks.json | tr -d "\n" | sed "s/^\/\/ //" > $destination/stocks.json2
if [ `cat "$destination/stocks.json2" | json_pp -f json  > /dev/null;echo $?` -ne 0 -o `cat $destination/stocks.json2 | wc -c` -le 2000 ];then
    echo "ERROR: stocks.json2 is not valid json or too small... < 2000 chars " | tee -a $destination/ERROR.log;
    echo "START $destination/stocks.json2" >> $destination/ERROR.log;
    cat "$destination/stocks.json2" >> $destination/ERROR.log;
    echo "END $destination/stocks.json2" >> $destination/ERROR.log;
    cp $destination/ERROR.log ${destination}-errors/ERROR-$timestamp.log
    cp $destination/stocks.json ${destination}-errors/stocks-$timestamp.json
    cat $destination/ERROR.log | mail -s "ERROR in stock download" hectorlm1983@gmail.com
    exit 1;
else
    echo " mv $destination/stocks.json2 $destination/stocks.json" | tee -a $destination/ERROR.log; 
    mv $destination/stocks.json2 $destination/stocks.json
fi

# UPDATE eps-hist
echo 'wget --timeout=180 -q -O $destination/eps-hist.json "http://www.cognitionis.com/cult/www/backend/update_eps_hist.php"' | tee -a $destination/ERROR.log;
wget --timeout=180 -q -O $destination/eps-hist.json "http://www.cognitionis.com/cult/www/backend/update_eps_hist.php" 2>&1 >> $destination/ERROR.log;
diff $destination/eps-hist.json $destination_eps_hist/eps-hist.json >> $destination/ERROR.log;
if [ $? -eq 1 ];then
    if [ `sed "s/,/\n/g" $destination/eps-hist.json | wc -l` -gt `sed "s/,/\n/g" $destination_eps_hist/eps-hist.json | wc -l` ];then 
        cp $destination/eps-hist.json $destination_eps_hist/eps-hist.json
        cp $destination/eps-hist.json  ${destination}-historical/${current_date}.eps-hist.json
    fi
fi

echo 'wget --timeout=180 -q -O $destination/stocks.formated.json2 "http://www.cognitionis.com/cult/www/backend/format_data_for_stock_alerts.php"' | tee -a $destination/ERROR.log;
wget --timeout=180 -q -O $destination/stocks.formated.json2 "http://www.cognitionis.com/cult/www/backend/format_data_for_stock_alerts.php" 2>&1 >> $destination/ERROR.log;
if [ `cat "$destination/stocks.formated.json2" | json_pp -f json  > /dev/null;echo $?` -ne 0 -o `cat $destination/stocks.formated.json2 | wc -c` -le 2000 ];then
    echo "ERROR: stocks.formated.json2 is not valid json or too small... < 2000 chars " >> $destination/ERROR.log;
    cat "$destination/stocks.formated.json2" >> $destination/ERROR.log;
    echo "END $destination/stocks.formated.json2" >> $destination/ERROR.log;
    cp $destination/ERROR.log ${destination}-errors/ERROR-$timestamp.log
    cat $destination/ERROR.log | mail -s "ERROR in stock download" hectorlm1983@gmail.com
    exit 1;
else
    echo "mv $destination/stocks.formated.json2 $destination/stocks.formated.json" | tee -a $destination/ERROR.log; 
    mv $destination/stocks.formated.json2 $destination/stocks.formated.json
    cp $destination/stocks.formated.json  ${destination}-historical/${current_date}.stocks.formated.json
    # comment out this line when you finish debug
    #cp $destination/stocks.formated.json  ${destination}-historical/${timestamp}.debug.stocks.formated.json
fi


echo "process alerts..."
if [ "$sendemail" == "true" ];then 
	echo "sending email errors!" | tee -a $destination/ERROR.log; 
	wget --timeout=180 -q -O $destination/data-download.log http://www.cognitionis.com/cult/www/backend/send-data-download-errors.php?autosecret=1secret > $destination/last-download-data-errors.log; 
fi
echo "sending email alerts if any!" | tee -a $destination/ERROR.log; 
wget --timeout=180 -q -O $destination/stock-alerts.log http://www.cognitionis.com/cult/www/backend/send-stock-alerts-fire.php?autosecret=1secret&gendate=$current_date > $destination/last-stock-alerts-errors.log; 

cp $destination/ERROR.log ${destination}/SUCCESS-$timestamp.log

