FROM golang:alpine AS git
WORKDIR /src
RUN apk add --update git

RUN go get -u github.com/jteeuwen/go-bindata/...
RUN git clone https://github.com/amborle/featmap

FROM golang:alpine as node-builder
COPY --from=git /src /src
RUN apk add --update npm
WORKDIR /src/featmap/webapp
ENV NODE_ENV=production
RUN npm install --production
RUN npm run build

FROM golang:alpine as go-builder
COPY --from=node-builder /src /src

WORKDIR /src/featmap/migrations
RUN go get -u github.com/jteeuwen/go-bindata/...
RUN go-bindata  -pkg migrations .

WORKDIR /src/featmap
RUN go-bindata  -pkg tmpl -o ./tmpl/bindata.go  ./tmpl/ && \
    go-bindata  -pkg webapp -o ./webapp/bindata.go  ./webapp/build/...
RUN go build -o /opt/featmap/featmap && \
    chmod 775 /opt/featmap/featmap

FROM golang:alpine
COPY --from=go-builder /opt/featmap /opt/featmap
WORKDIR /opt/featmap
ENTRYPOINT ./featmap
