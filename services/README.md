# Services

Docker Compose-based self-hosted services managed via `dotfiles services`.

## Usage

```bash
# List available services
dotfiles services list

# Start a service
dotfiles services up dozzle

# Stop a service
dotfiles services down dozzle

# View status
dotfiles services status

# View logs
dotfiles services logs dozzle
```

## Available Services

| Service | Port | Description |
|---------|------|-------------|
| [dozzle](./dozzle/) | 9999 | Real-time Docker log viewer |

## Adding a New Service

1. Create a directory under `services/` with the service name
2. Add a `docker-compose.yml` file
3. Optionally add a `.env` file for configuration
