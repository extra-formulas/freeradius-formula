{%- set default_sources = {'module' : 'freeradius', 'defaults' : True, 'pillar' : True, 'grains' : ['os_family','os','osfinger']} %}
{%- from "freeradius/defaults/load_config.jinja" import config as freeradius with context %}

freeradius:
  pkg.installed:
    - pkgs: {{ freeradius.pkgs_core }}

{{ freeradius.radiusd_conf }}:
  file.managed:
    - source: salt://freeradius/radiusd.conf.jinja
    - template: jinja
    - context: {{ freeradius }}
    - mode: 640
    - user: root
    - group: {{ freeradius.service_group }}

{%- if freeradius.proxy is defined and (freeradius.proxy is not none) %}

{{ freeradius.radiusd_conf_includes_dir + freeradius.includes.proxy }}:
  file.managed:
    - source: salt://freeradius/generic-template.jinja
    - template: jinja
    - context:
      content: {{ freeradius.proxy }}
    - mode: 640
    - user: root
    - group: {{ freeradius.service_group }}
    - require_in:
      - {{ freeradius.radiusd_conf }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endif %}

{%- if (freeradius.clients is defined) and (freeradius.clients is not none) %}

{{ freeradius.radiusd_conf_includes_dir + freeradius.includes.clients }}:
  file.managed:
    - source: salt://freeradius/generic-template.jinja
    - template: jinja
    - context:
      content: {{ freeradius.clients }}
    - mode: 640
    - user: root
    - group: {{ freeradius.service_group }}
    - require_in:
      - {{ freeradius.radiusd_conf }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endif %}

{%- if freeradius.virtual is defined %}

{{ freeradius.radiusd_conf_includes_dir + freeradius.includes.sites_enabled }}:
  file.directory:
    - clean: true
{%- if freeradius.virtual|length %}
    - exclude_pat: 'E@({{ freeradius.virtual|join(")|(") }})'
{%- endif %}

{%- for virtual_host, server_data in freeradius.virtual.items() %}

{%- if server_data is not none %}
{{ freeradius.radiusd_conf_includes_dir + freeradius.available_configs.sites_available + virtual_host }}:
  file.managed:
    - source: salt://freeradius/generic-template.jinja
    - template: jinja
    - context:
      content:
        - "server {{ virtual_host }}" : {{ server_data }}
    - mode: 640
    - user: root
    - group: {{ freeradius.service_group }}
    - require_in:
      - file: {{ freeradius.radiusd_conf_includes_dir + freeradius.includes.sites_enabled + virtual_host }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endif %}

{{ freeradius.radiusd_conf_includes_dir + freeradius.includes.sites_enabled + virtual_host }}:
  file.symlink:
    - target: {{ '../' + freeradius.available_configs.sites_available + virtual_host }}
    - mode: 777
    - user: root
    - group: {{ freeradius.service_group }}
    - require:
      - file: {{ freeradius.radiusd_conf_includes_dir + freeradius.includes.sites_enabled }}
    - require_in:
      - file: {{ freeradius.radiusd_conf }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endfor %}
{%- endif %}

{%- if freeradius.modules is defined %}

{{ freeradius.radiusd_conf_includes_dir + freeradius.includes.mods_enabled }}:
  file.directory:
    - clean: true
{%- if freeradius.modules|length %}
    - exclude_pat: 'E@({{ freeradius.modules|join(")|(") }})'
{%- endif %}

{%- for module_name, module_conf in freeradius.modules.items() %}

{%- if module_name in freeradius.pkgs_modules %}
freeradius_module_{{ module_name }}_pkg:
  pkg.installed:
    - name: {{ freeradius.pkgs_modules[module_name] }}
    - require_in:
      - file: {{ freeradius.radiusd_conf_includes_dir + freeradius.includes.mods_enabled + module_name }}
{%- endif %}

{%- if module_conf is not none %}
{{ freeradius.radiusd_conf_includes_dir + freeradius.available_configs.mods_enabled + module_name }}:
  file.managed:
    - source: salt://freeradius/generic-template.jinja
    - template: jinja
    - context:
      content: {{ module_conf }}
    - mode: 640
    - user: root
    - group: {{ freeradius.service_group }}
    - require_in:
      - file: {{ freeradius.radiusd_conf_includes_dir + freeradius.includes.mods_enabled + module_name }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endif %}

{{ freeradius.radiusd_conf_includes_dir + freeradius.includes.mods_enabled + module_name }}:
  file.symlink:
    - target: {{ '../' + freeradius.available_configs.mods_enabled + module_name }}
    - mode: 777
    - user: root
    - group: {{ freeradius.service_group }}
    - require:
      - file: {{ freeradius.radiusd_conf_includes_dir + freeradius.includes.mods_enabled }}
    - require_in:
      - file: {{ freeradius.radiusd_conf }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endfor %}
{%- endif %}

{%- if freeradius.certs is defined and (freeradius.certs is not none) %}

{%- for cert_file_name, cert_content in freeradius.certs.items() %}

{{ freeradius.radiusd_certs_dir + cert_file_name }}:
  file.managed:
    - contents: |
        {{ cert_content | indent(8) }}
    - mode: 640
    - user: root
    - group: {{ freeradius.service_group }}
    - require_in:
      - file: {{ freeradius.radiusd_conf }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endfor %}
{%- endif %}

{%- if freeradius.cas is defined and (freeradius.cas is not none) %}

{%- for cert_file_name, cert_content in freeradius.cas.items() %}

{{ freeradius.radiusd_cas_dir + cert_file_name }}:
  file.managed:
    - contents: |
        {{ cert_content | indent(8) }}
    - mode: 640
    - user: root
    - group: {{ freeradius.service_group }}
    - require_in:
      - file: {{ freeradius.radiusd_conf }}
    - watch_in:
      - service: {{ freeradius.service_name }}
{%- endfor %}
{%- endif %}

freeradius-service:
  service.running:
    - name: {{ freeradius.service_name }}
    - enable: True
    - require:
      - file: {{ freeradius.radiusd_conf }}
    - watch:
      - file: {{ freeradius.radiusd_conf }}
