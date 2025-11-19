FROM postgres:15-alpine

# Create a high UID user to satisfy CKV_K8S_40
# The postgres user in the base image uses UID 70, which Checkov considers too low
RUN addgroup -g 10000 pguser && \
    adduser -D -u 10000 -G pguser pguser && \
    mkdir -p /var/lib/postgresql/data && \
    chown -R pguser:pguser /var/lib/postgresql && \
    chmod -R 750 /var/lib/postgresql

USER pguser

# Copy init SQL to be executed on first container startup (empty data dir)
COPY --chown=pguser:pguser createSchema.sql /docker-entrypoint-initdb.d/01-createSchema.sql

# Health check - verify PostgreSQL is accepting connections
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD pg_isready -U postgres || exit 1
