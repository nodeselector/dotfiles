# Services

Docker Compose-based self-hosted services managed via `ns-dotfiles services`.

## Usage

```bash
# List available services
ns-dotfiles services list

# Start a service
ns-dotfiles services up dozzle

# Stop a service
ns-dotfiles services down dozzle

# View status
ns-dotfiles services status

# View logs
ns-dotfiles services logs dozzle
```

## Available Services

| Service | Port | Description |
|---------|------|-------------|
| [dozzle](./dozzle/) | 9999 | Real-time Docker log viewer |

## Adding a New Service

1. Create a directory under `services/` with the service name
2. Add a `docker-compose.yml` file
3. Optionally add a `.env` file for configuration
