FROM centos:centos7.9.2009

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

ENV JENKINS_HOME /home/${user}

USER root

# Copy private key for SCM access and ansible config file
RUN mkdir -p "$JENKINS_HOME/.ssh"
COPY ./id_rsa_scm "$JENKINS_HOME/.ssh/id_rsa"
# Copy private key for ssh access for linux host management with ansible
COPY ./id_rsa_ssh "$JENKINS_HOME/.ssh/id_rsa_ssh"
COPY ./ansible.cfg "$JENKINS_HOME/.ansible.cfg"

# chown everything in jenkins home for jenkins
RUN \
    set -ex && \
    chmod 600 "$JENKINS_HOME/.ssh/id_rsa" && chmod 600 "$JENKINS_HOME/.ssh/id_rsa_ssh" && \
    # Jenkins is run with user `jenkins`, uid = 1000
    groupadd -g ${gid} ${group} && \
    # Create jenkins user
    useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} && \
    # Disable host key checking for ssh to allow undisturbed ansible connections using ssh authentication
    echo 'Host *' >> "$JENKINS_HOME/.ssh/config" && \
    echo 'StrictHostKeyChecking no' >> "$JENKINS_HOME/.ssh/config" && \
    chown -R ${user}:${user} /home/${user} && \ 
    # Create location for ansible venv
    mkdir /opt/ansible; chown jenkins:jenkins /opt/ansible && \
    # Install prerequisites
    yum install -y -q wget vim htop gnupg gcc glibc && \
    # Install JDK and base utils
    yum install -y -q java-1.8.0-openjdk git && \
    # Install python3
    yum install -y -q python3 python3-pip && \
    # Create venv for ansible so that we can use the up-to-date version
    python3 -m venv /opt/ansible && . /opt/ansible/bin/activate && \
    # Install python3 prerequisites
    python3 -m pip install --upgrade pip && \
    python3 -m pip install setuptools wheel && \
    # Install necessary packages for ansible
    python3 -m pip install ansible google-auth jmespath requests psutil pywinrm zabbix-api && \
    # Add ansible binaries to path
    ln -s /opt/ansible/bin/ansible /usr/local/bin/ansible && \
    ln -s /opt/ansible/bin/ansible-galaxy /usr/local/bin/ansible-galaxy && \
    ln -s /opt/ansible/bin/ansible-playbook /usr/local/bin/ansible-playbook

USER ${user}

CMD ["/bin/bash"]
