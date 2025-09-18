import os
from time import sleep


def run_strongscaling_experiment(node_ips, port, middleware_ip):
    """
    Tuning for AHE prediction on large datasets.

    :param node_ips: list of ips of the workes (nodes)
    :param port: the port the nodes accept connections on.
    :param middleware_ip: ip of the middleware

    :return: nothing
    """

    d = 30
    n_list = [801724, 1373479]
    filename_list = [
        "MIMICIII-ABP-AHE-lag30m-cond30m.data",
        "MIMICIII-ABP-AHE-lag5m-cond5m.data"
    ]
    m_out = 190
    L_out = 72
    m_in = 90
    L_in = 60
    k = 10
    alpha = 0.005
    cores = 8
    workers_list = [1, 2, 3, 4, 5]

    for i in range(len(n_list)):
        n = n_list[i]
        filename = filename_list[i]

        for workers in workers_list:
            # Run all workers for this experiment.
            for j in range(workers):
                run_worker_abp_prediction(j + 1, node_ips[j], port, cores, n,
                                          d, m_out, L_out, m_in, L_in, alpha,
                                          k)
            # Run the middleware and wait for it to terminate.
            sleep(30)
            run_middleware_abp_prediction(middleware_ip, node_ips[:workers],
                                          port, cores, n, d, m_out, L_out,
                                          m_in, L_in, alpha, k, filename)
            sleep(280)

            # Change port to avoid issues.
            port += 10


def run_worker_abp_prediction(node_id,
                              worker_ip,
                              port,
                              n_cores,
                              n,
                              d,
                              m_out,
                              L_out,
                              m_in,
                              L_in,
                              alpha,
                              k,
                              from_middleware=False):

    command = "\"cd /home/ubuntu/code/distributed_SLSH; python3 -u ahe_main.py node --mode distributed --task accuracy --node_id {} --port {} --cores {} --n {} --d {} " \
              "--m_out {} --L_out {} --m_in {} --L_in {} --alpha {} --k {}\" &".format(node_id, port, n_cores, n, d, m_out, L_out, m_in, L_in, alpha, k)  # Run command in background.

    ssh = "ssh ubuntu@{} ".format(worker_ip)  # User settings.

    print(ssh + command)
    os.system(ssh + command)


def run_middleware_abp_prediction(middleware_ip, node_ips, port, n_cores, n, d,
                                  m_out, L_out, m_in, L_in, alpha, k,
                                  filename):

    nodes = ""
    for i in range(len(node_ips)):
        ip = node_ips[i]
        nodes += ip + ":{}".format(port)
        if i < len(node_ips) - 1:
            nodes += "-"

    command = "\"cd /home/ubuntu/code/distributed_SLSH; python3 -u ahe_main.py orchestrator --task accuracy --synchronous synchronous --nodes_list {} --cores {} --n {} --d {} " \
                  "--m_out {} --L_out {} --m_in {} --L_in {} --alpha {} --k {} --filename {}\"".format(nodes, n_cores, n, d, m_out, L_out, m_in, L_in, alpha, k, filename)  # Wait for this to terminate.
    ssh = "ssh ubuntu@{} ".format(middleware_ip)  # User settings.
    print(ssh + command)
    os.system(ssh + command)


if __name__ == "__main__":
    """
    Usage:

        run from scripts/
        python3 run_strongscaling.py


    IMPORTANT: in order to run a script without keeping the terminal open, use
    nohup python3 -u run_strongscaling.py &
    """

    node_ips = [
        "128.52.161.48", "128.52.161.31", "128.52.161.56", "128.52.161.57",
        "128.52.161.255"
    ]  # User settings.
    port = 3000  # The port the nodes accept connections on.  # User settings.
    middleware_ip = "128.52.161.43"  # User settings.

    run_strongscaling_experiment(node_ips, port, middleware_ip)
