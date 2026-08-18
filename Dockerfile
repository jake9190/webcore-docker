# ---------------------------------------------------------------------------
# Stage 1: minify the dashboard/ assets (HTML, CSS, JS)
# ---------------------------------------------------------------------------
FROM node:20-alpine AS minify

WORKDIR /build

# Minifiers: html-minifier-terser (HTML), clean-css-cli (CSS), terser (JS).
RUN npm install -g html-minifier-terser clean-css-cli terser

COPY dashboard/ /build/dashboard/

# Minify in place, skipping files that are already minified (*.min.*).
RUN set -e; \
    cd /build/dashboard; \
    find . -type f -name '*.html' \
      -exec html-minifier-terser --collapse-whitespace --remove-comments \
        --minify-css true --minify-js true -o {} {} \; ; \
    find . -type f -name '*.css' ! -name '*.min.css' \
      -exec sh -c 'cleancss -o "$1" "$1"' _ {} \; ; \
    find . -type f -name '*.js' ! -name '*.min.js' \
      -exec sh -c 'terser "$1" --compress --mangle -o "$1"' _ {} \;

# ---------------------------------------------------------------------------
# Stage 2: serve the minified dashboard/ folder with Apache httpd
# ---------------------------------------------------------------------------
FROM httpd:2.4-alpine

# Serve the minified dashboard/ folder produced by the minify stage.
COPY --from=minify /build/dashboard/ /var/www/webcore/
COPY webcore-apache.conf /usr/local/apache2/conf/webcore.conf
COPY docker-entrypoint.sh /usr/local/bin/webcore-entrypoint

# Enable the modules the dashboard needs:
#   rewrite    -> dashboard/.htaccess HTML5-mode deep-link fallback
#   proxy/http -> optional same-origin reverse proxy to the local hub
#   headers    -> cache-control on the unversioned html/js/css assets
# then include our vhost config from the main httpd.conf.
RUN sed -i \
      -e 's|^#\(LoadModule rewrite_module .*\)|\1|' \
      -e 's|^#\(LoadModule proxy_module .*\)|\1|' \
      -e 's|^#\(LoadModule proxy_http_module .*\)|\1|' \
      -e 's|^#\(LoadModule headers_module .*\)|\1|' \
      conf/httpd.conf \
    && printf '\nInclude conf/webcore.conf\n' >> conf/httpd.conf \
    && chmod +x /usr/local/bin/webcore-entrypoint

EXPOSE 80

  ENTRYPOINT ["webcore-entrypoint"]
  CMD ["httpd-foreground"]