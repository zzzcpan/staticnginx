
# Copyright (c) 2015 Alexandr Gomoliako. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials provided
#     with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

NAME = staticnginx
VERSION = 1.8.0.1

# http://nginx.org/en/download.html
NGINX_URL = "http://nginx.org/download/nginx-1.8.0.tar.gz"
# https://www.openssl.org/source/
OPENSSL_URL = "https://www.openssl.org/source/openssl-1.0.1p.tar.gz"
# http://www.cpan.org/src/README.html
PERL_URL = "http://www.cpan.org/src/5.0/perl-5.20.3.tar.gz"
# http://www.zlib.net/
ZLIB_URL = "http://sourceforge.net/projects/libpng/files/zlib/1.2.8/zlib-1.2.8.tar.gz"
# http://www.pcre.org/
PCRE_URL = "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.gz"

# temp copy of perl to fullfill release dir
RELEASE_PERL = $(PWD)/objs/release/bin/perl
RELEASE_PERL_SITEARCHEXP = `$(RELEASE_PERL) -MConfig -e 'print "$$Config{sitearchexp}/"'`
RELEASE_PERL_ARCHLIBEXP = `$(RELEASE_PERL) -MConfig -e 'print "$$Config{archlibexp}/"'`

all: objs/nginx/objs/nginx
	

release: objs/nginx/objs/nginx objs/myperl/bin/perl
	rm -rf objs/release
	mkdir -p objs/release/bin
	cp objs/myperl/bin/perl objs/release/bin/perl
	cp objs/nginx/objs/nginx objs/release/bin/nginx
	cp -r objs/myperl/lib objs/release/lib
	cp objs/nginx/objs/src/http/modules/perl/nginx.pm \
		$(RELEASE_PERL_SITEARCHEXP)
	rm -rf $(RELEASE_PERL_ARCHLIBEXP)/auto
	rm -f $(RELEASE_PERL_ARCHLIBEXP)/CORE/libperl.a
	rm objs/release/bin/perl
	rm -rf $(NAME)-$(VERSION)-bin
	rm -f $(NAME)-$(VERSION)-bin.tar.gz
	mv objs/release $(NAME)-$(VERSION)-bin
	tar -czf $(NAME)-$(VERSION)-bin.tar.gz $(NAME)-$(VERSION)-bin/

tarball: \
		objs/nginx/configure \
		objs/perl/Configure \
		objs/zlib/configure \
		objs/pcre/configure \
		objs/openssl/config
	mkdir $(NAME)-$(VERSION) \
	  && cp -rp objs Makefile dwnlx.sh \
	    README LICENSE *.patch $(NAME)-$(VERSION)/ \
	  && rm -f $(NAME)-$(VERSION).tar.gz \
	  && tar -czf $(NAME)-$(VERSION).tar.gz \
	    $(NAME)-$(VERSION)/

# apparently nginx requires make -j1 to build openssl before 
# linking to it 
objs/nginx/objs/nginx: objs/nginx/objs/Makefile
	cd objs/nginx \
	  && $(MAKE) -j1

# --with-perl requires $(PWD) because openssl cannot be configured
# with relative perl path
objs/nginx/objs/Makefile: \
		objs/nginx/configure \
		objs/myperl/bin/perl \
		objs/zlib/configure \
		objs/pcre/configure \
		objs/openssl/config
	cd objs/nginx \
	  && sh configure \
		--with-cc-opt="-static" \
		--with-ld-opt="-static" \
		--with-openssl="../openssl" \
		--with-zlib="../zlib" \
		--with-pcre="../pcre" \
		--with-perl="$(PWD)/objs/myperl/bin/perl" \
		--add-module="ngx_http_referer_host_module" \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_auth_request_module \
		--with-http_perl_module \
		--with-mail \
		--with-mail_ssl_module

objs/nginx/configure:
	sh dwnlx.sh objs nginx $(NGINX_URL) \
	  && cd objs/nginx \
	  && patch -p1 < ../../nginx_ngx_http_referer_host_module.patch \
	  && patch -p1 < ../../nginx_set_perl_openssl.patch \
	  && patch -p1 < ../../nginx_static_perl_autoconf.patch \
	  && patch -p1 < ../../nginx_static_perl_bootstrap.patch \
	  && patch -p1 < ../../nginx_zlib_distclean.patch \
	  && rm -f Makefile

objs/myperl/bin/perl: objs/perl/perl
	cd objs/perl \
	  && $(MAKE) install

objs/perl/perl: objs/perl/Makefile
	cd objs/perl \
	  && $(MAKE)

objs/perl/Makefile: objs/perl/Configure
	cd objs/perl \
	  && sh Configure \
		-sde \
		-Dusemymalloc=n \
		-Dusethreads=y \
		-Duselargefiles \
		-Duse64bitint \
		-Uusedl \
		-Uuseshrplib \
		-Duserelocatableinc \
		-Dprefix="$(PWD)/objs/myperl"

objs/perl/Configure:
	sh dwnlx.sh objs perl $(PERL_URL) \
	  && cd objs/perl \
	  && patch -p1 < ../../perl_zlib_noextern.patch \
	  && rm -f Makefile

objs/openssl/config:
	sh dwnlx.sh objs openssl $(OPENSSL_URL)

objs/zlib/configure:
	sh dwnlx.sh objs zlib $(ZLIB_URL)

objs/pcre/configure:
	sh dwnlx.sh objs pcre $(PCRE_URL)

clean:
	rm -rf objs
	rm -rf $(NAME)-$(VERSION)
	rm -rf $(NAME)-$(VERSION)-bin

realclean: clean
	rm *.tar.gz

