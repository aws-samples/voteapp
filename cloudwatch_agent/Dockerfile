FROM golang:1.11.2-stretch AS build

WORKDIR /build
COPY . .
RUN go get -d -v ./... && \
    go install -v ./... 


FROM golang:1.11.2-stretch
COPY --from=build /go/bin/envoy_cloudwatch_agent /usr/bin/envoy_cloudwatch_agent
CMD ["/usr/bin/envoy_cloudwatch_agent"]
