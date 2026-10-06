FROM --platform=$BUILDPLATFORM golang:1.27-alpine AS build_deps

RUN apk add --no-cache git

WORKDIR /workspace

COPY go.mod .
COPY go.sum .

RUN go mod download

FROM build_deps AS build

COPY . .

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -o webhook -ldflags '-w -extldflags "-static"' .

FROM alpine:3.24

RUN apk add --no-cache ca-certificates && \
    adduser -D -u 65532 nonroot

COPY --from=build /workspace/webhook /usr/local/bin/webhook

USER nonroot:nonroot

ENTRYPOINT ["webhook"]
