FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .
ARG CONFIG_PROFILE=default
ARG BUILD_SHA=ci
# Disable deprecated Flutter SW stub; bundle CanvasKit locally for strict CSP.
RUN flutter build web --release --pwa-strategy=none --no-web-resources-cdn \
  --dart-define=CONFIG_PROFILE=${CONFIG_PROFILE} \
  --dart-define=BUILD_SHA=${BUILD_SHA}

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY docker/nginx/snippets/ /etc/nginx/snippets/
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
