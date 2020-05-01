# This only configures BBB. It does NOT install it.

{% set bbb = pillar['bigbluebutton-conf'] %}

{# ---- PREREQS ---- #}

bigbluebutton-conf-prereqs:
  pkg.installed:
    - pkgs: 
      - tomcat7   # prereq of bbb-demo but not overall?? 
      - linux-lowlatency
      - docker-ce

bigbluebutton-conf-nodemo:
  pkg.removed:
    - pkgs:
       - bbb-demo


{# ---- LOW LATENCY KERNEL ---- #}

bigbluebutton-conf-grubfile:
  file.managed:
    - name: /etc/grub.d/09_lowlatency
    - source: salt://bigbluebutton-conf/grub/09_lowlatency

bigbluebutton-conf-update-grub:
  cmd.run:
    - name: /usr/sbin/update-grub
    - onchanges:
      - file: /etc/grub.d/09_lowlatency

{# ---- BBB conf files ---- #}

bigbluebutton-conf-restart:
  cmd.run:
    - name: '/usr/bin/bbb-conf --restart'
    - onchanges:
      - file: /opt/freeswitch/conf*
      - file: /usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml
      - file: /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
      - file: /usr/share/bbb-web/WEB-INF/classes/spring*
      - file: /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml

bigbluebutton-conf-nginx:
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


bigbluebutton-conf-kurento-webrtcendpoint:
  file.blockreplace:
    - name: /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
    - marker_start:  ";; ----- Added by salt. Do not edit manually! -----\n"
    - marker_end:  ";; ----- End Added by salt. Do not edit manually! -----\n"
    - template: jinja
    - prepend_if_not_found: True
    - source: salt://bigbluebutton-conf/kurento/WebRtcEndpoint.snippet
    - append_newline: True
    - defaults:
        c: {{ host_info }}


bigbluebutton-conf-bbb-web-stun-turn:
  file.managed:
    - name: /usr/share/bbb-web/WEB-INF/classes/spring/turn-stun-servers.xml
    - source: salt://bigbluebutton-conf/bbb-web/turn-stun-servers.xml
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
      b: {{ host_info }}




{% set kurento_rtp_ports = [
  ('minPort', host_info['kurento']['rtp_start']),
  ('maxPort', host_info['kurento']['rtp_end']),
  ] %}

{% for conf in kurento_rtp_ports: %}
bigbluebutton-conf-freeswitch-{{ conf[0] }}:
  file.line:
    - name: /etc/kurento/modules/kurento/BaseRtpEndpoint.conf.ini
    - match: '{{ conf[0] }}='
    - content: '{{ conf[0] }}={{ conf[1] }}'
    - mode: replace
    - backup: false
{% endfor %}

{# ---- HTML5 Client ---- #}

{% for client_opt in host_info['html5_client']: %}

bigbluebutton-conf-html5-client-opt-{{ client_opt }}:
  file.line:
    - name: /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml
    - match: "{{ client_opt }}:"
    - content: "{{ client_opt }}: {{ host_info['html5_client'][client_opt] ~ ' # Salt-change' }}"
    - mode: replace
    - backup: False

{% endfor %}

bigbluebutton-conf-html5-rename-cameraProfiles:
  file.line:
    - name: /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml
    - match: "    cameraProfiles:$"
    - content: "    cameraProfiles-orig: # changed by Salt"
    - mode: replace
    - backup: False

{#
bigbluebutton-conf-html5-set-cameraProfiles:
  file.blockreplace:
    - name: /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml
    - marker_start: "# --- Camera Profiles added by salt. Do not edit manually! ---\n"
    - marker_end: "# --- End Camera Profilesadded by salt. Do not edit manually! ---\n"
    - append_newline: True
    - template: jinja
    - defaults: 
        bitrates: {{ host_info['html5_camera_profiles'] }}
    - source: salt://bigbluebutton-conf/meteor/cameraProfiles.snippet
    - prepend_if_not_found: True
    - backup: False
#}


{# ---- WEBRTC ----- #}


{% set bbb_web_configlines = [
  ('defaultWelcomeMessageFooter','<br><br>To join this meeting by phone, dial:<br>  %%DIALNUM%%<br>Then enter %%CONFNUM%% as the conference PIN number.<br>This server is running <a href="http://docs.bigbluebutton.org/"     target="_blank"><u>BigBlueButton</u></a>.'),
  ('defaultDialAccessNumber', host_info['sip']['did_readable']),
  ('swfSlidesRequired', 'false'),
  ('attendeesJoinViaHTML5Client', 'true'),
  ('moderatorsJoinViaHTML5Client', 'true'),
  ('lockSettingsDisableCam', host_info['bbb_web']['lockSettingsDisableCam']),
  ('disableRecordingDefault', host_info['bbb_web']['disableRecordingDefault']),
  ] %}

{% for conf in bbb_web_configlines: %}
bigbluebutton-conf-bbb-web-properties-{{ conf[0] }}:
  file.line:
    - name: /usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
    - match: "{{ conf[0] }}="
    - content: '{{ conf[0] }}={{ conf[1] }}'
    - mode: replace
    - backup: false
{% endfor %}


{# ---- FreeSWITCH changes ---- #}

bigbluebutton-conf-freeswitch-dialin:
  file.managed:
    - name: /opt/freeswitch/conf/dialplan/public/from_my_provider.xml
    - source: salt://bigbluebutton-conf/freeswitch/from_my_provider.xml
    - user: freeswitch
    - group: daemon
    - mode: 644
    - template: jinja
    - defaults:
      did: {{ host_info['sip']['did'] }}



{# TODO: What are the implications of changing the default password? #}
bigbluebutton-conf-freeswitch-energy-level:
  file.line:
    - name: /opt/freeswitch/conf/autoload_configs/conference.conf.xml
    - match: '<param name="energy-level" value="'
    - content: '<param name="energy-level" value="{{ host_info['freeswitch']['energy_level'] }}"/>'
    - mode: replace
    - backup: false


{% set freeswitch_rtp_ports = [
  ('rtp-start-port', host_info['freeswitch']['rtp_start']),
  ('rtp-end-port', host_info['freeswitch']['rtp_end']),
  ] %}

{% for conf in freeswitch_rtp_ports: %}
bigbluebutton-conf-freeswitch-{{ conf[0] }}:
  file.line:
    - name: /opt/freeswitch/etc/freeswitch/autoload_configs/switch.conf.xml
    - match: '<param name="{{ conf[0] }}" value="'
    - content: '<param name="{{ conf[0] }}" value="{{ conf[1] }}" />'
    - mode: replace
    - backup: false
{% endfor %}
 

bigbluebutton-conf-http-redirect:
  file.managed:
    - name: /etc/nginx/sites-enabled/bigbluebutton-http
    - source: salt://bigbluebutton-conf/nginx/bigbluebutton-http
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - defaults:
      servername: {{ servername }}

{% set bad_nginx = ['^  listen \[::\]:80;',
                    '^  listen 80;',
                     ] %}

{% for item in bad_nginx: %}
bigbluebutton-conf-nginx-comment-{{ loop.index }}:
  file.comment:
    - backup: false
    - name: /etc/nginx/sites-enabled/bigbluebutton
    - regex: {{ item }}

{% endfor %}

bigbluebutton-conf-nginx-no-redir-greenlight: 
  file.absent:
    - name: /etc/bigbluebutton/nginx/greenlight-redirect.nginx

bigbluebutton-conf-nginx-no-html5vsflash:
  file.absent:
    - name: /var/www/bigbluebutton-default/index_html5_vs_flash.html

# This should be customized via Jinja
bigbluebutton-conf-homepage:
  file.managed:
    - name: /var/www/bigbluebutton-default/index.html
    - source: salt://bigbluebutton-conf/nginx/bigbluebutton-index.html
    - user: root
    - group: root
    - mode: 644
    

bigbluebutton-conf-nginx-request-map:
  file.blockreplace:
    - name: /etc/nginx/sites-enabled/bigbluebutton
    - marker_start: "# --- Added by salt. Do not edit manually! ---\n"
    - marker_end: "# --- End added by salt. Do not edit manually! ---\n"
    - append_newline: True
    - template: jinja
    - defaults: 
        redirect_dict: {{ host_info['room_redirects'] }}
    - source: salt://bigbluebutton-conf/nginx/redirect-map.snippet
    - prepend_if_not_found: True
    - backup: False

# DELETE THIS?
bigbluebutton-conf-nginx-redirect-test:
  file.managed:
    - name: /etc/bigbluebutton/nginx/redirect-test.nginx
    - source: salt://bigbluebutton-conf/nginx/redirect-test.nginx
    - mode: 644



{# ---- REDIS ---- #}

# Need to implement rules here. There are like four of them. 
# https://stackoverflow.com/questions/36880321/why-redis-can-not-set-maximum-open-file

bluebutton-conf-redis:
  pkg.installed:
    - name: redis-server

{# Edit service file. This is gross but we need to either take over 
 # the entire file or do this. 
 # 
 # This is FRAGILE and will break as soon as Debian/Ubuntu change 
 # their service file. 
 #}

{# Hoo boy is this fragile. But inserting two lines is not working #}
bigbluebutton-conf-redis-systemd-blockcontents:
  file.blockreplace:
    - name: /etc/systemd/system/redis.service
    - marker_start: '[Service]'
    - marker_end: 'Type=forking'
    - backup: False
    - source: salt://bigbluebutton-conf/redis/service.snippet
    - template: jinja

bigbluebutton-conf-redis-sysctl:
  file.blockreplace:
    - name: /etc/sysctl.conf
    - marker_start: "# --- Added by salt. Do not edit manually! ---\n"
    - marker_end: "# --- End added by salt. Do not edit manually! ---\n"
    - source: salt://bigbluebutton-conf/redis/sysctl.conf.snippet
    - append_if_not_found: True
    - backup: False
  cmd.run:
    - name: 'sysctl -p'
    - onchanges:
      - file: bigbluebutton-conf-redis-sysctl


{# Apparently this one needs a full reboot. 
 # In principle this can be edited by many users, but 
 # screw it. I am not going to insert in the middle when 
 # this is a user-controlled file.
 #}

# hello
bigbluebutton-conf-redis-rc-local:
  file.managed:
    - name: /etc/rc.local
    - source: salt://bigbluebutton-conf/redis/rc.local
    - mode: 755
    - user: root



{# ---- GREENLIGHT ---- #}

# Take control of .env and docker file
# This is probably a BAD IDEA because the files might change frequently.

bigbluebutton-conf-greenlight-env:
  file.managed:
    - name: {{ host_info['greenlight']['basedir'] }}/.env
    - source: salt://bigbluebutton-conf/greenlight/env
    - user: root
    - mode: 644
    - template: jinja
    - defaults:
        conf: {{ host_info['greenlight'] }}
        smtp_server: {{ pillar['postfix-internal-docker']['alias_ip'] }}

bigbluebutton-conf-greenlight-docker-compose:
 file.managed: 
   - name: {{ host_info['greenlight']['basedir'] }}/docker-compose.yml
   - source: salt://bigbluebutton-conf/greenlight/docker-compose.yml
   - user: root
   - mode: 644
   - template: jinja
   - defaults:
       postgres_password: {{ host_info['greenlight']['postgres_password'] }}
   
# Have docker compose run on boot

bigbluebutton-conf-greenlight-systemd:
 file.managed: 
   - name: /etc/systemd/system/greenlight.service
   - source: salt://bigbluebutton-conf/greenlight/greenlight.service
   - user: root
   - mode: 644
   - template: jinja
   - defaults:
     conf: {{ host_info['greenlight'] }}

bigbluebutton-conf-systemd-reload:
  cmd.run:
    - name: systemctl --system daemon-reload
    - onchanges:
      - file: /etc/systemd/system/greenlight.service

bigbluebutton-conf-service:
  service.running:
    - name: greenlight
    - enable: True
    - watch:
      - file: {{ host_info['greenlight']['basedir'] }}/docker-compose.yml
      - file: {{ host_info['greenlight']['basedir'] }}/.env
    - require:
      - file: bigbluebutton-conf-greenlight-systemd


# ----- BBB-DOWNLOAD ----

bigbluebutton-conf-download-srcdir:
  file.directory:
    - name: {{ host_info['bbb_download']['srcdir'] }}
    - user: root
    - makedirs: True

bigbluebutton-conf-src:
  archive.extracted:
    - name: {{ host_info['bbb_download']['srcdir'] }}
    - source: https://github.com/createwebinar/bbb-download/archive/master.zip
    - clean: true
    - archive_format: zip
    - skip_verify: true
    - require:
      - file: bigbluebutton-conf-download-srcdir

bigbluebutton-conf-install:
  cmd.run:
    - cwd: {{ host_info['bbb_download']['srcdir'] }}/bbb-download-master
    - name: './install.sh'
    - onchanges:
      - archive: bigbluebutton-conf-src

