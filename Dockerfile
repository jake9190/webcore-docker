FROM httpd:2.4-alpine

# Serve the local (unminified) dashboard/ folder straight from the build context.
COPY dashboard/ /var/www/webcore/
COPY webcore-apache.conf /usr/local/apache2/conf/webcore.conf

# Enable the modules the dashboard needs:
#   rewrite    -> dashboard/.htaccess HTML5-mode deep-link fallback
#   proxy/http -> optional same-origin reverse proxy to the local hub
# then include our vhost config from the main httpd.conf.
RUN sed -i \
      -e 's|^#\(LoadModule rewrite_module .*\)|\1|' \
      -e 's|^#\(LoadModule proxy_module .*\)|\1|' \
      -e 's|^#\(LoadModule proxy_http_module .*\)|\1|' \
      conf/httpd.conf \
    && printf '\nInclude conf/webcore.conf\n' >> conf/httpd.conf

EXPOSE 80