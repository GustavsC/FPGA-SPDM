# FPGA-SPDM
================================================
Researchers: LARC-SEMBEI-Escola Politécnica da USP

Este repositório contém um projeto de implementação do Security Protocol and Data Model (SPDM) em hardware. Este hardware foi criado para executar a BIOS como um Requester e uma placa de rede Ethernet como Responder dentro da FPGA. A comunicação do SPDM é feita em 3 fases: GET_VERSION, GET_CAPABILITIES, and NEGOTIATE_ALGORITHMS [1].

![image](https://github.com/user-attachments/assets/7fce130a-83e8-48ad-9fb9-9174fd753399)

O projeto é executado na NetFPGA-SUME [2].

Vivado 2023.1 com uma licença Virtex-7 é necessária para compilação e uso da FPGA. Mais informações da instalação da ferramenta podem ser encontradas nas referências. [3]
Para compilação, a máquina host precisa de ao menos 16GB de RAM. Todo o experimento foi realizado em um Ubuntu 20.04.6 LTS com a biblioteca python3 instalada.

Existem dois métodos de reprodutibilidade neste repositório: Compilação via TCL e Método de compilação. A diferença entre esses dois métodos é que no primeiro a BIOS, firmware, kernel, bootloader e o sistema de arquivos (initramfs.cpio) foram previamente compilados, enquanto no segundo, os mesmos são compilados a partir do código fonte disponível em repositórios. Em ambos o hardware precisa ser compilado.


# Pré Requisito
A biblioteca LiteX é uma biblioteca de código aberto para criação e/ou utilização de SoCs. Esta é considerada pré-requisito devido a sua ferramenta de leitura de seriais. [4] 
Para instalar essa biblioteca siga as instruções:

```
$ mkdir LiteX
$ cd LiteX
$ wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
$ chmod +x litex_setup.py
$ ./litex_setup.py --init --tag=2024.04 --install --user --config=full
```

# Compilação via TCL
No método utilizando o TCL Script, o script cria o hardware dentro do Vivado através do código fonte Verilog. O software já está pré compilado e é incorporado dentro do binário durante a compilação.

Para replicar o experimento, siga as intruções:

1. Abra o terminal de comando Vivado Tcl Shell.
2. cd no diretório SoC/SoC_with_spdm.
3. Execute ***source digilent_netfpga_sume.tcl -notrace*** para gerar o binário.

A compilação do projeto pode levar algum tempo (~1 hora usando 4 cores).

## Kernel
Em SoC/SoC_with_spdm/kernel os binários do Kernel, bootloader e initramfs.cpio estão disponíveis junto ao boot.json. 

Para iniciar o Kernel Linux basta ir em LiteX/litex/litex/tools e executar em um terminal o comando. 

```
python3 litex_term.py /dev/ttyUSB1 --images=PATH/TO/SoC/SoC_with_spdm/kernel/boot.json
```

Tenha atenção de que /dev/ttyUSB1 é um endereço de USB, este endereço varia a depender de quantas USBs estão sendo utilizadas. Se precisar saber qual utilizar: 

```
ls /dev/ttyUSB*
lsusb
```

## Nota:
Uma versão sem SPDM do SoC também está disponível para possível comparação. Para compilar esta versão siga as instruções:

1. Abra o terminal de comando Vivado Tcl Shell.
2. cd no diretório SoC/SoC_no_spdm.
3. Execute ***source digilent_netfpga_sume.tcl -notrace*** para gerar o binário.

O kernel também pode ser executado nesta versão. Basta seguir os passos descritos anteriormente em "Compilação via TCL"

# Método de Compilação
Todas as bibliotecas utilizadas junto ao compilador estão detalhadas nessa seção. Todo código fonte pode ser encontrado no diretório "SourceCode" deste repositório.

## 1. Compilador RISC-V GNU 

Toda compilação vai ser realizada com este compilador: 

```
$ sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip python3-tomli libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev libslirp-dev
$ mkdir riscv
$ cd riscv
$ git clone https://github.com/riscv/riscv-gnu-toolchain
$ git checkout tags/2023.06.09
```

Duas bibliotecas são utilizadas, Newlib and Linux. O compilador vai ser criado duas vezes:

Para a biblioteca Newlib:
```
$ ./configure --prefix=/opt/riscv --enable-multilib
$ make
```

Para a biblioteca Linux:
```
$ ./configure --prefix=/opt/riscv --enable-multilib
$ make linux
```

## 2. System on Chip - BIOS 

### 2.1 LibSPDM 

Biblioteca LibSPDM do repositório oficial.

```
$ git clone https://github.com/DMTF/libspdm.git
$ cd libspdm
$ git switch release-2.3
$ git submodule update --init --recursive
```

Antes de compilar a LibSPDM, estes arquivos precisam ser modificados: config.h, crt_wrapper_host.c and CMakeLists.txt. Altere os arquivos correspondentes com os deste repositório; Os diretórios neste repositório possuem o mesmo nome daqueles da LibSPDM/LiteX

Uma vez feito, siga as instruções abaixo no diretório da LibSPDM:

```
$ mkdir build
$ cd build
$ export PATH=$PATH:/opt/riscv/bin
$ cmake -DARCH=riscv64 -DTOOLCHAIN=RISCV_GNU -DTARGET=Release -DCRYPTO=mbedtls
$ make copy_sample_key
$ make
```

### 2.2 LibSPDM in BIOS
Antes de compilar a LibSPDM para a Litex, deve ser executado o Makefile "litex_libspdm.mk". Este Makefile vai adicionar os arquivos da LibSPDM dentro do diretório de software da LiteX para que a mesma encontro os arquivos corretamente.
Preste atenção para os diretórios corretos quando compilar. 

```
$ make -f libspdm_litex.mk
```

Substitua/Adicione os seguintes arquivos no diretório BIOS da LiteX: boot.c, bswapsi2.c, int_endianness.h, int_lib.h, int_types.h, int_util.h, linker.ld, spdmfuncs.c, spdmfuncs.h, cmd_bios.c e Makefile. Estes arquivos estão disponivéis neste repositório em SourceCode.

Substitua common.mak em "LiteX/litex/litex/soc/software".

A estrutura de diretórios com os arquivos adicionados e substituídos ficará da seguinte maneira:

```
/LiteX/litex/litex/soc/software/common.mak
/LiteX/litex/litex/soc/software/bios/boot.c
/LiteX/litex/litex/soc/software/bios/bswapsi2.c
/LiteX/litex/litex/soc/software/bios/int_endianness.h
/LiteX/litex/litex/soc/software/bios/int_lib.h
/LiteX/litex/litex/soc/software/bios/int_types.h
/LiteX/litex/litex/soc/software/bios/int_util.h
/LiteX/litex/litex/soc/software/bios/linker.ld
/LiteX/litex/litex/soc/software/bios/spdmfuncs.c
/LiteX/litex/litex/soc/software/bios/spdmfuncs.h 
/LiteX/litex/litex/soc/software/bios/Makefile
/LiteX/litex/litex/soc/software/bios/cmds/cmd_bios.c
```

***Tenha atenção quando editar os diretórios corretos antes de compilar, especialmente em Makefiles (libspdm_litex.mk, Makefile, common.mak).***

### 2.3 LibSPDM in Ethernet Card

Estes arquivos são para criar uma placa de rede Ethernet com registradores SPDM na FPGA.
Substuia/adicione os seguintes arquivos em seus respectivos diretórios:

```
/LiteX/liteeth/liteeth/phy/v7_1000basex.py
/LiteX/liteiclink/liteiclink/serdes/gth_7series.py
/LiteX/liteiclink/liteiclink/serdes/gth_7series_init.py
/LiteX/litex-boards/litex-boards/platforms/digilent_netfpga_sume.py
/LiteX/litex-boards/litex-boards/targets/digilent_netfpga_sume.py
```

Depois destas mudanças, volte ao diretório principal da LiteX e siga as seguintes instruções:

```
$ export PATH=$PATH:/opt/riscv/bin
$ source /tools/Xilinx/Vivado/2023.1/settings64.sh
$ litex-boards/litex_boards/targets/digilent_netfpga_sume.py --build --cpu-type rocket --cpu-variant linux --cpu-mem-width 8 --with-ethernet --bus-standard axi --no-compile-gateware
```

A BIOS compilada a partir do código fonte estará em:

```
/LiteX/build/digilent_netfpga_sume/software/bios/bios.elf
```

Com a bios.elf, basta substituir a BIOS em SoC/SoC_with_SPDM/software/bios e sigar as mesmas instruções do Método TCL.

# System on Chip - Software [3]

## Kernel Image e rootfs.cpio

Para recriar o kernel, bootloader e sistema de arquivos.

Primeiro, configure e obtenha o busybox. Compile para RISC-V:

```
curl https://busybox.net/downloads/busybox-1.33.2.tar.bz2 | tar xfj -
cp PATH/TO/FPGA-SPDM/Kernel/busybox-1.33.2/.config busybox-1.33.2/.config
(cd busybox-1.33.2; make CROSS_COMPILE=PATH/TO/riscv64-unknown-linux-gnu-)
mkdir linux
```

Com o busybox compilado, construa o initramfs.cpio. Dentro do repositório do busybox-1.33.2: 

```
mkdir initramfs
pushd initramfs
mkdir -p bin sbin lib etc dev home proc sys tmp mnt nfs root \
          usr/bin usr/sbin usr/lib
cp ../busybox-1.33.2/busybox bin/
ln -s bin/busybox ./init
cat > etc/inittab <<- "EOT"
::sysinit:/bin/busybox mount -t proc proc /proc
::sysinit:/bin/busybox mount -t devtmpfs devtmpfs /dev
::sysinit:/bin/busybox mount -t tmpfs tmpfs /tmp
::sysinit:/bin/busybox mount -t sysfs sysfs /sys
::sysinit:/bin/busybox --install -s
/dev/console::sysinit:-/bin/ash
EOT
fakeroot <<- "EOT"
find . | cpio -H newc -o > ../initramfs.cpio
EOT
popd
```


Para construção da imagem do Kernel Image e do initramfs.cpio iremos utilizar o buildroot:

```
$ mkdir buildroot_riscv64
$ cd buildroot_riscv64
$ wget https://git.busybox.net/buildroot/snapshot/buildroot-2023.05.1.tar.bz2
$ tar -xjf buildroot-2023.05.1.tar.bz2 
$ cd buildroot-2023.05.1 
```

Use as configurações .config deste repositório. Coloque estes arquivos nos diretórios corretos.

No arquivo buildroot-2023.05.01/.config, substitua as pelo correto PATH nas seguintes configurações:

```
BR2_DEFCONFIG="PATH/TO/buildroot_riscv64/buildroot-2023.05.1/configs/qemu_riscv64_virt_defconfig"
BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="PATH/TO/busybox-1.33.2/linux/.config"
BR2_PACKAGE_BUSYBOX_CONFIG="PATH/TO/busybox-1.33.2/.config"
BR2_LINUX_KERNEL_CUSTOM_DTS_PATH="PATH/TO/netfpgasume.dts"
```

No arquivo do busybox-1.33.2/linux/.config, configure o PATH para o correto initramfs.cpio 

```
CONFIG_INITRAMFS_SOURCE="PATH/TO/busybox-1.33.2/initramfs.cpio"
```

```
$ make
```

A Imagem do Kernel está em: /output/images/Image
O binário do rootfs.cpio está em: /output/images/rootfs.cpio

## Bootloader - OpenSBI [4]

Antes de compilar o bootloader, será necessário criar o Device Tree Blob (DTB). Utilize o DeviceTree fornecido neste repositório e siga as instruções:

```
$ cd Kernel/DeviceTree
$ dtc -O dtb -o netfpgasume.dtb netfpgasume.dts
```

Utilizando o OpenSBI 0.8

```
$ git clone https://github.com/litex-hub/opensbi
$ cd opensbi
$ git checkout 84c6dc17f7d41c5c02760a5533d7268b57369837
$ export PATH=$PATH:/opt/riscv/bin
$ make CROSS_COMPILE=riscv64-unknown-linux-gnu- PLATFORM=generic \
    FW_FDT_PATH=PATH/TO/netfpgasume.dtb FW_JUMP_FDT_ADDR=0x82400000
```
O binário do OpenSBI está em /opensbi/build/platform/generic/firmware/fw_jump.bin

## Execução

Crie um arquivo boot.json com a configuração de memória:

```
{
	"rootfs.cpio": "0x82000000",
	"Image":       "0x80200000",
	"fw_jump.bin": "0x80000000"
}
```

Com os binários (Image, rootfs.cpio, fw_jump.bin and boot.json) no mesmo diretório execute o comando no terminal:

```
litex_term /dev/ttyUSB1 --images=PATH/TO/boot.json
```

Execute the digilent_netfpga_sume.bit na FPGA a partir do Vivado.

# References
[1] https://www.dmtf.org/sites/default/files/standards/documents/DSP0274_1.2.1.pdf
[2] https://digilent.com/reference/programmable-logic/netfpga-sume/start?srsltid=AfmBOorSQYE7kGKgUYJlLcDCyw6vfYHvrAbTzTf5HQJcgC4-E-jnjQHG
[3] https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html
[4] https://github.com/enjoy-digital/litex

