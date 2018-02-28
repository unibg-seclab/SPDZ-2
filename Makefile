# (C) 2017 University of Bristol. See License.txt


include CONFIG

MATH = $(patsubst %.cpp,%.o,$(wildcard Math/*.cpp))

TOOLS = $(patsubst %.cpp,%.o,$(wildcard Tools/*.cpp))

NETWORK = $(patsubst %.cpp,%.o,$(wildcard Networking/*.cpp))

AUTH = $(patsubst %.cpp,%.o,$(wildcard Auth/*.cpp))

PROCESSOR = $(patsubst %.cpp,%.o,$(wildcard Processor/*.cpp))

ifeq ($(USE_NTL),1)
FHEOFFLINE = $(patsubst %.cpp,%.o,$(wildcard FHEOffline/*.cpp FHE/*.cpp))
endif

# OT stuff needs GF2N_LONG, so only compile if this is enabled
ifeq ($(USE_GF2N_LONG),1)
OT = $(patsubst %.cpp,%.o,$(filter-out OT/OText_main.cpp,$(wildcard OT/*.cpp)))
OT_EXE = ot.x ot-offline.x
endif

COMMON = $(MATH) $(TOOLS) $(NETWORK) $(AUTH)
COMPLETE = $(COMMON) $(PROCESSOR) $(FHEOFFLINE) $(TINYOTOFFLINE)

LIB = libSPDZ.a
LIBSIMPLEOT = SimpleOT/libsimpleot.a


all: gen_input get_output online offline externalIO

ifeq ($(USE_NTL),1)
all: she-offline
endif

online: Fake-Offline.x Server.x Player-Online.x Check-Offline.x

offline: $(OT_EXE) Check-Offline.x

gen_input: gen_input_f2n.x gen_input_fp.x

get_output: get_output_fp.x

externalIO: client-setup.x bankers-bonus-client.x bankers-bonus-commsec-client.x

she-offline: Check-Offline.x spdz2-offline.x

Fake-Offline.x: Fake-Offline.cpp $(COMMON) $(PROCESSOR)
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS)

Check-Offline.x: Check-Offline.cpp $(COMMON) $(PROCESSOR)
	$(CXX) $(CFLAGS) Check-Offline.cpp -o Check-Offline.x $(COMMON) $(PROCESSOR) $(LDLIBS)

Server.x: Server.cpp $(COMMON)
	$(CXX) $(CFLAGS) Server.cpp -o Server.x $(COMMON) $(LDLIBS)

Player-Online.x: Player-Online.cpp $(COMMON) $(PROCESSOR)
	$(CXX) $(CFLAGS) Player-Online.cpp -o Player-Online.x $(COMMON) $(PROCESSOR) $(LDLIBS)

ifeq ($(USE_GF2N_LONG),1)
ot.x: $(OT) $(COMMON) OT/OText_main.cpp
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS) $(LIBSIMPLEOT)

ot-check.x: $(OT) $(COMMON)
	$(CXX) $(CFLAGS) -o ot-check.x OT/BitVector.o OT/OutputCheck.cpp $(COMMON) $(LDLIBS)

ot-bitmatrix.x: $(OT) $(COMMON) OT/BitMatrixTest.cpp
	$(CXX) $(CFLAGS) -o ot-bitmatrix.x OT/BitMatrixTest.cpp OT/BitMatrix.o OT/BitVector.o $(COMMON) $(LDLIBS)

ot-offline.x: $(OT) $(COMMON) ot-offline.cpp
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS) $(LIBSIMPLEOT)
endif

check-passive.x: $(COMMON) check-passive.cpp
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS)

gen_input_f2n.x: Scripts/gen_input_f2n.cpp $(COMMON)
	$(CXX) $(CFLAGS) Scripts/gen_input_f2n.cpp	-o gen_input_f2n.x $(COMMON) $(LDLIBS)

gen_input_fp.x: Scripts/gen_input_fp.cpp $(COMMON)
	$(CXX) $(CFLAGS) Scripts/gen_input_fp.cpp	-o gen_input_fp.x $(COMMON) $(LDLIBS)

get_output_fp.x: Scripts/get_output_fp.cpp $(COMMON)
	$(CXX) $(CFLAGS) Scripts/get_output_fp.cpp	-o get_output_fp.x $(COMMON) $(LDLIBS)

client-setup.x: client-setup.cpp $(COMMON) $(PROCESSOR)
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS)

bankers-bonus-client.x: ExternalIO/bankers-bonus-client.cpp $(COMMON) $(PROCESSOR)
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS)

bankers-bonus-commsec-client.x: ExternalIO/bankers-bonus-commsec-client.cpp $(COMMON) $(PROCESSOR)
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS)

ifeq ($(USE_NTL),1)
spdz2-offline.x: $(COMMON) $(FHEOFFLINE) spdz2-offline.cpp
	$(CXX) $(CFLAGS) -o $@ $^ $(LDLIBS)
endif

clean:
	-rm */*.o *.o */*.d *.d *.x core.* *.a gmon.out
