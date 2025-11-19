FROM postgres:15-alpine

# Copy init SQL to be executed on first container startup (empty data dir)
COPY createSchema.sql /docker-entrypoint-initdb.d/01-createSchema.sql
