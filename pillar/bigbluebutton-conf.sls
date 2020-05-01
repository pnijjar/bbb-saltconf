{# This is not setting up BBB. It is only configuring it.
 # I probably should set it up too.
 #}
bigbluebutton-conf:
  freeswitch_port_ssl: 7443
  freeswitch_port_insecure: 5060
  freeswitch_port_internal: 5066

  hosts:
    meetings.theworkingcentre.org:
      stun_server: # See secrets for other info
        port: 3478
      turn_server: # See secrets for other info
        port: 5349
        protocol: 'turns' # turn for unencrypted, turns for TLS
      servername: meetings.theworkingcentre.org
      internal_ip: 172.26.110.13
      external_lookup: 'twc256k.dyn.theworkingcentre.org'
      freeswitch:
        energy_level: 50
        # Default range for FreeSWITCH: 16384-24576
        rtp_start: 20001
        rtp_end: 25000
      kurento:
        # Default range for Kurento: 24577-32768
        rtp_start: 25001
        rtp_end: 30000
      html5_client:
        enableListenOnly: 'true'
        wsUrl: 'wss://meetings.theworkingcentre.org/bbb-webrtc-sfu'
        enableVideo: 'true'
        relayOnlyOnReconnect: 'true'
      html5_camera_profiles:
        low: 101
        medium: 200
        high: 500
        hd: 800
      bbb_web:
        lockSettingsDisableCam: 'true' # Should webcams be off by default?
        # lock_disable_private_chat?
        disableRecordingDefault: 'true'
      greenlight:
        basedir: '/home/bbb/greenlight'
        smtp_domain: bbb.theworkingcentre.org
        relative_url_root: '/b'
        default_registration: invite
        allow_mail_notifications: 'true'
      bbb_download:
        srcdir: '/home/bbb/src'

      

