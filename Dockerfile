# ── Stage 1: build Flutter web ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy pubspec first so the pub-get layer is cached between code-only changes.
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy the rest of the source.
COPY . .

# Generate Android/iOS stubs so plugin registrants resolve during analysis
# (not strictly needed for web build, but keeps the cache consistent with CI).
RUN flutter build web --release

# ── Stage 2: serve with nginx ─────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Remove the default nginx welcome page.
RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
