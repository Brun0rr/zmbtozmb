#!/bin/bash
######################################
###     AUTHOR: Bruno Ricardo Rodrigues
##  	HELPER: Luciano da Silva
##      VERSION: 2.2
###     DATE: 01/12/17
######################################

DOMAIN=$2
THREADS=5
OUTPUT_SCRIPT="/migracao/script-$2.sh"
SSH_KEY="/opt/zimbra/.ssh/zimbra"
SSH_USER="zimbra"
SSH_PORT="22"

MIG_PASSWORD=TRUE
DEFAULT_PASSWORD="123456" # If MIG_PASSWORD is set to FALSE, this will be the password
MIG_DISTRIBUTIONLIST=TRUE
MIG_WHITELIST=TRUE
MIG_BLACKLIST=TRUE
MIG_SIGNATURE_HTML=TRUE
MIG_ALIAS=TRUE
MIG_FILTERS=TRUE
MIG_FORWARD=TRUE
MIG_STATUS=TRUE
MIG_EXECUTE_AFTER=FALSE

SOURCE_SERVER="mail.zimbra.com.br"
SOURCE_USER="Admin"
SOURCE_PWD="zimpra_pass"
SOURCE_PORT=7071

TARGET_SERVER="mail2.zimbra.com.br"
TARGET_USER="Admin"
TARGET_PWD="zimbra2_pass"
TARGET_PORT=7071

zmaccounts () {
	echo "Getting all accounts..."
	ACCOUNTS=`zmprov -l gaa $DOMAIN`

	echo '#!/bin/bash' > $OUTPUT_SCRIPT
	date >> $OUTPUT_SCRIPT
	echo "echo \"Creating domain $DOMAIN...\"" >> $OUTPUT_SCRIPT
	echo "zmprov cd $DOMAIN" >> $OUTPUT_SCRIPT

	for i in $ACCOUNTS; do
        if [ `echo $i | egrep '(ham|galsync|spam|quarantine)' | wc -l` = "1" ]; then
                continue
        fi
		ATTR=`zmprov -l ga $i`
		echo "echo \"Creating account: $i...\"" >> $OUTPUT_SCRIPT
		echo "zmprov ca $i $DEFAULT_PASSWORD" >> $OUTPUT_SCRIPT
		
		if [ $MIG_PASSWORD == "TRUE" ]; then
			echo "getting password for account: $i..."
			echo "echo \"  -- Change password for account: $i...\"" >> $OUTPUT_SCRIPT
			echo "zmprov ma $i userPassword `echo "$ATTR" | grep "userPassword" | cut -d " " -f 2`" >> $OUTPUT_SCRIPT
		fi
		
		if [ $MIG_WHITELIST == "TRUE" ]; then
			WHITELIST=`echo "$ATTR" | grep -i amavisWhitelistSender | cut -d' ' -f2`
			for w in $WHITELIST; do
				echo "getting whitelist $w for account $i"
				echo "echo \"  -- Adding whitelist $w for account: $i...\"" >> $OUTPUT_SCRIPT
				echo "zmprov ma $i +amavisWhitelistSender $w" >> $OUTPUT_SCRIPT
			done
		fi
		
		if [ $MIG_BLACKLIST == "TRUE" ]; then
			BLACKLIST=`echo "$ATTR" | grep -i amavisBlacklistSender | cut -d' ' -f2`
			for b in $BLACKLIST; do
				echo "getting blacklist $b for account $i"
				echo "echo \"  -- Adding blacklist $b for account: $i...\"" >> $OUTPUT_SCRIPT
				echo "zmprov ma $i +amavisBlacklistSender $b" >> $OUTPUT_SCRIPT
			done
		fi
		
		if [ $MIG_SIGNATURE_HTML == "TRUE" ]; then
			echo "getting signature for account: $i..."
			echo "echo \"  -- Adding signature for account: $i...\"" >> $OUTPUT_SCRIPT
			NOMEASS=`echo "$ATTR" | grep -i zimbraSignatureName | cut -d' ' -f2-`
			ASSINATURA=`echo "$ATTR" | grep -i zimbraPrefMailSignatureHTML | cut -d' ' -f2- | sed 's/\"/\\\"/g'`
			echo "zmprov ma $i zimbraPrefMailSignatureHTML \"$ASSINATURA\"" >> $OUTPUT_SCRIPT
			echo "zmprov ma $i zimbraSignatureName \"$NOMEASS\"" >> $OUTPUT_SCRIPT
		fi
		
		if [ $MIG_ALIAS == "TRUE" ]; then
			echo "getting alias for account: $i..."
			ALIAS=`echo "$ATTR" | grep -i zimbraMailAlias | cut -d" " -f2`
			for a in $ALIAS; do
				echo "echo \"  -- Adding alias $a for account: $i...\"" >> $OUTPUT_SCRIPT
                echo "zmprov aaa $i $a" >> $OUTPUT_SCRIPT
			done
		fi
		
		if [ $MIG_FORWARD == "TRUE" ]; then
			echo "getting Forwarding for account: $i..."
			echo "echo \"  -- Adding forward $k for account: $i...\"" >> $OUTPUT_SCRIPT
			echo "zmprov ma $i zimbraPrefMailForwardingAddress '$(echo "$ATTR" | grep -i zimbraPrefMailForwardingAddress | cut -d" " -f2)'" >> $OUTPUT_SCRIPT
			FORWARDING=`echo "$ATTR" | grep -i "zimbraMailForwardingAddress:" | cut -d" " -f2`
			for  k in $FORWARDING; do
				echo "zmprov ma $i +zimbraMailForwardingAddress $k" >> $OUTPUT_SCRIPT
			done
		fi
		
        if [ $MIG_FILTERS == "TRUE" ]; then
			echo "getting filters for account: $i..."
			echo "echo \"  -- Adding filters for account: $i...\"" >> $OUTPUT_SCRIPT
			echo "zmprov ma $i zimbraMailSieveScript '`zmprov ga $i zimbraMailSieveScript | sed 's/zimbraMailSieveScript: //g' | grep -v "^# name"`'" >> $OUTPUT_SCRIPT
		fi
		
		if [ $MIG_STATUS == "TRUE" ]; then
			echo "getting status for account: $i..."
			ACCOUNTSTATUS=`echo "$ATTR" | grep -i zimbraAccountStatus: | cut -d" " -f2`
			MAILBOXSTATUS=`echo "$ATTR" | grep -i zimbraMailStatus: | cut -d" " -f2`
			echo "echo \"  -- Setting status for account: $i...\"" >> $OUTPUT_SCRIPT
			if [ "$ACCOUNTSTATUS" != "active" ]; then
				echo "zmprov ma $i zimbraAccountStatus $ACCOUNTSTATUS" >> $OUTPUT_SCRIPT          
			fi
			if [ "$MAILBOXSTATUS" != "enabled" ]; then
				echo "zmprov ma $i zimbraMailStatus $MAILBOXSTATUS" >> $OUTPUT_SCRIPT          
			fi	
		fi
	done

	if [ $MIG_DISTRIBUTIONLIST == "TRUE" ]; then
		echo "Getting all Distribution Lists"
		DISTRIBUTIONLIST=`zmprov -gadl $DOMAIN`
		for i in $DISTRIBUTIONLIST; do
			echo "Getting Distribution List: $i"
			echo "echo \"  -- Creating distribution list $i...\"" >> $OUTPUT_SCRIPT
			echo "zmprov cdl $i" >> $OUTPUT_SCRIPT
			MEMBERS=`zmprov -gdl $i | grep -i zimbramailforwardingaddress | cut -d" " -f2`
			MEMBERSLIST="zmprov adlm $i"
			for j in $MEMBERS; do
				MEMBERSLIST="$MEMBERSLIST $j"
			done
			echo "echo \"  -- Adding members for distribution list: $i...\"" >> $OUTPUT_SCRIPT
			echo "$MEMBERSLIST" >> $OUTPUT_SCRIPT
			echo "echo \"  -- Setting distribution list name...\"" >> $OUTPUT_SCRIPT
			echo "zmprov mdl $i DisplayName \"$(zmprov -gdl $i | grep -i DisplayName | cut -d" " -f2-)\"" >> $OUTPUT_SCRIPT
		done
	fi
	date
	chmod +x $OUTPUT_SCRIPT
	scp -i $SSH_KEY -P $SSH_PORT $OUTPUT_SCRIPT $SSH_USER@$TARGET_SERVER:$OUTPUT_SCRIPT
	rm -rf $OUTPUT_SCRIPT

	if [ $MIG_EXECUTE_AFTER == "TRUE" ]; then
		ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT "$OUTPUT_SCRIPT"
	fi
}

