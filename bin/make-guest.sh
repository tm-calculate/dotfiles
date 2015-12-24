#!/bin/bash
virt-install --name=${1} --arch=x86_64 --vcpus=1 --ram=1024 --os-type=linux --os-variant=rhel7 --hvm --connect=qemu:///system --network bridge:virbr0,model=virtio --cdrom=${2} --disk path=/var/calculate/libvirt/images/${1}.qcow2,size=10,bus=virtio --virt-type=kvm --graphics=spice --noautoconsole