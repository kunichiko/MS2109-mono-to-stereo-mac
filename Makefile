prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(bindir)"
	install ".build/release/mono2stereo" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/mono2stereo"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
