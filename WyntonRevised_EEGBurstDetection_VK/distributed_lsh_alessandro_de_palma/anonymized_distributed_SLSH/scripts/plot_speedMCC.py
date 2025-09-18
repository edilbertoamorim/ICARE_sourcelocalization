import matplotlib.pyplot as plt
import matplotlib
from script_utils import get_comparison_CI


def read_mcc_tuning_file(filename, p, n, nodes, cores):

    lsh = []
    slsh = []

    with open(filename, "r") as file:

        for line in file:

            linesplit = line.split("_")
            if len(linesplit) < 2:
                continue

            if linesplit[0] == "exhaustive":
                baseline = (1, float(linesplit[4][3:]))

            if linesplit[0][0:4] == "mout":

                mcc = float(linesplit[7][3:])
                filename = "../results/distributed/abp-{}-{}-{}-{}-{}-{}-{}-{}nodes-{}cores.txt".format(
                    linesplit[0], linesplit[1], linesplit[2], linesplit[3],
                    linesplit[4], linesplit[10], linesplit[11].strip(), nodes,
                    cores)
                lowCI, median, uppCI = get_comparison_CI(filename)

                # Express CI's as differences.
                median = n / median / p
                lowCI = median - n / lowCI / p
                uppCI = n / uppCI / p - median

                if float(linesplit[4][5:]) == 1:
                    if len(linesplit) == 13:
                        slsh_base = ((lowCI, median, uppCI), mcc)
                    else:
                        lsh.append(((lowCI, median, uppCI), mcc))
                else:
                    slsh.append(((lowCI, median, uppCI), mcc))

        return baseline, lsh, slsh, slsh_base


if __name__ == "__main__":
    """
    To be executed from scripts/
    No command line arguments
    """

    matplotlib.rcParams.update({'font.size': 25})

    cores = 8
    nodes = 2
    p = cores * nodes
    n = 803725

    baseline, lsh, slsh, slsh_base = read_mcc_tuning_file(
        "../results/accuracy-test.txt", p, n, nodes, cores)

    plt.scatter(
        baseline[0], baseline[1], c='blue', marker='*', s=80, label="PKNN")
    plt.errorbar(
        slsh_base[0][1],
        slsh_base[1],
        xerr=[[slsh_base[0][0]], [slsh_base[0][2]]],
        fmt='o',
        c='green',
        capsize=2,
        ms=7,
        mew=2,
        capthick=1,
        elinewidth=0.3,
        label="SLSH onset")
    plt.errorbar(
        [e[0][1] for e in lsh], [e[1] for e in lsh],
        xerr=[[e[0][0] for e in lsh], [e[0][2] for e in lsh]],
        c='green',
        fmt='x',
        capsize=2,
        ms=7,
        mew=2,
        capthick=1,
        elinewidth=0.3,
        label="LSH")
    plt.errorbar(
        [e[0][1] for e in slsh], [e[1] for e in slsh],
        xerr=[[e[0][0] for e in slsh], [e[0][2] for e in slsh]],
        c='red',
        fmt='|',
        capsize=2,
        ms=7,
        mew=2,
        capthick=1,
        elinewidth=0.3,
        label="SLSH")

    plt.figure(1)
    #plt.axvline(x=1)
    plt.legend(loc='best')
    plt.grid()
    plt.ylabel("MCC")
    plt.xlabel("Speed-up to PKNN [n. comparisons]")
    plt.title("Speed vs. MCC trade-off")

    plt.show()
