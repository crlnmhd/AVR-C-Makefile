# AVR-c makefile
# Looks for source and header files in src/ and places .o files in build


############### Configurations ######################
uP := atmega2560 #  (e.g. atmega328p, atmega2560)
BAUD := 115200
CPU_FREQ := 16000000UL
SERIAL := /dev/ttyUSB0
############# End of configuration ##################


SRC := src
OBJ := build

SOURCES := $(wildcard $(SRC)/*.c)
OBJECTS := $(patsubst $(SRC)/%.c, $(OBJ)/%.o, $(SOURCES))


.DEFAULT_GOAL := build
CC := avr-gcc
AVRINC :=/usr/avr/include
CFLAGS := -Wall -pedantic -Wextra -Wstrict-prototypes -fshort-enums -std=gnu17 -mmcu=$(uP) -Wno-unknown-attributes -I$(AVRINC) -DF_CPU=$(CPU_FREQ) -flto -Os -DBAUD=$(BAUD) -g
RAMEWORK := wiring		# Use 'arduino' for arduino uno

.PHONY: %.compdb_entry compile_commands.json dir all

# Borrowed from https://gist.github.com/JayKickliter/f4e1945abe1d3bbbe3263640a3669e3c.
%.compdb_entry: %.c
	@echo "    {" > $@
	@echo "        \"command\": \"$(CC)  $(CFLAGS) $(CPPFLAGS) -c $<\","   >> $@
	@echo "        \"directory\": \"$(CURDIR)\","               >> $@
	@echo "        \"file\": \"$<\""                    >> $@
	@echo "    },"                              >> $@

COMPDB_ENTRIES = $(addsuffix .compdb_entry, $(basename $(SOURCES)))

compile_commands.json: $(COMPDB_ENTRIES)
	@echo "[" > $@.tmp
	@cat $^ >> $@.tmp
	@sed '$$d' < $@.tmp > $@
	@echo "    }" >> $@
	@echo "]" >> $@
	@rm $@.tmp


# Create build directory only if it doesn't exits.
dir:
	mkdir -p build

# Target to compile and generate database for clangd.
build: dir all compile_commands.json

all: $(OBJECTS)
	$(CC) $(CFLAGS) $^ -o build/out.o
	avr-size --mcu=$(uP) -C build/out.o

$(OBJ)/%.o: $(SRC)/%.c
	$(CC) $(CFLAGS) -I$(SRC) -c -g $< -o $@

flash: build
	avr-size --mcu=$(uP) -C build/out.o
	avr-objcopy -O ihex --strip-debug -R .eeprom build/out.o build/out.hex
	avrdude -c $(FRAMEWORK) \
		-p $(uP) \
		-D -P $(SERIAL) \
		-b $(BAUD) \
		-U flash:w:build/out.hex

clean:
	@if [[ -e build ]]; then \
		rm -r build;						\
		fi
	@rm -f src/*.compbd_entry
	@echo "cleaning..."