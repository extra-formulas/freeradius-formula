freeradius:
  max_request_time: 30
  cleanup_delay: 5
  max_requests: 16384
  hostname_lookups: no
  log:
    destination: syslog
    syslog_facility: daemon
    stripped_names: no
    auth: yes
    msg_denied: You are already logged in - access denied
  security:
    user: radiusd
    group: radiusd
    allow_core_dumps: "no"
    max_attributes: 200
    reject_delay: 1
    status_server: yes
  proxy: ~
  thread:
    start_servers: 5
    max_servers: 32
    min_spare_servers: 3
    max_spare_servers: 10
    max_requests_per_server: 0
    auto_limit_acct: no
  clients:
    - "client localhost":
      - ipaddr: 127.0.0.1
      - proto: "*"
      - secret: AVerySecureString
      - require_message_authenticator: "no"
      - nas_type: other
      - response_window: 10.0
      - limit:
        - max_connections: 0
        - lifetime: 0
        - idle_timeout: 120
  modules:
    always: ~
    attr_filter: ~
    cache_eap: ~
    chap: ~
    date: ~
    detail: ~
    "detail.log": ~
    dhcp: ~
    digest: ~
    dynamic_clients: ~
    eap:
      - eap:
        - default_eap_type: mschapv2
        - timer_expire: 60
        - ignore_unknown_eap_types: no
        - cisco_accounting_username_bug: no
        - max_sessions: "${max_requests}"
#        - md5: {}
#        - leap: {}
#        - gtc:
#          - auth_type: PAP
        - "tls-config tls-common":
          - private_key_password: whatever
          - private_key_file: "${certdir}/server.pem"
          - certificate_file: "${certdir}/server.pem"
          - ca_file: "${cadir}/ca.pem"
#          - dh_file: "${certdir}/dh"
          - ca_path: "${cadir}"
          - cipher_list: '"DEFAULT"'
          - cipher_server_preference: "yes"
          - tls_min_version: "\"1.2\""
          - tls_max_version: "\"1.2\""
          - ecdh_curve: '"prime256v1"'
          - cache:
            - enable: "no"
#
#
#          - cache:
#            - enable: "no"
#            - lifetime: 24
#          - verify: {}
#          - ocsp:
#            - enable: "no"
#            - override_cert_url: "yes"
#            - url: '"http://127.0.0.1/ocsp/"'
#
        - tls:
          - tls: tls-common
        - ttls:
          - tls: tls-common
          - default_eap_type: md5
          - copy_request_to_tunnel: "no"
          - use_tunneled_reply: "no"
          - virtual_server: '"inner-tunnel"'
        - peap:
          - tls: tls-common
          - default_eap_type: mschapv2
          - copy_request_to_tunnel: "no"
          - use_tunneled_reply: "no"
          - virtual_server: '"inner-tunnel"'
        - mschapv2: {}
    echo: ~
    exec: ~
    expiration: ~
    expr: ~
    files: ~
    ldap:
      - ldap:
        - server: "'ldap-server.example.com'"
        - identity: "'krbprincipalname=radius/server.example.com@EXAMPLE.COM,cn=services,cn=accounts,dc=example,dc=com'"
        - password: "'LDAPAccountPassword'"
        - base_dn: "'dc=example,dc=com'"
        - sasl: {}
        - update:
          - "control:Password-With-Header	+= 'userPassword'"
          - "control:NT-Password		:= 'ipaNTHash'"
          - "control:			+= 'radiusControlAttribute'"
          - "request:			+= 'radiusRequestAttribute'"
          - "reply:				+= 'radiusReplyAttribute'"
        - user:
          - base_dn: '"cn=users,cn=accounts,${..base_dn}"'
          - filter: '"{{ '(uid=%{%{Stripped-User-Name}:-%{User-Name}})' }}"'
          - sasl: {}
        - group:
          - base_dn: '"cn=groups,cn=accounts,${..base_dn}"'
          - filter: "'(objectClass=posixGroup)'"
          - membership_attribute: "'memberOf'"
        - "post-auth":
          - update:
            - 'description := "Authenticated at %S"'
        - options:
          - chase_referrals: yes
          - rebind: yes
          - res_timeout: 10
          - srv_timelimit: 5
          - net_timeout: 15
          - idle: 360
          - probes: 3
          - interval: 3
          - ldap_debug: "0x0028"
        - tls:
            - start_tls: yes
        - pool:
          - start: "${thread[pool].start_servers}"
          - min: "${thread[pool].min_spare_servers}"
          - max: "${thread[pool].max_servers}"
          - spare: "${thread[pool].max_spare_servers}"
          - uses: 0
          - retry_delay: 30
          - lifetime: 0
          - idle_timeout: 60
    linelog: ~
    logintime: ~
    mschap: ~
    ntlm_auth: ~
    pap: ~
    passwd: ~
    preprocess: ~
    radutmp: ~
    realm: ~
    replicate: ~
    soh: ~
    sradutmp: ~
    unix: ~
    unpack: ~
    utf8: ~
  virtual:
    "inner-tunnel": ~
    my-service:
      - listen:
        - type: auth
        - ipaddr: '"*"'
        - port: 1812
      - authorize:
        - filter_username
        - preprocess
        - auth_log
        - chap
        - mschap
        - digest
        - suffix
        - eap:
          - "ok = return"
#          - "updated = return"
        - files
        - "-ldap"
        - expiration
        - logintime
        - pap
      - authenticate:
        - "Auth-Type PAP":
          - pap
        - "Auth-Type CHAP":
          - chap
        - "Auth-Type MS-CHAP":
          - mschap
        - mschap
        - digest
        - eap
        - "Auth-Type EAP":
          - eap:
            - "handled = 1"
          - "if (handled && (Response-Packet-Type == Access-Challenge))":
            - "attr_filter.access_challenge.post-auth"
            - handled
      - "post-auth":
        - update:
          - "&reply: += &session-state:"
        - reply_log
        - exec
        - remove_reply_message_if_eap
        - "Post-Auth-Type REJECT":
          - "attr_filter.access_reject"
          - eap
          - remove_reply_message_if_eap
        - "Post-Auth-Type Challenge": {}
