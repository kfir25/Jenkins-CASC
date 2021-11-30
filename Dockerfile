FROM jenkins/jenkins:lts
#check UID and GID cat /etc/passwd
ARG HOST_UID=1001
ARG HOST_GID=998
USER root
RUN apt-get update


# Install the required docker package
RUN apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker-ce.list
RUN apt-get update
RUN apt-get -y install docker-ce docker-ce-cli containerd.io

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
chmod +x /usr/local/bin/docker-compose

# disable the setup wizard as we will set up jenkins as code :)
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# Configure - Jenkins Configuration as Code
# Tell the jenkins config-as-code plugin where to find the yaml file
ENV CASC_JENKINS_CONFIG /var/jenkins_home/jenkins-casc.yaml
COPY jenkins-casc.yaml /var/jenkins_home/jenkins-casc.yaml

# Copy the list of plugins we wish to install
# more info at https://github.com/jenkinsci/docker/#preinstalling-plugins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt


# run ALL commands without a password for the jenkins user
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers
    
RUN usermod -u $HOST_UID jenkins
RUN groupmod -g $HOST_GID docker
RUN usermod -aG docker jenkins
USER jenkins
