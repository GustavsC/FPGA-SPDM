# Proteção em hardware com Security Protocol and Data Model

Uma ameaça crítica à segurança de sistemas computacionais modernos envolve ataques em nível de hardware, como a manipulação de firmware. Esses ataques são particularmente perigosos porque permitem acesso não autorizado a dados no nível do barramento, dificultando a detecção de *eavesdropping* ou adulteração de dados. Uma possível contramedida é o *Security Protocol and Data Model* (SPDM), um padrão da indústria para atestação mútua de componentes de hardware e estabelecimento seguro de canais.
   Neste trabalho, apresentamos o projeto, a implementação e a execução do SPDM em um FPGA (*Field-Programmable Gate Array*). Nosso ambiente de teste consiste em um SoC RISC-V e uma placa Ethernet, onde o código de inicialização (BIOS) autentica o periférico (placa Ethernet) usando o SPDM.

Este repositório contém um projeto de implementação do *Security Protocol and Data Model* (SPDM) em hardware. Este hardware foi criado para executar a BIOS como um Requester e uma placa de rede Ethernet como Responder dentro da FPGA. A comunicação do SPDM é feita em 3 fases: **GET_VERSION**, **GET_CAPABILITIES**, and **NEGOTIATE_ALGORITHMS** [1].

![image](https://github.com/user-attachments/assets/7fce130a-83e8-48ad-9fb9-9174fd753399)

Existem dois métodos de reprodutibilidade neste repositório: [Compilação via TCL](#compilação-via-tcl) e [Método de compilação](#método-de-compilação). A diferença entre esses dois métodos é que no primeiro a BIOS, firmware, kernel, bootloader e o sistema de arquivos (initramfs.cpio) foram previamente compilados, enquanto no segundo, os mesmos são compilados a partir do código fonte disponível em repositórios. Em ambos o hardware precisa ser compilado. O artigo apresentado utilizará como reprodutibilidade o *Compilação via TCL*.

# Estrutura do readme.md
  
- [Selos Considerados](#selos-considerados)  
- [Informações básicas](#informações-básicas)  
- [Dependências](#dependências)

- [Preocupações com segurança](#preocupações-com-segurança)
- [Instalação](#instalação)
    - [Pré-requisito](#pré-requisito)
    - [Compilação via TCL](#compilação-via-tcl)
- [Teste Mínimo](#teste-mínimo)
- [Experimentos](#experimentos)
- [Método de compilação](#método-de-compilação)
    - [1. Compilador RISC-V GNU](#1-compilador-risc-v-gnu)
    - [2. System on Chip - SPDM](#2-system-on-chip---spdm)
       - [2.1 LibSPDM](#21-libspdm)
       - [2.2 LibSPDM na BIOS](#22-libspdm-na-bios)
       - [2.3 LibSPDM na Ethernet](#23-libspdm-na-ethernet)
          - [Firmware da placa de rede Ethernet](#firmware-da-placa-de-rede-ethernet)
- [System on Chip - Software](#system-on-chip---software)
   - [Kernel Image e rootfs.cpio](#kernel-image-e-rootfscpio)
   - [Bootloader - OpenSBI](#bootloader---opensbi)
   - [Execução](#execução)
- [Anexos](#anexos)
  - [Tabela 1 - Arquivos de BIOS](#tabela-1---arquivos-de-bios)
  - [Tabela 2 - Arquivos de hardware LiteX](#tabela-2---arquivos-de-hardware-litex)
- [LICENSE](#license)
- [Referências](#referências)

# Selos Considerados

Os selos solicitados pelos autores para avaliação deste trabalho são: Disponíveis (SeloD), Funcionais (SeloF), Sustentáveis (SeloS) e Reprodutíveis (SeloR).

# Informações básicas

Para execução do projeto é necessário um FPGA NetFPGA-SUME [2]. 

Para reprodução (compilação) do experimento é estritamente necessário uma máquina host com ao menos 16GB de RAM e 4 núcleos de processamento. Igualmente, recomenda-se a utilização de um sistema operacional Ubuntu 20.04.6 LTS. Em relação aos softwares, será necessário as bibliotecas python3 e LiteX. Outro software necessário é o Vivado 2023.1 com uma licença Virtex-7, utilizado para compilação e programação da FPGA [3]. As instruções de instalação do Vivado 2023.1 pode ser encontrada em: https://docs.amd.com/r/2023.1-English/ug910-vivado-getting-started/Installing-the-Vivado-Design-Suite.

OBS: A Licença Virtex-7 é uma licença paga, porém, a empresa responsável fornece uma licença gratuita de 30 dias que pode também ser utilizada para reprodução deste trabalho. O modo de instalação é: Dentro do ambiente Vivado, vá em *Help* -> *Obtain a License Key* -> *Start Now! 30 Day Trial* -> *Process Now*. Pronto, a licença está funcional por 30 dias.

# Dependências

A versão utilizada na biblioteca LiteX é a versão 2024.04. A versão do Python3 recomendada é a 3.8.10, porém, versões superiores podem ser utilizadas.

# Preocupações com segurança

O risco de segurança ocorre em choques elétricos e superfícies cortantes no manuseio da FPGA NetFPGA-SUME. A placa é alimentada através de uma fonte padrão ATX (*ATX Power Supply*) com um conector do tipo *2×4 pin PCI Express Auxiliary Power Connector*. O recomendado é não manusear a placa com a fonte ligada.
Ao ligar a placa, deve-se ter o cuidado com contatos na ventoinha, já que esta fica exposta e apresenta risco de corte.

# Instalação

Na etapa de instalação está descrito o processo de instalação da LiteX e da compilação do artefato. Esta seção se divide em duas partes: [Pré-requisito](#pré-requisito) e [Compilação via TCL](#compilação-via-tcl).

## Pré-requisito
A biblioteca LiteX é uma biblioteca de código aberto para criação e/ou utilização de SoCs. Esta é considerada pré-requisito devido a ser uma ferramenta de leitura de seriais. [4] 

Para instalação desta biblioteca siga as instruções:

```
$ mkdir LiteX
$ cd LiteX
$ wget https://raw.githubusercontent.com/enjoy-digital/litex/master/litex_setup.py
$ chmod +x litex_setup.py
$ ./litex_setup.py --init --tag=2024.04 --install --user --config=full
```
## Compilação via TCL
No método utilizando o TCL Script, o script cria o hardware dentro do Vivado através do código fonte Verilog. O software já está pré compilado e é incorporado dentro do binário durante a compilação.

Para replicar o experimento, siga as intruções:

1. Abra o terminal de comando Vivado Tcl Shell [5].
2. cd SoC/SoC_with_spdm.
3. Execute ***source digilent_netfpga_sume.tcl -notrace*** para gerar o binário.

A compilação do projeto pode levar algum tempo (~1 hora usando 4 cores).

# Teste Mínimo

Como teste mínimo, iremos utilizar o SoC dentro de sua BIOS. Para realizar isto, primeiramente conecte a FPGA via USB na máquina host. Após conectada veja o local alocado pelo Ubuntu no qual está localizada a placa. Usualmente, ela fica em **/dev/ttyUSB1**, porém, isto não é uma regra. Para visualizar o local corretamente utilize os comandos no terminal.

```
ls /dev/ttyUSB*
lsusb
```

Para iniciar a leitura de seriais da FPGA basta ir no diretório **LiteX/litex/litex/tools** via terminal e executar em um terminal o comando.

```
python3 litex_term.py /dev/ttyUSB1 
```

Com a USB conectada e a leitura de seriais preparada, vá no ambiente Vivado 2023.1 e siga: *Program and Debug* -> *Open Hardware Manager* -> *Open Target* -> *Auto Connect*. Espere a conexão com a FPGA e depois siga: *xc7vx690t_0* -> *Program Device*, selecione o arquivo **digilent_netfpga_sume.bit** e então clique em *Program*. Espere o SoC inicializar.

Depois de inicializado (no qual o SoC é liberado para receber comandos via teclado padrão da máquina host), digite no console **spdm_requester**. Se ocorrer de aparecer uma variável com o nome **libspdm_init_connection = 0x0** o teste mínimo foi bem sucedido. O teste mínimo deve ocorrer como na Imagem abaixo:


![Screenshot from 2025-03-27 10-35-41(1)](https://github.com/user-attachments/assets/faf0cb2d-c1ff-40fc-8bc8-9b6a03d859aa)

# Experimentos

Iremos reproduzir dois experimentos.

## Reivindicações #Inicialização correta do Kernel com autenticação SPDM na Ethernet

Em SoC/SoC_with_spdm/kernel os binários do Kernel, bootloader e initramfs.cpio estão disponíveis junto ao boot.json. 

Para iniciar o Kernel Linux basta ir em LiteX/litex/litex/tools e executar em um terminal o comando. 

```
python3 litex_term.py /dev/ttyUSB1 --images=PATH/TO/SoC/SoC_with_spdm/kernel/boot.json
```

O SPDM irá ser executado e após *upload* dos arquivos na memória RAM (Cerca de 40 minutos com 1GB de RAM utilizada), o kernel será executado. A imagem abaixo demonstra o que deve ocorrer:

![Screenshot from 2025-05-12 21-48-23](https://github.com/user-attachments/assets/9b1ed1fc-50fd-4583-b554-b0b9a4ccb6f1)

## Reivindicações #Execução do Kernel interrompida devido a ataque no firmware da Ethernet

O segundo teste aplicado se refere a demonstração da reação do SPDM diante de uma adulteração de firmware. Neste caso o atacante tentou alterar os algoritmos de Hash estáveis por um com vulnerabilidade. 

No diretório SoC/SoC_with_spdm/software/firmware há dois firmwares da Ethernet disponíveis sendo um deles o *spdm_requester_adulterado.elf*. Renomeie este firmware para *spdm_requester.elf* (cuidado com dois nomes iguais, o firmware que será compilado no SoC **sempre** estará como *spdm_requester.elf*) e recompile no ambiente Vivado através de *Run Synthesis* -> *Run Implementation* -> *Generate Bitstream*. Após compilado (cerca de 40min, a depender da máquina host) o binário *digilent_netfpga_sume.bit* pode ser programado na FPGA do mesmo modo como descrito em [Teste Mínimo](#teste-mínimo).

O resultado esperado será como o da Imagem abaixo:

![Screenshot from 2025-07-08 16-15-10(3)](https://github.com/user-attachments/assets/f8de5a57-b5bd-40af-aca4-3c472f67bb96)


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

## 2. System on Chip - SPDM 

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

### 2.2 LibSPDM na BIOS
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

As funções destes arquivos estão descritas na Tabela 1 da seção de [Anexos](#anexos)

***Tenha atenção quando editar os diretórios corretos antes de compilar, especialmente em Makefiles (libspdm_litex.mk, Makefile, common.mak).***

### 2.3 LibSPDM na Ethernet 

Estes arquivos são para criar uma placa de rede Ethernet com registradores SPDM na FPGA.
Substuia/adicione os seguintes arquivos em seus respectivos diretórios:

```
/LiteX/liteeth/liteeth/phy/v7_1000basex.py
/LiteX/liteiclink/liteiclink/serdes/gth_7series.py
/LiteX/liteiclink/liteiclink/serdes/gth_7series_init.py
/LiteX/litex-boards/litex-boards/platforms/digilent_netfpga_sume.py
/LiteX/litex-boards/litex-boards/targets/digilent_netfpga_sume.py
```

As funções destes arquivos estão descritas na Tabela 2 da seção de [Anexos](#anexos)

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


#### Firmware da placa de rede Ethernet

Para compilação do firmware que será executado no processador Microblaze, o software Vitis 2023.1 é requisito.[6]

O projeto está em formato .zip em SourceCode/Microblaze. Basta entrar no Vitis 2023.1 e ir em "Import Project". Após a importação, compile o projeto como "Debug"; O resultado estará no diretório de mesmo nome como "spdm_requester.elf".

Com a bios.elf e spdm_requester.elf compiladas, basta substituir a BIOS em SoC/SoC_with_SPDM/software/bios e o firmware em SoC/SoC_with_SPDM/software/firmware. Após isto siga as mesmas instruções da seção [Compilação via TCL](#compilação-via-tcl).

# System on Chip - Software

## Kernel Image e rootfs.cpio

Para recriar o kernel, bootloader e sistema de arquivos.

Primeiro, configure e obtenha o busybox. Compile para RISC-V:

```
curl https://busybox.net/downloads/busybox-1.33.2.tar.bz2 | tar xfj -
cp PATH/TO/FPGA-SPDM/Kernel/busybox-1.33.2/.config busybox-1.33.2/.config
(cd busybox-1.33.2; make CROSS_COMPILE=/opt/riscv/bin/riscv64-unknown-linux-gnu-)
mkdir linux
cp PATH/TO/FPGA-SPDM/Kernel/busybox-1.33.2/linux/.config linux/.config
```

Com o busybox compilado, construa o initramfs.cpio. Dentro do repositório do busybox-1.33.2: 

```
mkdir initramfs
pushd initramfs
mkdir -p bin sbin lib etc dev home proc sys tmp mnt nfs root \
          usr/bin usr/sbin usr/lib
cp ../busybox bin/
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

```
cp PATH/TO/FPGA-SPDM/Kernel/buildroot_riscv64/buildroot-2023.05.1/.config .config
```

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

## Bootloader - OpenSBI

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

Para iniciar o Kernel Linux basta ir em LiteX/litex/litex/tools e executar em um terminal o comando. 

```
python3 litex_term.py /dev/ttyUSB1 --images=PATH/TO/SoC/SoC_with_spdm/kernel/boot.json
```

Execute o digilent_netfpga_sume.bit na FPGA a partir do Vivado.

# Anexos

### Tabela 1 - Arquivos de BIOS
| Arquivo  | Função |
| ------------- | ------------- |
| common.mak | Makefile de compilação |
| boot.c | Responsável por realizar a função de boot serial |
| bswapsi2.c | Biblioteca de suporte |
| int_endianness.h | Biblioteca de suporte |
| int_lib.h | Biblioteca de suporte |
| int_types.h | Biblioteca de suporte |
| int_util.h | Biblioteca de suporte |
| linker.ld | Linker com adição de um heap de memória para alocação do SPDM |
| spdmfuncs.c | Contém as funções de SPDM para a BIOS |
| spdmfuncs.h | Header das funções SPDM |
| Makefile | Responsável por realizar a compilação para código objeto das bibliotecas e da BIOS |
| cmd_bios.c  | Responsável por permitir o uso do SPDM a partir da BIOS |

### Tabela 2 - Arquivos de hardware LiteX
| Arquivo  | Função |
| ------------- | ------------- |
| v7_1000basex.py | Descrição para criação de Verilog com registradores SPDM da placa de rede |
| gth_7series.py | Descrição da máquina de estados do transceiver que é utilizado como Ethernet |
| gth_7series_init.py | Estado inicial da máquina com seus sinais |
| /platforms/digilent_netfpga_sume.py | Descrição de pinos da FPGA NetFPGA Sume. Utilizado para criação de Verilog |
| /targets/digilent_netfpga_sume.py | Descrição em alto nível da FPGA NetFPGA Sume. Utilizado para criação de Verilog |

# LICENSE

Em arquivo LICENSE

# Referências
[1] https://www.dmtf.org/sites/default/files/standards/documents/DSP0274_1.2.1.pdf

[2] https://digilent.com/reference/programmable-logic/netfpga-sume/start?srsltid=AfmBOorSQYE7kGKgUYJlLcDCyw6vfYHvrAbTzTf5HQJcgC4-E-jnjQHG

[3] https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html

[4] https://github.com/enjoy-digital/litex

[5]https://docs.amd.com/r/2023.1-English/ug893-vivado-ide/Using-the-Tcl-Console

[6] https://docs.amd.com/r/2023.1-English/ug1400-vitis-embedded/Installing-the-Vitis-Software-Platform


