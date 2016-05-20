#!/bin/bash

#clock:		0 Hz
#vdd:		0 (invalid)
#bus mode:	1 (open drain)
#chip select:	0 (don't care)
#power mode:	0 (off)
#bus width:	0 (1 bits)
#timing spec:	0 (legacy)
#signal voltage:0 (3.30 V)


ERROR_PARAM=-200
err=0

if [ -z "$1" ]

then
echo "Help:"
echo "You need some parameters, such as 'mmc0' '1' '2' '3'"
echo "You need superuser permission, eg: sudo mmc.sh mmc0 1 2 3"
echo "How to select the 1 2 3?"
echo "	1: Start Case 1: check eMMC ios parameters"
echo "	2: Start Case 2: check eMMC partiton tables"
echo "	3: Start Case 3: Do eMMC mount/umount validation"
echo "	                 Do eMMC Data read/write stability validation"
echo "How to select the mmcx?"
echo "	mmc0 or mmc1 or mmc2..., that is indicating which"
echo "	controller is dedicated for eMMC, not SD,not SDIO"
echo "	run 'dmesg', and check it is mmc0 or mmc1 or mmc2..."
exit 1
fi

for ((loop=1; loop<1000; loop++))
do
	echo loop test $loop times.

for i in $*
do 
if [ $i == 1 ]
then
	echo "***********************************************"
	echo "****Start Case 1: check eMMC ios parameters****"
	echo "***********************************************"
	cat /sys/kernel/debug/$1/ios > $PWD/tempfile

	checkvalid=$(awk -F: '/signal voltage/ {print $2}' $PWD/tempfile | awk '{print 1}')
	if [ -z $checkvalid ]
	then
		exit 1
	fi

	cat /sys/kernel/debug/$1/ios

	VAR0=$(awk -F: '/actual clock/ {print $2}' $PWD/tempfile | awk '{print $1}')
	echo $VAR0

	VAR3=$(awk -F: '/vdd/ {print $2}' $PWD/tempfile | awk '{print $1}')
	echo $VAR3

	VAR4=$(awk -F: '/bus width/ {print $2}' $PWD/tempfile | awk '{print $1}')
	echo $VAR4

	VAR1=$(awk -F: '/signal voltage/ {print $2}' $PWD/tempfile | awk '/1.8/ {print 1}')
	echo $VAR1

	VAR5=$(awk -F: '/signal voltage/ {print $2}' $PWD/tempfile | awk '/3.3/ {print 1}')
	echo $VAR5

	VAR6=$(awk -F: '/signal voltage/ {print $2}' $PWD/tempfile | awk '/1.2/ {print 1}')
	echo $VAR6

	VAR2=$(awk -F: '/timing spec/ {print $2}' $PWD/tempfile | awk '{print $1}')
	echo $VAR2

	echo "Diagnose Status:"
	#1. check clock:
	echo "	>>Check clock:"
	if [ -z $VAR0 ]
	then
		echo "		1. error!!, eMMC disk bus clock is 0, please check!!"
		err=1
	elif [ ! -z $VAR0 ]
	then
		echo "		1. eMMC disk bus clock is ok($VAR0)!!"
	fi
	#2. check VDD:
	echo "	>>Check vdd:"
	if [ $VAR3 -eq 0 ]
	then
		echo "		2. error!!, eMMC disk VDD is 0, please check!!"
		err=1
	elif [ $VAR3 -ne 0 ]
	then
		echo "		3. eMMC disk VDD is ok($VAR3)!!"
	fi
	#3. check bus width:
	echo "	>>Check bus width:"
		VAR4=$(echo 2 | awk "{print 2^$VAR4}")
		echo "		4. eMMC work at bus width is $VAR4 bits, Does host support?"
	#4. check mode match:
	echo "	>>Check mode match:"
	if [ ! -z $VAR1 ] && [ $VAR2 -ge 3 ]
	then
		echo "		5. eMMC bus mode does match successfully(io voltage:1.8V)!!"
	elif [ ! -z $VAR1 ] && [ $VAR2 -lt 3 ]
	then
		echo "		5. eMMC bus mode does match failed(io voltage:1.8V)!!"
		err=1
	fi

	if [ ! -z $VAR5 ] && [ $VAR2 -lt 3 ]
	then
		echo "		5. eMMC bus mode does match successfully(io voltage:3.3V)!!"
	elif [ ! -z $VAR5 ] && [ $VAR2 -ge 3 ]
	then
		echo "		5. eMMC bus mode does match failed(io voltage:3.3V)!!"
		err=1
	fi

	if [ ! -z $VAR6 ]
	then
		echo "		5. Can you really confirm your eMMC work io voltage is 1.2V)???"
		err=1
	fi

	echo "****End Case 1****"
	echo "Diagnose result:"
	if [ $err -eq 1 ]
	then
		echo "	>>error!!Your eMMC can not identify successfully, please check identification stage codes"
		echo "		>> Can you check the ADMA work? eMMC bus width match your expect?"
		err=0
		exit 1
	fi
		echo "	>>OK!!Your eMMC can identify successfully, please go next step test!!"

