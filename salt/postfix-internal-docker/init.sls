{% set p = pillar['postfix-internal-docker'] %}
{% set configlines = [('relayhost', p['relayhost']),
                      ] %}


{% for conf in configlines %}
postfix-internal-docker-{{ conf[0] }}:
  file.line:
    - name: /etc/postfix/main.cf
    - match: {{ conf[0] }} =
    - content: {{ conf[0] }} = {{ conf[1] }}
    - mode: replace
    - backup: False
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix
{% endfor %}


postfix-internal-docker-relay-domains::
  file.line:
    - name: /etc/postfix/main.cf
    - match: relay_domains =
    - content: relay_domains = $mydestination 
      {%- for dest in p['extra_relay_domains']: -%}
        {{ ' ' ~ dest }}
      {%- endfor %}

    - mode: replace
    - backup: False
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix


postfix-internal-docker-inet-interfaces:
  file.line:
    - name: /etc/postfix/main.cf
    - match: inet_interfaces = 
    - content: inet_interfaces = 127.0.0.1 {{ p['alias_ip'] }}
    - mode: replace
    - backup: False
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix

{% set docker_nets = salt['network.subnets'](interfaces='docker0') %}

postfix-internal-docker-mynetworks:
  file.line:
    - name: /etc/postfix/main.cf
    - match: mynetworks =
    - content: mynetworks = {{ p['loopback_networks'] }} {{ p['alias_ip'] }}/32   
      {%- for net in docker_nets -%}
        {{ ' ' ~ net }}
      {%- endfor %}

    - mode: replace
    - backup: False
    - require:
      - pkg: postfix
    - watch_in:
      - service: postfix




postfix-internal-docker-networking-service:
  service.running:
    - name: networking
    - watch:
      - file: /etc/network/interfaces.d/postfix-loopback

{# This will break for netplan-based distros!! #}
postfix-internal-docker-loopback:
  file.managed:
    - name: /etc/network/interfaces.d/postfix-loopback
    - source: salt://postfix-internal-docker/postfix-loopback
    - user: root
    - mode: 644
    - template: jinja
    - defaults:
      p: {{ p }}



