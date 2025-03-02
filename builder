#!/bin/bash

cleanup() {
    echo "Script interrupted! Exiting safely..."
    exit 1
}

profile=""
build_base_dir="/tmp/archiso_builder"
iso_name="archlinux"
main_dir=$(pwd)

usage() {
    echo "Usage: $0 [-p <profile>] [-c] [-i] [-n <iso_name>] [-h]"
    echo "  -p <profile>   Specify profile to build (use 'all' for all profiles)"
    echo "  -c            Clean build directory"
    echo "  -i            Build ISO only"
    echo "  -n <iso_name> Set custom ISO name"
    echo "  -h            Show this help message"
    exit 1
}

check_sudo() {
    if ! sudo -v; then
        echo "Error: This script requires sudo privileges."
        exit 1
    fi
}

merge_profiles() {
    echo "Starting profile merge..."
    if [ "$profile" == "" ]; then
        echo "No profile specified, using base only"
        mkdir -p "$build_base_dir/base"
        cp -r "$main_dir"/base/* "$build_base_dir/base"
    elif [ "$profile" == "all" ]; then
        echo "Building all profiles"
        for profile in profiles/*; do
            profile_name=$(basename "$profile")
            echo "Merging profile: $profile_name"
            mkdir -p "$build_base_dir/$profile_name"
            cp -r "$main_dir"/base/* "$build_base_dir/$profile_name"
            if ! cp -r "$main_dir/$profile"/* "$build_base_dir/$profile_name"; then
                echo "Error: Failed to copy profile $profile_name"
                exit 1
            fi
        done
    else
        if [ ! -d "$main_dir/profiles/$profile" ]; then
            echo "Error: Profile '$profile' does not exist in profiles directory"
            exit 1
        fi
        echo "Merging single profile: $profile"
        mkdir -p "$build_base_dir/$profile"
        cp -r "$main_dir"/base/* "$build_base_dir/$profile"
        if ! cp -r "$main_dir/profiles/$profile"/* "$build_base_dir/$profile"; then
            echo "Error: Failed to copy profile $profile"
            exit 1
        fi
    fi
}

build_profiles() {
    echo "Starting profile build..."
    for profile in $build_base_dir/*; do
        echo "Building ISO for profile: $profile"
        profile_name=$(basename "$profile")
        mkdir -p "$main_dir/iso/$profile_name"
        echo "iso_name=$iso_name-$profile_name" >>"$profile/profiledef.sh"
        if ! sudo sh -c "mkarchiso -v -r -w /tmp/archiso-build-tmp -o '$main_dir/iso/$profile_name' '$profile'"; then
            echo "Error: Failed to build ISO for profile $profile"
            exit 1
        fi
        echo "Completed building ISO for: $profile"
    done
    echo "All profile builds complete"
}

# Check sudo rights
check_sudo

# Check if more than one option is used with c or i
if [ "$*" == "-c" ] || [ "$*" == "-i" ]; then
    : # Valid single option usage
elif [[ "$*" == *"-c"* ]] || [[ "$*" == *"-i"* ]]; then
    echo "Error: -c and -i options must be used alone"
    usage
fi

while getopts ":hp:cn:" option; do
    case $option in
    h)
        usage
        ;;
    p)
        profile=$OPTARG
        echo "Selected profile: $profile"
        ;;
    c)
        echo "Cleaning build directory $build_base_dir"
        rm -rf "$build_base_dir"
        echo "Cleaning /tmp/archiso-build-tmp"
        sudo rm -rf "/tmp/archiso-build-tmp"
        exit 1
        ;;
    i)
        echo "Cleaning iso directory"
        rm -rf "$main_dir/iso"
        exit 1
        ;;
    n)
        echo "Iso name is $OPTARG"
        iso_name=$OPTARG
        ;;
    \?)
        echo "Error: Invalid option"
        usage
        ;;
    esac
done

merge_profiles

build_profiles

