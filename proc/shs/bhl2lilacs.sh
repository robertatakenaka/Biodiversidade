op=$1
debug=$2
START_DATE=$3
END_DATE=$4


APIKEY=b64e048b-e947-44c2-b5e3-b9ba4e47fce0


# paths
CISIS1660=../../bases/cisis1660
DB_PATH=../db
XML_PATH=../xml_path
DONE_PATH=../done/
TMP_PATH=../temp

# existing files
FST=../../bases/lildbi/dbcertif/lilacs/LILACS.fst

#
LILDB_PATH=../../bases/lildbi/dbcertif/lilacs/
LILDB_NAME=LILACS

LILDB=$LILDB_PATH/$LILDB_NAME

# to create
PROCESSED_ID_LIST=$DB_PATH/processed_id.seq
NEW_ID=$DB_PATH/new_id
NEW_ID_ISO=$DB_PATH/new_id_iso-8859-1
NEW_ID_UTF=$DB_PATH/new_id_utf-8

TMP_LILDB=$DB_PATH/temp_lilacs
NEW_LILDB=$DB_PATH/$LILDB_NAME
BIOTA_ID=$DB_PATH/biota_fapesp_lildbi_iso-8859-1

#
TODO_LIST=$DB_PATH/todolist

if [ ! -d $TMP_PATH ]
then
    mkdir -p $TMP_PATH
fi
if [ ! -d $DB_PATH ]
then
    mkdir -p $DB_PATH
fi
if [ ! -d $XML_PATH/i ]
then
    mkdir -p $XML_PATH/i
fi
if [ ! -d $XML_PATH/t ]
then
    mkdir -p $XML_PATH/t
fi

# create ../db/processed_ids which contains the processed title and its items id
if [ -f $LILDB.mst ]
then
    $CISIS1660/mx $LILDB fst=@$FST fullinv=$LILDB
    $CISIS1660/mx $LILDB btell=0 "DB_BHL$" lw=9999 "pft=v901^*,'|',v900^*/" now > $PROCESSED_ID_LIST
    $CISIS1660/mx $LILDB btell=0 "DB_BHL$" lw=9999 "pft=mfn,'|',v901^*,'|',v965^d,'|',v965^*/" now | sort -u -r > last_id
    $CISIS1660/mx seq=last_id create=last_id now -all
    $CISIS1660/mx last_id count=1 "pft=v2" now> last_id
    $CISIS1660/mx last_id count=1 "pft=v3" now> last_date
else
    $CISIS1660/mx null count=1 "proc='a333{',date,'{'" create=$LILDB now -all
    $CISIS1660/mx $LILDB fst=@$FST fullinv=$LILDB

    echo > $PROCESSED_ID_LIST
fi

if [ -f $NEW_ID ]
then
rm $DB_PATH/new_id
fi
if [ -f $NEW_ID_ISO ]
then
    rm $NEW_ID_ISO
fi
if [ -f $NEW_ID_UTF ]
then
    rm $NEW_ID_UTF
fi

# download titles.xml
if [ "@$op" == "@download_all" ]
then
    PARAM3=$PROCESSED_ID_LIST
    PARAM4=$NEW_ID
    
    OP=$op
fi
if [ "@$op" == "@download_incr" ]
then
    if [ ! -f last_date ]
    then
        echo "2009-03-29" > last_date
    fi
    s_date=`cat last_date`
    $CISIS1660/mx null count=1 "pft=s(date)*0.4,'-',s(date)*4.2,'-',s(date)*6.2" now > curr_date
    e_date=`cat curr_date`

    PARAM3=$PROCESSED_ID_LIST
    PARAM4=$NEW_ID
    PARAM5=$s_date
    PARAM6=$e_date
    PARAM7=`cat last_id`
    if [ ! "@$START_DATE" == "@" ]
    then
        if [ ! "@$END_DATE" == "@" ]
        then
            PARAM5=$START_DATE
            PARAM6=$END_DATE
        fi
    fi
    
    OP=$op
fi

if [ "@$OP" == "@" ]
then
    echo "Usage: $0 [ download_all | download_incr  ]"
    echo You tried to execute
    echo $0 $1 $2 $3 $4 $5 $6
else
    echo Executing python3 ../bhl2lilacs/call_bhl2lilacs.py $OP $XML_PATH $PARAM3 $PARAM4  $PARAM5 $PARAM6 $PARAM7
    if [ "@$debug" == "@no" ]
    then
        python3 ../bhl2lilacs/call_bhl2lilacs.py $OP $XML_PATH $PARAM3 $PARAM4  $PARAM5 $PARAM6 $PARAM7

        $CISIS1660/mx null count=0 create=$NEW_LILDB now -all
        $CISIS1660/mx seq=lang.gzm.seq create=lang now -all

        # check biota
        $CISIS1660/mx $LILDB btell=0 "DB_FAPESP$" count=1 lw=9999 "pft=v4" now > biota
        EXIST_BIOTA=`cat biota`
        if [ "@$EXIST_BIOTA" == "@" ]
        then
            echo create BIOTA
            $CISIS1660/id2i $BIOTA_ID create=$BIOTA_ID
            $CISIS1660/mx $BIOTA_ID "proc='d13',if v13='*' then if v12[1]^i<>'en' then (if v12^i='en' then 'a13{',v12^*,'{' fi) fi fi" "proc='s'" append=$NEW_LILDB now -all
        echo $NEW_LILDB
        $CISIS1660/mx $NEW_LILDB +control now
        fi

        if [ -f $LILDB.mst ]
        then
            echo backup LILACS
            if [ -f ../db/LILACS.bkp.tgz ]
            then
               mv ../db/LILACS.bkp.tgz ../db/LILACS.bkp.`date '+%Y%m%d-%H%M%S'`.tgz
            fi
            tar cvfzp ../db/LILACS.bkp.tgz $LILDB.???
            echo $LILDB append to $NEW_LILDB
            #$CISIS1660/mx $LILDB "proc=if p(v940) then 'd40','a40{',v940^*,'{' fi" copy=$LILDB now -all
            $CISIS1660/mx $LILDB gizmo=lang,40 mfrl=99000 fmtl=99000  "proc=@fix.prc" append=$NEW_LILDB now -all
            echo $NEW_LILDB
            $CISIS1660/mx $NEW_LILDB +control now
            echo $LILDB
            $CISIS1660/mx $LILDB +control now
        fi

        if [ -f $NEW_ID_ISO ]
        then
            echo create $TMP_LILDB
            $CISIS1660/id2i $NEW_ID_ISO create=$TMP_LILDB
        
            if [ -f $TMP_LILDB.mst ]
            then
                echo $TMP_LILDB append to $NEW_LILDB
                $CISIS1660/mx $TMP_LILDB gizmo=lang,40 mfrl=99000 fmtl=99000 "proc=@add.prc" "proc='s'" append=$NEW_LILDB now -all
        echo $TMP_LILDB
        $CISIS1660/mx $TMP_LILDB +control now
        echo $NEW_LILDB
        $CISIS1660/mx $NEW_LILDB +control now
            fi
        fi

        if [ -f $NEW_LILDB.mst ]
        then
            $CISIS1660/mx $NEW_LILDB fst=@$FST fullinv=$NEW_LILDB
            cp $NEW_LILDB.??? $LILDB_PATH
        fi
    fi
fi

