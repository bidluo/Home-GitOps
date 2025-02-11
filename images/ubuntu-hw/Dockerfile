FROM quay.io/kairos/ubuntu:22.04-standard-amd64-generic-v3.3.1-k3sv1.32.1-k3s1

ARG TAG

RUN apt-get update && \
    apt-get install -y \
    initramfs-tools \
    zstd \
    linux-firmware && \ 
    apt-get clean && \ 
    rm -rf /var/lib/apt/lists/* && \
    echo "CUSTOM_TAG=${TAG}" >> /etc/os-release

RUN zstd -d -r /lib/firmware/i915/*.zst.zst

# Update kernel modules and initramfs
RUN kernel=$(ls /lib/modules | head -n1) && \
    update-initramfs -c -k "${kernel}"
