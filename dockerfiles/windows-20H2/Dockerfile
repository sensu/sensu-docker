FROM mcr.microsoft.com/windows/nanoserver:20H2

MAINTAINER Sensu, Inc. Engineering <engineering@sensu.io>

LABEL name="sensu/sensu" \
      maintainer="engineering@sensu.io" \
      vendor="Sensu, Inc." \
      license="All Rights Reserved. For details, visit https://sensu.io/sensu-license" \
      summary="Sensu Go - Full-stack monitoring" \
      description="Sensu is an event pipeline and monitoring system for everything from the server closet to the serverless application." \
      url="https://sensu.io/" \
      run="docker run -d --name sensu-agent sensu/sensu" \
      io.k8s.description="Sensu" \
      io.k8s.display-name="Sensu" \
      io.openshift.expose-services="3030:tcp,3030:udp,6060:tcp,8125:udp" \
      io.openshift.tags="sensu,monitoring,observability"

##################
# agent ports
##################

# agent socket (tcp)
EXPOSE 3030/tcp

# agent socket (udp)
EXPOSE 3030/udp

# pprof endpoint (http/https)
EXPOSE 6060/tcp

# statsd listener (udp)
EXPOSE 8125/udp

##################
# agent volumes
##################

# TODO (jk): determine how to fix permission errors on Windows.
#VOLUME "C:\\sensu\\cache\\sensu-agent"
#VOLUME "C:\\sensu\\data\\sensu-agent"
#VOLUME "C:\\sensu\\log"

##################
# agent config
##################

ENV SENSU_CACHE_DIR "C:\sensu\cache\sensu-agent"

COPY target/windows/amd64/sensu-agent.exe /sensu/bin/sensu-agent.exe
COPY target/windows/amd64/sensuctl.exe /sensu/bin/sensuctl.exe

USER ContainerAdministrator
RUN setx /m PATH "%PATH%;C:\sensu\bin"
USER ContainerUser

CMD ["sensu-agent.exe", "start"]
