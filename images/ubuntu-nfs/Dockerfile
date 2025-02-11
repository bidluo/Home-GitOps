FROM quay.io/kairos/ubuntu:24.04-standard-amd64-generic-v3.3.1-k3sv1.32.1-k3s1

ARG TAG

RUN apt-get update && \
    apt-get install -y \
    initramfs-tools \
    zstd \
    nfs-kernel-server \
    linux-firmware && \ 
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/* && \
    echo "CUSTOM_TAG=${TAG}" >> /etc/os-release

# Update kernel modules and initramfs
RUN kernel=$(ls /lib/modules | head -n1) && \
    update-initramfs -c -k "${kernel}"
