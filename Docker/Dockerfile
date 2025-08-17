# Use Ubuntu as the base image (Vivado works well with Ubuntu)
FROM ubuntu:20.04

# Set environment variables (adjust the version accordingly)
ENV VIVADO_VERSION=2023.1
ENV VIVADO_INSTALLER_PATH=/vivado-installer
ENV VIVADO_INSTALL_DIR=/opt/Xilinx
ENV XINSTALLER_SCALE=2
ENV TZ=Etc/UTC
ENV PATH="$PATH:~/.local/bin"
ENV PATH="$PATH:~/.local/lib/python3.8/site-packages"
ENV LANG=en_US.UTF-8 
ENV LANGUAGE=en_US:en 
ENV LC_ALL=en_US.UTF-8

# Install required dependencies for Vivado
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    libncurses5 \
    libstdc++6 \
    python3 \
    python3-pip \
    libreadline-dev \
    && rm -rf /var/lib/apt/lists/*

#Install required dependencies for LiteX
RUN apt-get update && apt-get install -y git && apt-get install -y usbutils

# Set the timezone to UTC or any other timezone
RUN ln -snf /usr/share/zoneinfo/UTC /etc/localtime && echo "UTC" > /etc/timezone
RUN apt-get update && apt-get install -y expect
RUN apt-get update && apt-get install -y locales \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8

# Install LiteX
RUN wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
RUN chmod +x litex_setup.py
RUN ./litex_setup.py --init --tag=2024.04 --install --user --config=minimal

#Clone repository
RUN git clone https://github.com/GustavsC/FPGA-SPDM
COPY compile_soc.sh compile_soc.sh
RUN chmod +x compile_soc.sh
    
# Create directories for installer and Vivado installation
RUN mkdir -p ${VIVADO_INSTALLER_PATH} ${VIVADO_INSTALL_DIR}

# Copy the Vivado installer binary into the container (adjust this path accordingly)
COPY Xilinx_Unified_*.bin ${VIVADO_INSTALLER_PATH}/Vivado_${VIVADO_VERSION}.bin
COPY config_vivado ${VIVADO_INSTALLER_PATH}/install.txt
COPY password.sh /vivado-installer/password.sh

# Create credetials
RUN chmod +x /vivado-installer/password.sh

# Make the installer executable
RUN chmod +x ${VIVADO_INSTALLER_PATH}/Vivado_${VIVADO_VERSION}.bin && \
    ls -l ${VIVADO_INSTALLER_PATH}/Vivado_${VIVADO_VERSION}.bin

# Run the Vivado installer in batch mode
RUN ${VIVADO_INSTALLER_PATH}/Vivado_${VIVADO_VERSION}.bin --target ${VIVADO_INSTALLER_PATH}/extracted && \
    ls -l ${VIVADO_INSTALLER_PATH}/extracted

# Run the Vivado installer in batch mode by invoking the internal script
RUN /vivado-installer/password.sh
RUN ${VIVADO_INSTALLER_PATH}/extracted/xsetup --batch Install --agree 3rdPartyEULA,XilinxEULA --product Vivado -c /vivado-installer/install.txt --location ${VIVADO_INSTALL_DIR}

# Expose Vivado installation directory
ENV PATH="${VIVADO_INSTALL_DIR}/bin:${PATH}"

# Set the entrypoint (you can adjust this if you want to execute Vivado commands inside the container)
EXPOSE 80

CMD ["tail", "-f", "/dev/null"]

