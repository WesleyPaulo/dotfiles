# ALIASES PARA DOCKER
alias di='docker images'
alias dr='docker run -it --rm'

# ALIASES PARA DOCKER COMPOSE
alias dc='docker compose'
alias dce='docker compose exec'

# COMANDOS DE GERENCIAMENTO DE CONTAINERS
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcb='docker compose build'

#COMANDOS PARA BUILD DE CONTAINERS DE DEV E PROD
alias dcdev="docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build"
alias dcprod="docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build"

# EXECUÇÃO DE CONTAINERS
alias dcsta='docker compose start'
alias dcsto='docker compose stop'
alias dcr='docker compose restart'

# LOGS E STATUS
alias dcl='docker compose logs'
alias dclf='docker compose logs -f'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# LIMPEZA DE IMAGENS E CONTAINERS PARADOS
alias dclean='docker system prune -f'
alias dcleanall='docker system prune -a -f'