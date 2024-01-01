
# clone frappe docker
git clone git@github.com:tramkhanhduong/frappe_docker.git;
cd frappe_docker;
cp -R devcontainer-example .devcontainer;
cp -R development/vscode-example development/.vscode;
code .;
code --install-extension ms-vscode-remote.remote-containers; # init dev containers
# Run (Ctrl + Shift + P) to open vscode remote container 

nvm use v16;

# bench init --skip-redis-config-generation --frappe-branch version-14 frappe-bench;  # install frappe version 14
bench init frappe-bench --ignore-exist --skip-redis-config-generation --frappe-path=https://github.com/tramkhanhduong/frappe.git;
# bench init test-frappe-dev --frappe-path=https://github.com/tramkhanhduong/frappe.git


# Installing frappe;
# $ /workspace/development/frappe-bench/env/bin/python -m pip install --quiet --upgrade -e /workspace/development/frappe-bench/apps/frappe;
# yarn install

cd frappe-bench;
# setup host
bench set-config -g db_host localhost;
bench set-config -g redis_cache redis://redis-cache:6379;
bench set-config -g redis_queue redis://redis-queue:6379;
bench set-config -g redis_socketio redis://redis-socketio:6379;

# setup db env
bench config set-common-config -c root_login postgres;
bench config set-common-config -c root_password '"123"';

# Get apps
# bench get-app --branch version-14 --resolve-deps erpnext;
# bench get-app --branch master git@github.com:tramkhanhduong/frappe.git;
# bench get-app --branch master git@github.com:tramkhanhduong/erpnext.git;
# bench get-app --branch master git@github.com:tramkhanhduong/payments.git;
# bench get-app --branch master git@github.com:tramkhanhduong/education.git;
# bench get-app --branch master git@github.com:tramkhanhduong/frappe_custom_app.git;
# bench get-app --branch master https://github.com/frappe/insights

git clone git@github.com:tramkhanhduong/frappe.git;
git clone git@github.com:tramkhanhduong/erpnext.git;
git clone git@github.com:tramkhanhduong/payments.git;
git clone git@github.com:tramkhanhduong/education.git;
git clone git@github.com:tramkhanhduong/frappe_custom_app.git;


# Clone repo to apps
# Install using pip: ./env/bin/pip install apps/hello_world/ –no-cache-dir
# Make sure app name exists in ./sites/app.txt
# Install app on associated site: bench –site site1.local install-app hello_world {Here name of out custom application is hello_world}
# If you get AttributeError: WebApplicationClient issue solve it using: https://discuss.frappe.io/t/quickbooks-migrator-py-failing-attributeerror-webapplicationclient-object-has-no-attribute-populate-token-attributes/45050/2?u=black_mamba


# setup developer mode on new site
# bench new-site test-erp-postgres.localhost --db-host postgresql --db-port 5432 --db-type postgres
# bench new-site test-erp-mdb.localhost --db-host mariadb --db-port 3306 --mariadb-root-password 123 --admin-password admin --no-mariadb-socket
bench new-site hyperdata.localhost --db-type postgres --db-host postgresql;
bench new-site hyperdata_duplicate.localhost --db-type postgres --db-host postgresql;
bench --site hyperdata.localhost set-config developer_mode 1;
# bench --site hyperdata.localhost clear-cache;

# Install apps to site
bench --site hyperdata_duplicate.localhost install-app erpnext; # map a site with erp app;
bench --site hyperdata.localhost install-app education; # https://github.com/frappe/education
bench --site hyperdata.localhost install-app payments;
bench --site hyperdata.localhost install-app frappe_custom_app; # map a site with erp app;

# Start apps
bench start;

# Test site
# source env/bin/activate
# pip install hypothesis
# bench --site hyperdata.localhost run-tests

# Python env
# python -m venv .venv
# source .venv/bin/activate
# pip install ..