INST_PREFIX ?= /usr
INST_LIBDIR ?= $(INST_PREFIX)/lib64/lua/5.1
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INSTALL ?= install

C_SO_NAME := libr3.so

CFLAGS := -O3 -g -Wall -fpic

LDFLAGS := -shared
# on Mac OS X, one should set instead:
# LDFLAGS := -bundle -undefined dynamic_lookup

MY_CFLAGS := $(CFLAGS) -DBUILDING_SO
MY_LDFLAGS := $(LDFLAGS) -fvisibility=hidden

OBJS := r3_resty.o
R3_FOLDER := r3
R3_CONGIGURE := r3/configure
R3_STATIC_LIB := r3/.libs/libr3.a

.PHONY: default
default: compile

### test:         Run test suite. Use test=... for specific tests
.PHONY: test
test: compile
	    TEST_NGINX_SLEEP=0.001 \
	    TEST_NGINX_LOG_LEVEL=info \
	    prove -j$(jobs) -r $(test)


### clean:        Remove generated files
.PHONY: clean
clean:
	cd r3 && make clean
	rm -f $(C_SO_NAME) $(OBJS) ${R3_CONGIGURE}

### compile:      Compile library
.PHONY: compile

compile: ${R3_FOLDER} ${R3_CONGIGURE} ${R3_STATIC_LIB} $(C_SO_NAME)

${OBJS} : %.o : %.c
	$(CC) $(MY_CFLAGS) -c $<

${C_SO_NAME} : ${OBJS}
	$(CC) $(MY_LDFLAGS) $(OBJS) r3/.libs/libr3.a -o $@

${R3_FOLDER} :
	cd deps && tar -xvf r3-2.0.tar.gz && mv r3 ../

${R3_CONGIGURE} :
	cd r3 && sh autogen.sh

${R3_STATIC_LIB} :
	cd r3 && sh configure && make


### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(INST_LUADIR)/resty/
	$(INSTALL) lib/resty/*.lua $(INST_LUADIR)/resty/
	$(INSTALL) $(C_SO_NAME) $(INST_LIBDIR)/

### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
