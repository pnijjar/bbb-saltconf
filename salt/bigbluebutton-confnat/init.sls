# This only configures BBB. It does NOT install it.

{% set bbb = pillar['bigbluebutton-conf'] %}

{# ---- BBB conf files ---- #}

bigbluebutton-confnat-restart:
  cmd.run:
    - name: '/usr/bin/bbb-conf --restart'
    - onchanges:
      - file: /opt/freeswitch/conf*
      - file: /usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml
      - file: /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
      - file: /usr/share/bbb-web/WEB-INF/classes/spring*
      - file: /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

bigbluebutton-confnat-nginx:
  service.running:
    - name: nginx
    - watch:
      - file: /etc/nginx/sites-enabled/bigbluebutton
      - file: /etc/nginx/sites-enabled/bigbluebutton-http
      - file: /etc/bigbluebutton/nginx*
      

{% set host = grains['id'] %}
{% set host_info = bbb['hosts'][host] %}
{% set internal_ip = host_info['internal_ip'] %}
{% set servername = host_info['servername'] %}

{# The output of dig had better be numeric (at least for the last value) #}
{% set external_ip = salt['cmd.run']('dig +short ' ~ host_info['external_lookup'] ).split() | last  %}
{# {% set external_ip = salt['cmd.run']('dig +short ' ~ host_info['external_lookup'] ~ ' | grep ''^[.0-9]*\$'' | tail -n1') %} #}

bigbluebutton-confnat-red5-bbb-sip-properties:
  file.managed:
    - name: /usr/share/red5/webapps/sip/WEB-INF/bigbluebutton-sip.properties
    - source: salt://bigbluebutton-conf/red5/bigbluebutton-sip.properties
    - user: red5
    - group: red5
    - mode: 644
    - template: jinja
    - defaults:
      internal_ip: {{ internal_ip }}
      external_ip: {{ external_ip }}
      freeswitch_port: {{ bbb['freeswitch_port_insecure'] }}



{# ---- WEBRTC ----- #}

{% set configlines = [('ip', external_ip ),
                      ('sip_ip', external_ip),
                      ('port',  '"' ~ bbb['freeswitch_port_ssl'] ~ '"' ),
                     ] %}

{% for conf in configlines: %}
bigbluebutton-confnat-bbb-webrtc-sfu-{{ conf[0] }}:
  file.line:
    - name: /usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml
    - match: "  {{ conf[0] }}: "
    - content: '  {{ conf[0] }}: {{ conf[1] }}'
    - mode: replace
    - backup: false
  
{% endfor %}


{# ---- HAIRPIN NAT INTERFACE ---- #}
{# This will break for netplan-based distros!! #}
bigbluebutton-confnat-hairpin-interface:
  file.managed:
    - name: /etc/network/interfaces.d/hairpin-bbb
    - source: salt://bigbluebutton-conf/interfaces/hairpin-bbb
    - user: root
    - mode: 644
    - template: jinja
    - defaults:
      external_ip: {{ external_ip }}

bigbluebutton-confnat-networking-service:
  service.running:
    - name: networking
    - watch:
      - file: /etc/network/interfaces.d/hairpin-bbb

{# ---- FreeSWITCH changes ---- #}

# Probably these should be line edits, not managed files. Inconsistency!
bigbluebutton-confnat-freeswitch-vars:
  file.managed:
    - name: /opt/freeswitch/conf/vars.xml
    - source: salt://bigbluebutton-conf/freeswitch/vars.xml
    - user: freeswitch
    - group: daemon
    - mode: 644
    - template: jinja
    - defaults:
      external_ip: {{ external_ip }}
      internal_ip: {{ internal_ip }}
      default_password: {{ host_info['freeswitch']['default_password'] }}

bigbluebutton-confnat-freeswitch-external:
  file.managed:
    - name: /opt/freeswitch/conf/sip_profiles/external.xml
    - source: salt://bigbluebutton-conf/freeswitch/external.xml
    - user: freeswitch
    - group: daemon
    - mode: 644
    - template: jinja
    - defaults:
      external_ip: {{ external_ip }}


{# ---- NGINX Changes ---- #}

bigbluebutton-confnat-sip-nginx:
  file.managed:
    - name: /etc/bigbluebutton/nginx/sip.nginx
    - source: salt://bigbluebutton-conf/nginx/sip.nginx
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
      external_ip: {{ external_ip }}
      freeswitch_port: {{ bbb['freeswitch_port_ssl'] }}