zmztozmig () {
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/Domains=.*/Domains=$DOMAIN/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/Threads=.*/Threads=$THREADS/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/Accounts=.*/Accounts=all/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/KeepSuccessFiles=.*/KeepSuccessFiles=FALSE/g' /opt/zimbra/conf/zmztozmig.conf"

	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/SourceZCSServer=.*/SourceZCSServer=$SOURCE_SERVER/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/SourceAdminUser=.*/SourceAdminUser=$SOURCE_USER/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/SourceAdminPwd=.*/SourceAdminPwd=$SOURCE_PWD/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/SourceAdminPort=.*/SourceAdminPort=$SOURCE_PORT/g' /opt/zimbra/conf/zmztozmig.conf"

	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/TargetZCSServer=.*/TargetZCSServer=$TARGET_SERVER/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/TargetAdminUser=.*/TargetAdminUser=$TARGET_USER/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/TargetAdminPwd=.*/TargetAdminPwd=$TARGET_PWD/g' /opt/zimbra/conf/zmztozmig.conf"
	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT  "sed -i 's/TargetAdminPort=.*/TargetAdminPort=$TARGET_PORT/g' /opt/zimbra/conf/zmztozmig.conf"

	ssh -i $SSH_KEY $SSH_USER@$TARGET_SERVER -p $SSH_PORT "/opt/zimbra/libexec/zmztozmig -f /opt/zimbra/conf/zmztozmig.conf"
}


help () {
	echo " ZMBTOZMB - By Bruno Ricardo Rodrigues/Luciano da Silva - bruno.rrodrigues@outlook.com/luciano.silva0@outlook.com"
	echo "Help"
	echo ""
	echo "Commands:"
	echo "      $0 zmaccounts { Migração de atributo }"
	echo "      $0 zmztozmig { Migração de MailBoxs }"
	echo "      $0 zmmigall { Migracao total }"
	echo "      $0 help { Ajuda }"
}

case $1 in
    "zmaccounts") zmaccounts;;
    "zmztozmig") zmztozmig;;
    "zmmigall") zmaccounts; zmztozmig;;
    "-h"|"help"|"--help") help;;
	*) echo "Migracao.sh (zmaccounts|zmztozmig|zmmigall|help)"
esac