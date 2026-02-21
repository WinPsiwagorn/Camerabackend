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

# Stage 2: Serve with nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]