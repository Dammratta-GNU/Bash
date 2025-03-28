#!/bin/bash

# umount luks container
umount_luks_container(){
    read -p "Please enter luks file path to umount (/mnt/CONTAINER_NAME): " l_path
    file_name=$(basename "$l_path")
    if [[ -d /mnt/$file_name ]]
        then
            echo "Umounting dir /mnt/$file_name"
            sudo umount /mnt/$file_name
            echo "Closing container $file_name"
            sudo cryptsetup close $file_name
            echo "Deleting mount point /mnt/$file_name"
            sudo rm -r /mnt/$file_name
        else
            echo "Can't find mounted luks container: /mnt/$file_name"
    fi
}

# Mount luks container
mount_luks_container(){
    read -p "Please enter luks file path: " l_path
    file_name=$(basename "$l_path")
    if [[ -e $l_path ]]
        then
            echo "Opening created container $l_path for mounting"
            sudo cryptsetup open --type luks $l_path $file_name
            # mount section
            if [[ -d /mnt/$file_name ]]
                then
                    echo "Mounting dir mnt/$file_name exists"
                    sudo mount /dev/mapper/$file_name /mnt/$file_name
                else
                    echo "Creating directory /mnt/$file_name"
                    sudo mkdir -p /mnt/$file_name
                    sudo mount /dev/mapper/$file_name /mnt/$file_name
            fi
        else
            echo "Wrong file provided! Select valid one"
            mount_luks_container
        fi
        echo "File $l_path mounted to /mnt/$file_name"

}

# Create new luks file
create_luks_file(){
    dd if=/dev/urandom of="$l_path" bs=1M count=$l_size
    sudo cryptsetup --batch-mode luksFormat $l_path
    file_name=$(basename "$l_path")
    echo "Opening created container $l_path for format in EXT4"
    sudo cryptsetup open --type luks $l_path $file_name
    echo "Formating created container $l_path"
    sudo mkfs.ext4 -L $file_name /dev/mapper/$file_name
    # Mounting for permissions fix
    if [[ -d /mnt/$file_name ]]
        then
            echo "Mounting dir mnt/$file_name exists"
            sudo mount /dev/mapper/$file_name /mnt/$file_name
        else
            echo "Creating directory /mnt/$file_name"
            sudo mkdir -p /mnt/$file_name
            sudo mount /dev/mapper/$file_name /mnt/$file_name
    fi
    # Fix permissions
    sudo chmod 755 /mnt/$file_name
    sudo chmod -R 755 /mnt/$file_name
    sudo chown $USER /mnt/$file_name
    sudo chown -R $USER /mnt/$file_name
    # Unmounting created drive
    sudo umount /mnt/$file_name
    # Closing created container
    echo "Closing container $l_path"
    sudo cryptsetup close $file_name
    # Deleting mounbt folder
    sudo rm -r /mnt/$file_name
    echo "Container $l_path created sucessfully!"
}

# Get luks file size
function get_luks_file_size(){
    read -p "Please enter luks file size in MB, example 512: " l_size
    if [[ -z $l_size ]]
        then 
            echo "Empty value! Enter valid size!"
            get_luks_file_size
    fi
    # Check if input is a valid integer (matches only numbers)
    if [[ $l_size =~ ^-?[0-9]+$ ]]
        then
            create_luks_file
        else
            echo "Entered valuse is not integer! Enter valid size!"
            get_luks_file_size
    fi
    # else
    #     dd if=/dev/urandom of=$l_path bs=1M count=$l_size
    # fi
}

# Check luks file
function check_luks_file(){
    read -p "Please enter luks file path (/home/username/file.bin):  " l_path
    if [[ -e $l_path ]]
        then echo "Luks container $l_path already exists! Enter another name"
        check_luks_file
    else
        echo "Creating luks container"
        get_luks_file_size
    fi
}

# Action select
echo "List of available actions: "
echo "1. create luks container"
echo "2. mount existed container"
echo "3. unmount mounted container"

# Main program menu
function select_work_mode(){
    read -p "Please select action number: " number
    case $number in
        1) 
            echo "Creating encrypted luks container"
            check_luks_file
            ;;
        2) 
            echo "Mounting existed container"
            mount_luks_container
            ;;
        3) 
            echo "Unmounting mounted container"
            umount_luks_container
            ;;
        *) 
            echo "wrong action, choose again!"
            select_work_mode
            ;;
    esac
}

select_work_mode