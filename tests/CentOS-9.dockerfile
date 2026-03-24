FROM quay.io/centos/centos:stream9

RUN curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo | tee /etc/yum.repos.d/saltstack.repo
RUN dnf clean all
RUN dnf check-update
RUN dnf --assumeyes upgrade
RUN dnf install --assumeyes salt-minion

COPY tests/minion /etc/salt/
RUN mkdir --parents /srv/salt/{state,pillar}
COPY tests/state-top.sls /srv/salt/state/top.sls
COPY freeradius /srv/salt/state/freeradius
COPY tests/pillar-top.sls /srv/salt/pillar/top.sls
COPY tests/pillar.sls /srv/salt/pillar/freeradius.sls

ENTRYPOINT ["salt-call", "--local", "state.show_sls", "freeradius"]