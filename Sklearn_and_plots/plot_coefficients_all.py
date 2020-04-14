import numpy as np
import matplotlib.pyplot as plt
from sklearn.svm import LinearSVC

def title_of_plot(model):
    title = model+' in Temporal-EZ localization: Feature Ranking'
    return title


def save_folder_of_plot(model):
    folder = ('D:\\Ali USB Backup\\1 PhD\\paper 1\\fixed fully\\'
                + 'LANCET ' + model + ' EZ_localization_features')
    return folder


def cm2inch(values) -> tuple:
    new_values = tuple(value/2.54  for value in values)
    return new_values


def plot_coefficients_all(classifier,
                            feature_names,
                            save=False,
                            model='___',
                            figsize=(10.7, 8),
                            ):
    """
    kwargs = "figsize" in cm
    """
    try:
        coef = classifier.coef_.ravel()
    except AttributeError:
        coef = classifier.feature_importances_.ravel()
    coefficients = np.argsort(coef)[0:]
#     coefficients = np.hstack(coefficients)

    # create plot
    plt.figure(figsize=cm2inch(figsize))
    colors = ['red' if c < 0 else 'blue' for c in coef[coefficients]]

    plt.bar(np.arange(len(coef)), coef[coefficients], color=colors)

    feature_names = np.array(feature_names)
    plt.xticks(np.arange(0, 1 + len(coef)), feature_names[coefficients], rotation=45, ha='right', fontsize=10)
    plt.ylabel('Coefficients', fontsize=10)
    plt.grid(which='all')

    csfont = {'fontname':'Times New Roman'}

    if save:
        plt.tight_layout()
        filename_no_title = (save_folder_of_plot(model)
                            + ' BLANK.jpg')
        plt.savefig(filename_no_title, format='jpg', dpi=1000)
        filename_no_title = (save_folder_of_plot(model)
                            + ' VECTOR_BLANK.eps')
        plt.savefig(filename_no_title, format='eps', dpi=1000)


        title = title_of_plot(model)
        plt.title(title, fontsize=10, fontweight='bold', **csfont)
        plt.tight_layout()
        filename = (save_folder_of_plot(model)
                    + '.jpg')
        plt.savefig(filename, format='jpg', dpi=1000)
        filename_eps = (save_folder_of_plot(model)
                    + ' VECTOR.eps')
        plt.savefig(filename_eps, format='eps', dpi=1000)

    # plot e.g. in jupyter notebook
    title = title_of_plot(model)
    plt.title(title, fontsize=10, fontweight='bold', **csfont)

    plt.tight_layout()
    plt.show()