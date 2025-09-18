from script_utils import *


def plot_strongscaling():

    basename = "../results/distributed/abp-mout{}-Lout{}-min{}-Lin{}-alpha{}-n{}-k{}-{}nodes-{}cores.txt"

    m_out_list = [125, 190]
    L_out = 72
    m_in = 90
    L_in = 60
    k = 10
    alpha = 0.005

    worker_list = [1, 2, 3, 4, 5]
    cores = 8
    n_list = [801725, 1371479]

    array = []
    for index in range(len(n_list)):
        n = n_list[index]
        m_out = m_out_list[index]

        for i in range(len(worker_list)):
            nodes = worker_list[i]

            filename = basename.format(m_out, L_out, m_in, L_in, alpha, n, k,
                                       nodes, cores)
            lowCI, median, upCI = get_comparison_CI(filename)
            array.append((median - lowCI, median, upCI - median))

        # Plot DSLSH.
        custom_plot(
            index,
            np.array(worker_list) * 8, [x[1] for x in array],
            [[x[0] for x in array], [x[2] for x in array]],
            r'Number of overall processors $\nu p$',
            "Max. Comparisons",
            r'Strong scaling $n=$' + "{}".format(n),
            True,
            labelname="DSLSH",
            dotted=True)

        # Plot baseline.
        baseline = n / np.array(worker_list) / 8
        custom_plot(
            index,
            np.array(worker_list) * 8,
            baseline,
            baseline,
            r'Number of overall processors $\nu p$',
            "Max. Comparisons",
            r'Strong scaling $n=$' + "{}".format(n),
            False,
            labelname="PKNN",
            dotted=True)
        array.clear()


if __name__ == "__main__":
    """
    To be executed from scripts/
    No command line arguments
    """

    plot_strongscaling()
    plt.show()
