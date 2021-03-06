#!/bin/bash

########################################################################
#	- This is the main script that is used to compile/interpret the source code
#	- The script takes 3 arguments
#		1. The compiler that is to compile the source file.
#		2. The source file that is to be compiled/interpreted
#		3. Additional argument only needed for compilers, to execute the object code
#	
#	- Sample execution command:   $: ./script.sh g++ file.cpp ./a.out
#	
########################################################################

compiler=$1
file=$2
runner=$3
addtionalArg=$4


########################################################################
#	- The script works as follows
#	- It first stores the stdout and std err to another stream
#	- The output of the stream is then sent to respective files
#	
#	
#	- if third arguemtn is empty Branch 1 is followed. An interpretor was called
#	- else Branch2 is followed, a compiler was invoked
#	- In Branch2. We first check if the compile operation was a success (code returned 0)
#	
#	- If the return code from compile is 0 follow Branch2a and call the output command
#	- Else follow Branch2b and output error Message
#	
#	- Stderr and Stdout are restored
#	- Once the logfile is completely written, it is renamed to "completed"
#	- The purpose of creating the "completed" file is because NodeJs searches for this file 
#	- Upon finding this file, the NodeJS Api returns its content to the browser and deletes the folder
#
#	
########################################################################

# redirect stdout --> logfile.txt & stderr --> errors
exec  1> $"/usercode/logfile.txt"
exec  2> $"/usercode/errors"


START=$(date +%s.%2N)
NL=$'\n'
FIRST_LINE="TRUE"
# the separator values below are also maintained in glob.go in project root dir...
IN_SEP="*-BRK-*"
OUT_SEP="*-BRK-*"

# Branch 1: we are calling an interpreter (no compilation step)
if [ "$runner" = "" ]; then
        # Reads until reaching $SEP and then runs command with that block of input
	while read p; do
		if [ "$p" = "$IN_SEP" ]; then
			
			# run program with input
			OUTPUT="$(echo -n "$INPUT" | $compiler /usercode/$file)"

			if [ ${#OUTPUT} = 0 ]; then 
				# if no input is produced, make a newline (makes later parsing possible)
				echo
			else
				# otherwise just echo the output
				echo "$OUTPUT"
			fi

			echo "$OUT_SEP"
			INPUT=""
			FIRST_LINE="TRUE"
		else
			if [ "$FIRST_LINE" = "FALSE" ];then
				INPUT="$INPUT$NL"
				# echo "Adding \n"
			fi
			INPUT="$INPUT$p"
			FIRST_LINE="FALSE"
		fi
	done < $"/usercode/inputFile"

#Branch 2
else  # runner was not blank
	#In case of compile errors, redirect them to a file
        $compiler /usercode/$file $addtionalArg > /dev/null #&> /usercode/errors.txt

	#Branch 2a : exit code is zero aka success
	if [ $? -eq 0 ];	then
			while read p; do
				if [ "$p" = "$IN_SEP" ]; then
					
					# run program with input
					OUTPUT="$(echo -n "$INPUT" | $runner)"

					if [ ${#OUTPUT} = 0 ]; then 
						# if no input is produced, make a newline (makes later parsing possible)
						echo
					else
						# otherwise just echo the output
						echo "$OUTPUT"
					fi

					echo "$OUT_SEP"
					INPUT=""
					FIRST_LINE="TRUE"
				else
					if [ "$FIRST_LINE" = "FALSE" ];then
						INPUT="$INPUT$NL"
						# echo "Adding \n"
					fi
					INPUT="$INPUT$p"
					FIRST_LINE="FALSE"
				fi
			done < $"/usercode/inputFile"

	#Branch 2b : exit code is not zero
	else
	    echo "Compilation Failed:"
	    #if compilation fails, display the output file	
	    cat /usercode/errors
	fi
fi

#exec 1>&3 2>&4

#head -100 /usercode/logfile.txt
#touch /usercode/completed
END=$(date +%s.%2N)
runtime=$(echo "$END - $START" | bc)


echo "*-COMPILEBOX::ENDOFOUTPUT-*" $runtime 


mv /usercode/logfile.txt /usercode/completed

