FROM golang:1.23 as builder

WORKDIR /app

COPY go.mod main.go ./
RUN go mod tidy && \
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o service main.go

FROM gcr.io/distroless/static-debian12
WORKDIR /
COPY --from=builder /app/service /service

ENTRYPOINT ["/service"]

EXPOSE 8080