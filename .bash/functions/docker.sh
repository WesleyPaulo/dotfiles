dexec() {
    docker exec -it "$1" bash
}

dlog() {
    docker logs -f "$1"
}

dinspect() {
    docker inspect "$1" | less
}