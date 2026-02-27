# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build

WORKDIR /app

# disable analytics
RUN flutter config --no-analytics

# copy pubspec first for cache
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# copy source
COPY . .

RUN flutter build web --release

# keep container alive (so volume stays)
CMD ["sh", "-c", "cp -r /app/build/web/* /output && sleep infinity"]