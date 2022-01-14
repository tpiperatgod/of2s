FROM golang:1.17 as build-env

WORKDIR /go/src/app
COPY *.go .
COPY go.mod .

RUN ls /go/src/app
RUN go mod tidy

RUN CGO_ENABLED=0 go build -o /go/bin/app

FROM gcr.io/distroless/static

COPY --from=build-env /go/bin/app /
CMD ["/app"]