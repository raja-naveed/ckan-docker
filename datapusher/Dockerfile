FROM ckan/ckan-base-datapusher:0.0.21

USER root

# Create a fixed datapusher_settings.py with proper SSL handling
RUN cat /srv/app/datapusher_settings.py | \
    sed "s/SSL_VERIFY = os.environ.get('DATAPUSHER_SSL_VERIFY', True)/# Fixed SSL_VERIFY to handle string 'False' properly\nSSL_VERIFY_STR = os.environ.get('DATAPUSHER_SSL_VERIFY', 'True')\nSSL_VERIFY = SSL_VERIFY_STR.lower() not in ('false', '0', 'no', '')/g" \
    > /tmp/datapusher_settings.py && \
    mv /tmp/datapusher_settings.py /srv/app/datapusher_settings.py && \
    chown ckan:ckan /srv/app/datapusher_settings.py

# Patch jobs.py to print actual HTTP errors
RUN find /usr/lib -name "jobs.py" -path "*/datapusher/*" -exec sed -i "s/raise HTTPError(/import traceback; traceback.print_exc(); raise HTTPError(/g" {} \;

# Verify the fix
RUN echo "=== SSL_VERIFY configuration ===" && \
    grep -A 2 "SSL_VERIFY" /srv/app/datapusher_settings.py

USER ckan

