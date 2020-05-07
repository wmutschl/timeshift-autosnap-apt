PKGNAME ?= timeshift-autosnap-apt

.PHONY: install

install:
	@install -Dm644 -t "$(DESTDIR)/etc/apt/apt.conf.d/" 80-timeshift-autosnap-apt
	@install -Dm755 -t "$(DESTDIR)/usr/bin/" timeshift-autosnap-apt
	@install -Dm644 -t "$(LIB_DIR)/etc/" timeshift-autosnap-apt.conf
