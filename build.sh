#!/bin/bash

cleanup() {
    echo "Script interrupted! Exiting safely..."
    exit 1
}

profile=""
build_base_dir="/tmp/archiso_builder"
main_dir=$(pwd)

usage() {
    echo "Usage: $0 [-p <profile>] [-h]"
    echo "  -p <profile>   Enable flag"
    echo "  -h             Show this help message"
    exit 1
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
            cp -r "$main_dir/$profile"/* "$build_base_dir/$profile_name"
        done
    else
        if [ ! -d "$main_dir/profiles/$profile" ]; then
            echo "Error: Profile '$profile' does not exist in profiles directory"
            exit 1
        fi
        echo "Merging single profile: $profile"
        mkdir -p "$build_base_dir/$profile"
        cp -r "$main_dir"/base/* "$build_base_dir/$profile"
        cp -r "$main_dir/profiles/$profile"/* "$build_base_dir/$profile"
    fi
}
build_profiles() {
    echo "Starting profile build..."
    for profile in $build_base_dir/*; do
        echo "Building ISO for profile: $profile"
        profile_name=$(basename "$profile")
        mkdir -p "$main_dir/iso/$profile_name"
        echo "\niso_name=$profile_name" >>"$profile/profiledef.sh"
        sudo sh -c "mkarchiso -v -r -w /tmp/archiso-build-tmp -o '$main_dir/iso/$profile_name' '$profile'"
        echo "Completed building ISO for: $profile"
    done
    echo "All profile builds complete"
}

while getopts ":hp:c" option; do
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
    \?)
        echo "Error: Invalid option"
        usage
        ;;
    esac
done

merge_profiles

build_profiles
