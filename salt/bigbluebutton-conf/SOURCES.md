Port 7443

local external_ip=$(dig +short $1 @resolver1.opendns.com | grep '^[.0-9]*$' | tail -n1)

{% for host in pillar['bigbluebuttonconf']: %}
  {% set external_ip = salt['cmd.run']('dig +short ' ~ host['external_lookup'] ~ '| grep '^[.0-9]*$' | tail -n1') %}
{% endfor %}

https://docs.bigbluebutton.org/2.2/configure-firewall.html

/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini

; Added by pauln -- stun.freeswitch.org
stunServerAddress=45.32.217.190
stunServerPort=3478

/opt/freeswitch/conf/vars.xml
/opt/freeswitch/conf/sip_profiles/external.xml

/usr/share/red5/webapps/sip/WEB-INF/bigbluebutton-sip.properties

/etc/bigbluebutton/nginx/sip.nginx

/usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml 

wsUrl: wss://meetings.theworkingcentre.org/bbb-webrtc-sfu




/usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml

