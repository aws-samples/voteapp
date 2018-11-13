FROM envoyproxy/envoy

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /envoyconfig
ADD startup.sh /envoyconfig

ENTRYPOINT [ "/envoyconfig/startup.sh"]
CMD [ "envoy", "-c", "/envoyconfig/envoy-bootstrap.yaml" ]
