FROM envoyproxy/envoy

RUN mkdir /envoyconfig
ADD startup.sh /envoyconfig

ENTRYPOINT [ "/bin/bash", "/envoyconfig/startup.sh"]

CMD [ 'envoy', '-c', '/envoyconfig/envoy-bootstrap.yaml']