fi
if [ $i == 2 ]
then
	echo "************************************************"
	echo "****Start Case 2: check eMMC partiton tables****"
	echo "************************************************"
	cat /proc/partitions
	cat /proc/partitions > $PWD/tempfile
	echo "Diagnose result:"
	checkvalid=$(awk -F: '/mmcblk/ {print $2}' $PWD/tempfile | awk '{print 1}' | sed -n '1p' )
	if [ -z $checkvalid ]
	then
		echo "	>>error!!I can not find mmcblk* partition informations"
		echo "		>> Can you check the ADMA work? eMMC bus width match your expect?"
		echo "		>> It seems data tramsfer stage has some issues for your eMMC"
		exit 1
	fi

	echo "	>>OK!! In theory, Your eMMC can work, but if you can not see 'mmcblkxpx', "
	echo "		you must make partitions table use tools like 'gparted', mkfs.."

fi
if [ $i == 3 ]
then
	echo "*****************************************************"
	echo "****Start Case 3: Do eMMC mount/umount validation****"
	echo "****Do eMMC Data read/write stability/performance validation****"
	echo "*****************************************************"
		ls -l  /dev/mmcblk* > $PWD/tempfile
		mmcblkx=$(awk '/mmcblk/ {print $NF}' $PWD/tempfile | sed -n '1p')
		mmcblkxp=$mmcblkx"p"1
	echo "	>>Identify your eMMC has one DATA area partition: $mmcblkxp"
	echo "	>>Create one mount folder: mnt in current folder"
		if [ ! -d "$PWD/mnt" ]
		then
			mkdir $PWD/mnt
		fi
	echo "	>>Test mount/umount 100 times for $mmcblkxp"
		echo "		>>Firstly, we try to unmount, but if eMMC still be in umount status"
		echo "		>>You maybe see one info: 'umount: /dev/mmcblk0p1: not mounted', it is normal."
	for (( times=1; times <= 60; times++))
		do
		#echo "	>>1. Do umount $mmcblkxp"
			umount $mmcblkxp
		#echo "	>>2. Do mount: mount -t ext4 $mmcblkxp $PWD/mnt"
			mount -t ext4 $mmcblkxp $PWD/mnt
			sleep 1
		printf "\r--Finish %d times mount/umount test" $times
	done
	printf "\n"
fi

