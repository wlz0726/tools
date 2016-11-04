#! /bin/bash 
echo "please enter scan path"
read path

if [ -z $path ]
then
    echo "please enter scan path"
    exit
fi

for file in $(find $path -type l)
do
    if [ ! -e $file ]
    then
        echo "rm $file"
        rm -f $file
    fi
done