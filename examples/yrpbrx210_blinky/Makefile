TARGETMCU       ?= rx200

CROSS           := rx-elf-
CC              := $(CROSS)gcc
LDSCRIPT	:= rx2108.ld
FLASHER		:= rx -B rx210 -m 1,1 -l 3200
CFLAGS          := -Wall -Werror -g -mcpu=$(TARGETMCU) -nostartfiles
CFLAGS += -fdata-sections -ffunction-sections -Wl,--gc-sections
LDFLAGS		:=


SRCS                    := crt0.S crtn.S main.c
PROG                    := main

all:                    $(PROG).elf

$(PROG).elf:    $(OBJS)
	$(CC) $(CFLAGS) -o $(PROG).elf $(SRCS) -T $(LDSCRIPT) $(LDFLAGS)

clean:
	-rm -f $(PROG).elf

install: $(PROG).elf
	$(FLASHER) $(PROG).elf
