prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(bindir)"
	install ".build/release/mono-to-stereo" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/mono-to-stereo"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
