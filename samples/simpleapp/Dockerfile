FROM golang

RUN go get github.com/gorilla/mux

RUN mkdir /simplewebapp
WORKDIR /simplewebapp
ADD main.go /simplewebapp/main.go
ADD app/build /simplewebapp/public

RUN go build main.go

CMD ["/simplewebapp/main"]