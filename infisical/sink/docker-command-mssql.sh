#!/usr/bin/env bash
set -e

CONTAINER_NAME="mssql"
SA_PASSWORD="StrongP@ssw0rd!"
IMAGE="mcr.microsoft.com/mssql/server:2022-latest"

echo "🚀 Starting SQL Server 2022 container..."

docker run -d \
  --platform=linux/amd64 \
  --name "${CONTAINER_NAME}" \
  -p 1433:1433 \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=${SA_PASSWORD}" \
  "${IMAGE}"

echo "⏳ Waiting for SQL Server to be ready..."
# Check logs for ready message
until docker logs "${CONTAINER_NAME}" 2>&1 | grep -q "SQL Server is now ready for client connections."; do
  sleep 5
done

echo ""
echo "✅ SQL Server is ready!"
echo ""
echo "🔐 Connection details:"
echo "------------------------------------"
echo "Host:        localhost"
echo "Port:        1433"
echo "Username:    sa"
echo "Password:    ${SA_PASSWORD}"
echo "Database:    master"
echo ""
echo "📎 JDBC URL:"
echo "jdbc:sqlserver://localhost:1433;databaseName=master;user=sa;password=${SA_PASSWORD}"
echo ""
echo "🧪 Connect using sqlcmd:"
echo "sqlcmd -S localhost,1433 -U sa -P '${SA_PASSWORD}'"
echo "------------------------------------"
