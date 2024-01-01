# https://github.com/frappe/frappe_docker/blob/main/docs/single-server-example.md

mkdir /gitops/
echo 'TRAEFIK_DOMAIN=traefik.hyperdata.vn' > gitops/traefik.env
echo 'EMAIL=system@hyperdata.vn' >> gitops/traefik.env
echo 'HASHED_PASSWORD='$(openssl passwd -apr1 changeit | sed 's/\$/\\\$/g') >> gitops/traefik.env

# docker compose --project-name traefik   --env-file gitops/traefik.env   -f overrides/compose.traefik.yaml   -f overrides/compose.traefik-ssl.yaml up -d
docker compose -p traefik \
    --env-file gitops/traefik.env \
    -f overrides/compose.traefik.yaml -f overrides/compose.traefik-ssl.yaml config > gitops/traefik.yaml    
docker compose -project-name traefik -f gitops/traefik.yaml up -d

# docker compose --project-name mariadb --env-file gitops/mariadb.env -f overrides/compose.mariadb-shared.yaml up -d
docker compose -p mariadb \
    --env-file gitops/mariadb.env \
    -f overrides/compose.mariadb-shared.yaml config > gitops/mariadb.yaml    
docker compose -f gitops/mariadb.yaml up -d

cp example.env gitops/erpnext-one.env
sed -i 's/DB_PASSWORD=123/DB_PASSWORD=changeit/g' gitops/erpnext-one.env
sed -i 's/DB_HOST=/DB_HOST=mariadb-database/g' gitops/erpnext-one.env
sed -i 's/DB_PORT=/DB_PORT=3306/g' gitops/erpnext-one.env
sed -i 's/SITES=`erp.example.com`/SITES=\`hyperdata.vn\`,\`primedata.vn\`/g' gitops/erpnext-one.env
echo 'ROUTER=erpnext-one' >> gitops/erpnext-one.env
echo "BENCH_NETWORK=erpnext-one" >> gitops/erpnext-one.env

docker compose --project-name erpnext-one \
  --env-file gitops/erpnext-one.env \
  -f compose.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.multi-bench.yaml \
  -f overrides/compose.multi-bench-ssl.yaml config > gitops/erpnext-one.yaml

docker compose --project-name erpnext-one -f gitops/erpnext-one.yaml up -d

# hyperdata.vn
docker compose --project-name erpnext-one exec backend \
  bench new-site --no-mariadb-socket --mariadb-root-password changeit --install-app erpnext --admin-password changeit hyperdata.vn

# Run: 
docker compose --project-name erpnext-one -f gitops/traefik.yaml up -d
docker compose --project-name erpnext-one -f gitops/mariadb.yaml up -d
docker compose --project-name erpnext-one -f gitops/erpnext-one.yaml up