Start Development Mode:
docker compose -f docker-compose.dev.yml up -d

Stop Development Mode:
docker compose -f docker-compose.dev.yml down

View Logs:
docker compose -f docker-compose.dev.yml logs -f ckan-dev

Access Container
docker compose -f docker-compose.dev.yml exec ckan-dev bash