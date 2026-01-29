CXX = g++
CXXFLAGS = -std=c++17 -O3

BINDIR = bin
SRCDIR = src

TARGETS = $(BINDIR)/gen_changelist $(BINDIR)/calc_displacement $(BINDIR)/filter_backslash $(BINDIR)/change_corner
SOURCES = $(SRCDIR)/gen_changelist.cpp $(SRCDIR)/calc_displacement.cpp $(SRCDIR)/filter_backslash.cpp $(SRCDIR)/change_corner.cpp

# Default target - build all executables
all: $(TARGETS)

# Create bin directory if it doesn't exist
$(BINDIR):
	mkdir -p $(BINDIR)

# # Build gen_changelist
# $(BINDIR)/gen_changelist: $(SRCDIR)/gen_changelist.cpp | $(BINDIR)
# 	$(CXX) $(CXXFLAGS) -o $@ $<

# # Build calc_displacement
# $(BINDIR)/calc_displacement: $(SRCDIR)/calc_displacement.cpp | $(BINDIR)
# 	$(CXX) $(CXXFLAGS) -o $@ $<
	
# # Build filter_backslash
# $(BINDIR)/filter_backslash: $(SRCDIR)/filter_backslash.cpp | $(BINDIR)
# 	$(CXX) $(CXXFLAGS) -o $@ $<

# Build change_corner
$(BINDIR)/change_corner: $(SRCDIR)/change_corner.cpp | $(BINDIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

# Clean all binaries
clean:
	rm -f $(TARGETS)

# Individual targets for convenience
# gen_changelist: $(BINDIR)/gen_changelist
# calc_displacement: $(BINDIR)/calc_displacement
# filter_backslash: $(BINDIR)/filter_backslash
change_corner: $(BINDIR)/change_corner

.PHONY: all clean gen_changelist calc_displacement filter_backslash change_corner