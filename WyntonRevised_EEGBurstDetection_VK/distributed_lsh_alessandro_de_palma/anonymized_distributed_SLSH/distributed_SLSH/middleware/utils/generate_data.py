'''
    File containing the methods to generate datasets and store them into files.
'''
import numpy as np
import sys


def generate_identity(D, folder, prediction=False):
    """
    Generate identity matrix.

    :param D: dimensionality
    :param folder: folder to store the dataset to

    :return: nothing
    """

    pred_string = ""

    X = np.eye(D)
    if prediction:
        labels = np.ones((1, D))
        X = np.append(X, labels, axis=0)
        pred_string = "labeled_"

    filename = folder + pred_string + "identity_{}".format(D)

    write_matrix_to_file(filename, X, prediction=prediction)


def generate_isotropic_gaussian(d, n, folder):
    '''
    Generate identity matrix.

    :param d: dimensionality
    :param folder: folder to store the dataset to

    :return: nothing
    '''

    # Data generation.
    mean = 0
    std = 20
    X_shape = (d, n)
    X = np.random.normal(mean, std, X_shape)  # Generate dataset.

    filename = folder + "gaussian_{}x{}".format(d, n)

    write_matrix_to_file(filename, X)


def write_matrix_to_file(filename, X, prediction=False):
    """
    Write the matrix to a file.
    Each line is a point, separated by spaces.

    :param filename: filename
    :param X: the input numpy matrix

    :return: nothing
    """

    f = open(filename, 'w')

    for i in range(np.shape(X)[1]):
        line = ""
        for j in range(np.shape(X)[0]):
            line += str(X[j, i])
            if not prediction:
                if j != np.shape(X)[0] - 1:
                    line += " "
            else:
                if j <= np.shape(X)[0] - 3:
                    line += " "
                elif j == np.shape(X)[0] - 2:
                    line += " - "

        print(line, file=f)

    f.close()


if __name__ == "__main__":

    # Format: type n d

    folder = "./datasets/"
    type = sys.argv[1]
    n = int(sys.argv[2])
    d = int(sys.argv[3])

    if type == "identity":
        generate_identity(d, folder, prediction=True)
    elif type == "gaussian":
        generate_isotropic_gaussian(d, n, folder)
