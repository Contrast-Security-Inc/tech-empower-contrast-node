import multiprocessing
import os


_is_travis = os.environ.get("TRAVIS") == "true"

workers = 2 * 3
if _is_travis:
    workers = 2

bind = "0.0.0.0:8080"
keepalive = 120
errorlog = "-"
pidfile = "/tmp/gunicorn.pid"
timeout = 60

worker_class = "meinheld.gmeinheld.MeinheldWorker"

def post_fork(server, worker):
    # Disalbe access log
    import meinheld.server
    meinheld.server.set_access_logger(None)

