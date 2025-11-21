FROM postgres:15-alpine

RUN addgroup -g 10000 pguser && \
    adduser -D -u 10000 -G pguser pguser && \
    mkdir -p /var/lib/postgresql/data && \
    chown -R pguser:pguser /var/lib/postgresql && \
    chmod -R 750 /var/lib/postgresql

USER pguser


COPY --chown=pguser:pguser createSchema.sql /docker-entrypoint-initdb.d/01-createSchema.sql


HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD pg_isready -U postgres || exit 1