if [ $i == 4 ]
then
	echo "******************************************************************"
	echo "****Start Case 4: Do eMMC Data read/write stability validation****"
	echo "******************************************************************"

	echo ">>Check partition size"
		size=$(df -m | grep /dev/mmcblk0p1 | awk '{print $2}')
		echo "	>>Partition size: $size Mbytes"
	echo ">>Create the test files in current folder"
		echo "	>>1G size file making--------"
			if [ ! -e $PWD/1Gfile ]
			then
				dd if=/dev/zero of=$PWD/1Gfile bs=1M count=1024
			fi
		echo "	>>1K size file making--------"
			if [ ! -e $PWD/1Kfile ]
			then
				dd if=/dev/zero of=$PWD/1Kfile bs=1 count=1024
			fi
		echo "	>>$size+10 Mbytes size file making--------"
			extendsize=$[$size + 10]
			if [ ! -e $PWD/Fullsizefile$extendsize ]
			then
				echo "		>>>total size is :$extendsize"
				dd if=/dev/zero of=$PWD/Fullsizefile$extendsize bs=1M count=$extendsize
			fi
	echo "1. Test to write file that its size is larger than partition size(here is :$size Mbytes)"
		echo "	>>This test may be take more time since file is large!!!, please wait.--------"
		#Before do this test, we must keep eMMC disk no any data!!
		rm -rf $PWD/mnt/*
		if [ -e $PWD/mnt/Fullsizefile$extendsize ]
		then
			rm -rf $PWD/mnt/Fullsizefile$extendsize
		fi
		cp $PWD/Fullsizefile$extendsize $PWD/mnt 2> $PWD/Fullsizefile-tempfile
		nospace=$(awk '/No space left on device/{print 1}' $PWD/Fullsizefile-tempfile | sed -n '1p')
		rm -rf $PWD/Fullsizefile-tempfile
		echo $nospace
		if [ -z $nospace ]
		then
			echo "		>>>Your current partition is doing write full test--------"
			echo "		>>>But it seems to have some errors happened, please check--------"
			exit 1
		fi
			echo "		>>>Your current partition has write full, no space left--------"
			echo "		>>>If the following test no error, we think write full test is passing!!!--------"
			echo "		>>>But if the following test have errors, please consider its impacting!!!--------"
			echo "		>>>Or try to re-format your current partitions to resolve this issues!!!--------"
		if [ -e $PWD/mnt/Fullsizefile$extendsize ]
		then
			rm -rf $PWD/mnt/Fullsizefile$extendsize
		fi
		rm -rf $PWD/mnt/*
		echo "	>>>We have to sync or umount to make eMMC sync --------"
		echo "	>>>Here, we are using the 'sync' cmd, but if no --------"
		echo "	>>>support this cmd, you must do umount this partition --------"
		echo "	>>>or else, you must not go next test!!!! --------"
		cd $PWD/mnt && sync && cd -
	echo "2. Test write-->read-->md5-->umount-->mount-->md5-->delete-->rewrite-->reread-->remd5 for 1G file"
	for (( times=1; times <= 2; times++))
		do
		echo "	>>Write 1G size file to eMMC--------"
			cp $PWD/1Gfile $PWD/mnt
			sync
		echo "	>>Read 1G size file to externel disk named 1Gfile-tmp--------"
			cp $PWD/mnt/1Gfile $PWD/1Gfile-tmp
			sync
		echo "	>>check the MD5 for 1Gfile-tmp and 1Gfile --------"
		echo "		>>check the MD5 for source file 1Gfile--------"
				md5src=$(md5sum $PWD/1Gfile | awk '{print $1}')
				echo $md5src
		echo "		>>check the MD5 for 1Gfile-tmp--------"
				md5dest=$(md5sum $PWD/1Gfile-tmp | awk '{print $1}')
				echo $md5dest

		if [ $md5src != $md5dest ]
		then
			echo "		>>error!!!, MD5 value does not match between 1Gfile-tmp and 1Gfile --------"
			exit 1
		fi
			echo "		>>MD5 value matching between 1Gfile-tmp and 1Gfile --------"
			echo "		>>>Basically, your eMMC write and read are ok now!! --------"
		echo "	>>Umount eMMC disk--------"
		#echo "	>>1. Do umount $mmcblkxp"
			umount $mmcblkxp
			sleep 1
		echo "	>>Re-mount eMMC disk--------"
			mount -t ext4 $mmcblkxp $PWD/mnt
			sleep 1
		echo "	>>check the MD5 for 1Gfile in eMMC disk folder $PWD/mnt/1Gfile --------"
			md5dest=$(md5sum $PWD/mnt/1Gfile | awk '{print $1}')
			echo $md5dest
			if [ $md5src != $md5dest ]
			then
				echo "		>>error!!!, MD5 value does not match, Your umount/mount will crash data---"
				echo "		>>error!!!, it seems eMMC has some issues when do mount/umount test!!!---"
				exit 1
			fi
				echo "		>>MD5 value matching between 1Gfile of eMMC and 1Gfile source --------"
				echo "		>>>Basically, your eMMC mount/umount are ok now, it keeps the right files!!--"

		echo "	>>Delete 1Gfile from eMMC disk--------"
			rm -rf $PWD/mnt/1Gfile
			sync
			if [ -e $PWD/mnt/1Gfile ]
			then
				echo "		>>Failed to Delete 1Gfile from eMMC disk--------"
				exit 1
			fi
				echo "		>>OK to Delete 1Gfile from eMMC disk--------"
		if [ $times -eq 1 ]
		then
			echo "	>>Start test reWrite/reread/redelete/remd5 1G size file to eMMC--------"
		fi
	done
#fi
#if [ $i == 4 ]
#then
	echo "4. Test write-->read-->md5 for 1K file, loop 102400 times, 100M bytes files totally"
	if [ -d $PWD/mnt/tmp ]
	then
		rm -rf $PWD/mnt/tmp
	fi

	if [ -d $PWD/tmp ]
	then
		rm -rf $PWD/tmp
	fi

	mkdir $PWD/mnt/tmp

	for (( times=1; times <= 102400; times++))
		do
		printf "\r>>Write 1K size file to eMMC, current loop %d times, need loop 102400 times, about 100M bytes files" $times
		cp $PWD/1Kfile $PWD/mnt/tmp/1Kfile$times
	done
	sync
	echo "	>>Read 1K size file to externel disk tmp folder, about 100M sizes files.--------"
		cp -r $PWD/mnt/tmp $PWD/tmp
		sync
	echo "	>>check the MD5 for 1Kfile[1-102400] and 1Kfile --------"
		echo "		>>check the MD5 for source file 1Kfile--------"
				md5src=$(md5sum $PWD/1Kfile | awk '{print $1}')
				echo $md5src
			for ((times=1; times <= 102400; times++))
				do
				printf "\r		>>check if the MD5 of 1Kfile%d matched the $md5src" $times

				md5dest=$(md5sum $PWD/tmp/1Kfile$times | awk '{print $1}')

				if [ $md5src != $md5dest ]
				then
					printf "\n"
					echo "		>>error!!!, MD5 value does not match for 1Kfile$times---------"
					exit 1
				fi
			done
					printf "\n"
					echo "		>>MD5 value matching between 1kfile[1-102400] and 1Kfile --------"
					echo "		>>>Basically, your eMMC write and read are ok now!! --------"
#fi
#if [ $i == 5 ]
#then
	echo "5. Test write-->read-->md5-->delete-->rewrite-->reread-->remd5 for [1-1024]bytes, [1-1024]Kbytes files, loop 1 times, 100M bytes files totally"
	echo "	>>Create the test files in current source folder tmp"

	if [ -d $PWD/mnt/tmp ]
	then
		rm -rf $PWD/mnt/tmp
	fi

	if [ -d $PWD/tmp ]
	then
		rm -rf $PWD/tmp
	fi

	mkdir $PWD/tmp

	for (( times=1; times <= 1024; times++))
		do
		dd if=/dev/zero of=$PWD/tmp/bytesfile$times bs=1 count=$times 2> /dev/null
		dd if=/dev/zero of=$PWD/tmp/kbytesfile$times bs=1024 count=$times 2> /dev/null
		printf "\r		>>please wait, I am creating bytesfile%d and kbytesfile$times" $times
	done
	printf "\n"
	echo "	>>Write those files into eMMC tmp folder from external source folder tmp"
		cp -rf $PWD/tmp  $PWD/mnt
		sync
	echo "	>>Read those files from eMMC to external disk tmp1 folder"
		cp -rf $PWD/mnt/tmp  $PWD/tmp1
		sync
	echo "	>>Check those files in tmp1 folder md5 with source folder tmp, matching or not"
			for ((times=1; times <= 1024; times++))
				do
				printf "\r	>>check if the MD5 of bytesfile%d matched the bytesfile%d in source folder" $times $times

				md5src=$(md5sum $PWD/tmp/bytesfile$times | awk '{print $1}')
				md5dest=$(md5sum $PWD/tmp1/bytesfile$times | awk '{print $1}')

				if [ $md5src != $md5dest ]
				then
					printf "\n"
					echo "		>>error!!!, MD5 value does not match for bytesfile$times---------"
					exit 1
				fi
			done
					printf "\n"
					echo "		>>MD5 value of bytesfile[1-1024] matching between tmp and tmp1 folder--------"
					echo "		>>>Basically, your eMMC write and read are ok now!! --------"

			for ((times=1; times <= 1024; times++))
				do
				printf "\r	>>check if the MD5 of kbytesfile%d matched the kbytesfile%d in source folder" $times $times

				md5src=$(md5sum $PWD/tmp/kbytesfile$times | awk '{print $1}')
				md5dest=$(md5sum $PWD/tmp1/kbytesfile$times | awk '{print $1}')

				if [ $md5src != $md5dest ]
				then
					printf "\n"
					echo "		>>error!!!, MD5 value does not match for kbytesfile$times---------"
					exit 1
				fi
			done
					printf "\n"
					if [ -d $PWD/mnt/tmp ]
					then
						rm -rf $PWD/mnt/tmp
					fi

					if [ -d $PWD/tmp ]
					then
						rm -rf $PWD/tmp
					fi
					echo "		>>MD5 value of kbytesfile[1-1024] matching between tmp and tmp1 folder--------"
					echo "		>>>Basically, your eMMC write and read are ok now!! --------"

#fi
#if [ $i == 6 ]
#then
	echo "6. Do performance test"
	iozone -a -n 512m -g 2g -i 0 -i 1 -i 2 -f $PWD/mnt/testfile -p -I -r 512k -Rb $PWD/emmc-performance-data.xls
	echo "########################################################"
	echo "#######					    ##########"
	echo "#######Congratulation, all eMMC test passed!!!##########"
	echo "#######					    ##########"
	echo "########################################################"
fi
done
#for loop
done
